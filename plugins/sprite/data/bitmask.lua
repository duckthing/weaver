local ffi = require "ffi"
local Object = require "lib.classic"
---@class Bitmask
local Bitmask = require "lib.bitmask"

-- This isn't the actual bitmask, just a wrapper that adds a few functions to it.

---@class Bitmask.Renderer: Object
local BitmaskRenderer = Object:extend()

---Creates a new Bitmask.Renderer for this Bitmask
---@param ... unknown
---@return Bitmask.Renderer
function Bitmask.newRenderer(...)
	return BitmaskRenderer(...)
end

local bitmaskShaderCode = [[
extern vec2 stepSize;
extern float time;

vec4 effect( vec4 col, Image texture, vec2 texturePos, vec2 screenPos )
{
	// get color of pixels:
	float alpha = 4.0*Texel( texture, texturePos ).r;
	alpha -= Texel( texture, texturePos + vec2( stepSize.x, 0.0f ) ).r;
	alpha -= Texel( texture, texturePos + vec2( -stepSize.x, 0.0f ) ).r;
	alpha -= Texel( texture, texturePos + vec2( 0.0f, stepSize.y ) ).r;
	alpha -= Texel( texture, texturePos + vec2( 0.0f, -stepSize.y ) ).r;

	// calculate resulting color
	float num = step(
		mod(time +
			0.05 * screenPos.x +
			0.05 * screenPos.y,
		1.f),
	0.5f);

	return vec4( num, num, num, min(alpha, 1.f) * 0.6 );
}
]]
local bitmaskShader = love.graphics.newShader(bitmaskShaderCode)

---@param bitmask Bitmask
function BitmaskRenderer:new(bitmask)
	BitmaskRenderer.super.new(self)
	self.bitmask = bitmask
	self.width, self.height = bitmask.width, bitmask.height
	self.image = love.image.newImageData(bitmask.width, bitmask.height, "r8")
	self.graphicsImage = love.graphics.newImage(self.image)
	self.graphicsImage:setWrap("clampzero", "clampzero")
end

function BitmaskRenderer:update()
	local bitmask = self.bitmask
	local width, height = bitmask.width, bitmask.height
	-- Check if dimensions changed
	if self.width ~= width or self.height ~= height then
		self.width, self.height =
			width, height
		self.image:release()
		self.image = love.image.newImageData(width, height, "r8")
	end

	local imageP = ffi.cast("uint8_t*", self.image:getFFIPointer())
	for x = 0, width - 1 do
		for y = 0, height - 1 do
			if bitmask:get(x, y) then
				-- True, set to 255
				imageP[x + y * width] = 255
			else
				-- False, set to 0
				imageP[x + y * width] = 0
			end
		end
	end
	self.graphicsImage:release()
	self.graphicsImage = love.graphics.newImage(self.image)
	self.graphicsImage:setWrap("clampzero", "clampzero")
end

local vals = {0.1, 0.1}

---Draws the renderer
---@param x integer
---@param y integer
function BitmaskRenderer:draw(x, y, scale)
	if self.bitmask._active then
		vals[1], vals[2] = 3 / self.width / scale, 3 / self.height / scale
		local oldShader = love.graphics.getShader()
		bitmaskShader:send("stepSize", vals)
		bitmaskShader:send("time", (love.timer.getTime() * 0.3) % 1)
		love.graphics.setShader(bitmaskShader)
		love.graphics.draw(self.graphicsImage, x, y)
		love.graphics.setShader(oldShader)
	end
end

return Bitmask
