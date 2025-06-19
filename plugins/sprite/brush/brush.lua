local ffi = require "ffi"
local Inspectable = require "src.properties.inspectable"
local Luvent = require "lib.luvent"
local bline = require "src.common.bline"
local AABBMath = require "src.math.aabb"

local BoolProperty = require "src.properties.bool"
local EnumProperty = require "src.properties.enum"
local IntegerProperty = require "src.properties.integer"

---@class Brush: Inspectable
local Brush = Inspectable:extend()

---@alias Brush.OffsetMode
---| "center"
---| "manual"

---@type BoolProperty
Brush.continuous = BoolProperty(Brush, "Continuous", true)

local patternOptions = {
	{
		name = "Simple",
		value = "simple"
	},
	{
		name = "Scroll From Offset",
		value = "scrolloffset"
	},
	{
		name = "Scroll From Beginning",
		value = "scrollbeginning"
	},
}

local brushTypeOptions = {
	{
		name = "Mask",
		value = "mask"
	},
	{
		name = "Color",
		value = "color"
	},
}

function Brush:new()
	Brush.super.new(self)
	---@type integer
	self.w = 1
	---@type integer
	self.h = 1
	---@type integer, integer
	self.offsetX, self.offsetY = 0, 0
	---@type EnumProperty
	self.patternMode = EnumProperty(self, "Pattern", "simple")
	self.patternMode:setOptions(patternOptions)
	---@type Brush.OffsetMode
	self.offsetMode = "center"
	---@type integer, integer
	self.scrollOffsetX, self.scrollOffsetY = 0, 0
	---@type IntegerProperty, IntegerProperty
	self.sourceOffsetX, self.sourceOffsetY =
		IntegerProperty(self, "Offset X", 0), IntegerProperty(self, "Offset Y", 0)
	---@type EnumProperty
	self.type = EnumProperty(self, "Type", "mask")
	self.type:setOptions(brushTypeOptions)

	---@type love.ImageData
	self.brushData = love.image.newImageData(1, 1, "r8")

	-- Makes the pixel equal to 255
	ffi.cast("uint8_t*", self.brushData:getFFIPointer())[0] = 255

	---@type love.Image
	self.brushImage = love.graphics.newImage(self.brushData)
	---@type Luvent
	self.brushDataChanged = Luvent.newEvent()

	self._onPatternModeChanged = self.patternMode.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
	end)
end

---Sets the brushData and triggers the events
---@param data love.ImageData
function Brush:setBrushData(data)
	self.brushImage:release()
	self.brushData:release()
	self.brushData = data
	self.brushImage = love.graphics.newImage(data)
	self:updateOffset()
	self.brushDataChanged:trigger(self)
end

---Sets the offset mode and moves it
---@param mode Brush.OffsetMode
function Brush:setOffsetMode(mode)
	self.offsetMode = mode
end

function Brush:updateOffset()
	local mode = self.offsetMode
	if mode == "center" then
		self.offsetX, self.offsetY =
			math.floor(self.w * 0.5),
			math.floor(self.h * 0.5)
	end
end

function Brush:generate()
	local newData = love.image.newImageData(1, 1, "r8")
	ffi.cast("uint8_t*", newData:getFFIPointer())[0] = 255
	self:setBrushData(newData)
end

---Increase the brush size by a certain amount. If amount is nil, assume it's by 1 step.
---@param amount integer?
function Brush:grow(amount)
end

---Decrease the brush size by a certain amount. If amount is nil, assume it's by 1 step.
---@param amount integer?
function Brush:shrink(amount)
end

local function alwaysValid()
	return true
end

local function simpleMaskBrushIndex(curX, curY, brushX, brushY, brushWidth, brushHeight, scrollOffsetX, scrollOffsetY)
	return brushX + brushY * brushWidth
end

local function scrollMaskBrushIndex(curX, curY, _, _, brushWidth, brushHeight, scrollOffsetX, scrollOffsetY)
	return (curX - scrollOffsetX) % brushWidth + ((curY - scrollOffsetY) % brushHeight) * brushWidth
end

local function simpleColorBrushIndex(curX, curY, brushX, brushY, brushWidth, brushHeight, scrollOffsetX, scrollOffsetY)
	return (brushX + brushY * brushWidth) * 4
end

local function scrollColorBrushIndex(curX, curY, _, _, brushWidth, brushHeight, scrollOffsetX, scrollOffsetY)
	return ((curX - scrollOffsetX) % brushWidth + ((curY - scrollOffsetY) % brushHeight) * brushWidth) * 4
end

local function checkBitmask(bitmask, curX, curY)
	return bitmask:get(curX, curY)
end

local function maskBrushPixelValid(brushP, brushIndex)
	return brushP[brushIndex] == 255
end

local function colorBrushPixelValid(brushP, brushIndex)
	return brushP[brushIndex + 3] == 255
end

local function forEachPixel(
	cX, cY, --[[ cStep, totalSteps, --]]
	self,
	imageP, brushP,
	spriteWidth, spriteHeight, brushWidth, brushHeight,
	bitmask, drawCommand,
	callback,
	...
)
	-- This function is ran at each step of the bline function

	local ix, iy, iw, ih = AABBMath.intersect(
		0, 0, spriteWidth, spriteHeight,
		cX, cY, brushWidth, brushHeight
	)

	if bitmask._active then
		-- Make sure we are within the bounds of the bitmask
		local bx, by, _, _, bw, bh = bitmask:getBounds()
		ix, iy, iw, ih = AABBMath.intersect(
			ix, iy, iw, ih,
			bx, by, bw, bh
		)
	end

	local startBrushX, startBrushY =
		ix - cX,
		iy - cY
	local diffBrushWidth, diffBrushHeight =
		ix + brushWidth - (brushWidth - iw + cX) - 1,
		iy + brushHeight - (brushHeight - ih + cY) - 1

	if drawCommand then
		drawCommand:markRegion(ix, iy, iw, ih)
	end

	---@cast self Brush
	-- Change the set function if we're in scroll mode
	local getBrushIndex = simpleMaskBrushIndex
	local pasteMode = self.patternMode:getValue()
	local type = self.type:getValue()
	if type == "mask" then
		if pasteMode == "scrolloffset" or pasteMode == "scrollbeginning" then
			getBrushIndex = scrollMaskBrushIndex
		end
	else
		if pasteMode == "scrolloffset" or pasteMode == "scrollbeginning" then
			getBrushIndex = scrollColorBrushIndex
		else
			getBrushIndex = simpleColorBrushIndex
		end
	end

	-- Change the check function if the bitmask is active
	local canDrawHere = (bitmask._active and checkBitmask) or alwaysValid

	-- Check the brush pixel's validity
	local checkBrushPixel = (type == "mask" and maskBrushPixelValid) or colorBrushPixelValid

	local scrollOffsetX, scrollOffsetY = self.scrollOffsetX, self.scrollOffsetY
	for brushX = startBrushX, diffBrushWidth do
		local curX = cX + brushX
		for brushY = startBrushY, diffBrushHeight do
			local curY = cY + brushY

			-- Skip if we can't draw here
			if not canDrawHere(bitmask, curX, curY) then goto continue end

			-- Get the pixel inside of the brush data
			local brushIndex = getBrushIndex(
				curX, curY,
				brushX, brushY,
				brushWidth, brushHeight,
				scrollOffsetX, scrollOffsetY
			)

			-- Skip if the point on this brush is not valid (usually if alpha is not 255 for mask brushes)
			if not checkBrushPixel(brushP, brushIndex) then goto continue end

			-- Call the passed function
			local alphaValue = brushP[brushIndex]
			local imageIndex = (curX + curY * spriteWidth) * 4
			callback(imageP, brushP, imageIndex, brushIndex, curX, curY, alphaValue, ...)
			::continue::
		end
	end
end

---Applies a function per valid pixel
---@param callback fun(imageP: ffi.cdata*, brushP: ffi.cdata*, imageIndex: integer, brushIndex: integer, curX: integer, curY: integer, alphaValue: integer, ...): nil
---@param imageData love.ImageData
---@param startX integer
---@param startY integer
---@param endX integer
---@param endY integer
---@param bitmask Bitmask
---@param drawCommand DrawCommand?
function Brush:forEachPixel(callback, imageData, startX, startY, endX, endY, bitmask, drawCommand, ...)
	local continuous = self.continuous:get()
	local imageP = ffi.cast("uint8_t*", imageData:getFFIPointer())
	local brushP = ffi.cast("uint8_t*", self.brushData:getFFIPointer())
	local offsetX, offsetY = self.offsetX, self.offsetY

	local spriteWidth, spriteHeight = imageData:getDimensions()
	local brushWidth, brushHeight = self.w, self.h

	-- Make the algorithm only run once
	if not continuous then
		startX, startY = endX, endY
	end

	bline(
		startX - offsetX, startY - offsetY,
		endX - offsetX, endY - offsetY,
		forEachPixel,
		self,
		imageP, brushP,
		spriteWidth, spriteHeight, brushWidth, brushHeight,
		bitmask,
		drawCommand,
		callback,
		...
	)
end


local flatMaskShaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	vec4 pixel = Texel(texture, texture_coords);
	return pixel.rrrr * color;
}
]]

-- :(
--[[ local outlineShaderCode = [[
	extern vec2 pixelsize;
	extern float size = 1;
	extern float smoothness = 1;

	vec4 effect(vec4 color, Image texture, vec2 uv, vec2 fc) {
		float a = 0;
		for(float y = -size; y <= size; ++y) {
			for(float x = -size; x <= size; ++x) {
				a += Texel(texture, uv + vec2(x * pixelsize.x, y * pixelsize.y)).r;
			}
		}
		a = color.r * min(1, a / (2 * size * smoothness + 1));

		return vec4(color.rrr, a);
	}
]] --]]

local invertMaskShaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec3 inverted = vec3(1., 1., 1.) - color.rgb;
	return pixel.rrrr * vec4(inverted, 1.);
}
]]

local flatColorShaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	vec4 pixel = Texel(texture, texture_coords);
	return pixel.rgba;
}
]]

local invertColorShaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	vec4 pixel = Texel(texture, texture_coords);
	vec3 inverted = vec3(1., 1., 1.) - pixel.rgb;
	return vec4(inverted, pixel.a);
}
]]

local maskShaders = {
	flat = love.graphics.newShader(flatMaskShaderCode),
	-- outline = love.graphics.newShader(outlineShaderCode),
	invert = love.graphics.newShader(invertMaskShaderCode),
}

local colorShaders = {
	flat = love.graphics.newShader(flatColorShaderCode),
	invert = love.graphics.newShader(invertColorShaderCode),
}

---@alias Brush.DrawShader
---| "flat"
---| "invert"

---Draws the brush
---@param x integer
---@param y integer
---@param shaderMode Brush.DrawShader?
function Brush:draw(x, y, shaderMode)
	if not shaderMode then shaderMode = "flat" end
	local shaders = (self.type:getValue() == "mask" and maskShaders) or colorShaders
	local shader = shaders[shaderMode]

	local offsetX, offsetY =
		self.offsetX, self.offsetY

	love.graphics.setShader(shader)
	love.graphics.draw(self.brushImage, x - offsetX, y - offsetY)
	love.graphics.setShader()
end

---Draws the brush where it would be on an image
---@param x integer
---@param y integer
---@param shaderMode Brush.DrawShader?
---@param canvas SpriteCanvas
function Brush:drawOnCanvas(x, y, shaderMode, canvas)
	if not shaderMode then shaderMode = "flat" end
	local shaders = (self.type:getValue() == "mask" and maskShaders) or colorShaders
	local shader = shaders[shaderMode]

	love.graphics.push("all")
	local patternMode = self.patternMode:getValue()
	local offsetX, offsetY =
		self.offsetX, self.offsetY
	local bw, bh = self.w, self.h

	if patternMode ~= "scrolloffset" then
		-- Don't pretend to scroll
		love.graphics.setShader(shader)
		love.graphics.draw(self.brushImage, x - offsetX, y - offsetY)
		love.graphics.setShader()
	else
		-- Do pretend to scroll
		love.graphics.setShader(shader)

		local brushX, brushY =
			x - (x - self.sourceOffsetX:get() - canvas.imageX) % bw,
			y - (y - self.sourceOffsetY:get() - canvas.imageY) % bh
		local cameraX, cameraY, scale = canvas.cameraX, canvas.cameraY, canvas.scale

		love.graphics.intersectScissor(
			canvas.x - (cameraX - x + math.floor(bw * 0.5)) * scale + canvas.w * 0.5,
			canvas.y - (cameraY - y + math.floor(bh * 0.5)) * scale + canvas.h * 0.5,
			bw * scale - 1,
			bh * scale - 1
		)

		--TODO: Make this draw 4 times instead of 9
		for cx = -1, 1 do
			for cy = -1, 1 do
				love.graphics.draw(
					self.brushImage,
					brushX + cx * bw,
					brushY + cy * bh
				)
			end
		end
		love.graphics.setShader()
	end

	love.graphics.pop()
end

return Brush
