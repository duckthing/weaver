local ffi = require "ffi"
local bit = require "bit"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local LabelProperty = require "src.properties.label"
local DrawCommand = require "plugins.sprite.commands.drawcommand"

---@class SpritePencil: SpriteTool
local Pencil = SpriteTool:extend()

---@type DrawCommand
local command = nil

---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function Pencil:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index and not SpriteTool.drawing then
		local color = SpriteTool.primaryColor
		local brush = SpriteTool.brush:get()
		if brush.blendMode:getValue() == "shade" then
			love.graphics.setColor(1, 1, 1, 0.6)
		else
			love.graphics.setColor(color)
		end
		brush:drawOnCanvas(imageX, imageY, "flat", SpriteTool.canvas)
	end
end

---@param imageX integer
---@param imageY integer
function Pencil:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
	SpriteTool.drawing = true
	sprite.spriteState.includeDrawBuffer = true

	sprite.undoStack:pushGroup()
	SpriteTool.applyFromSelection()
	SpriteTool:ensureCel()
	command = DrawCommand(sprite, SpriteTool.cel)

	local brush = SpriteTool.brush:get()
	local pasteMode = brush.patternMode:getValue()
	if pasteMode == "scrollbeginning" then
		brush.scrollOffsetX, brush.scrollOffsetY =
			imageX - brush.offsetX, imageY - brush.offsetY
	elseif pasteMode == "scrolloffset" then
		brush.scrollOffsetX, brush.scrollOffsetY = brush.sourceOffsetX:get(), brush.sourceOffsetY:get()
	end

	Pencil:pressing(imageX, imageY)
end

---+ Uses brush as mask
---+ Overwrites alpha and color at this point
local function useBrushMaskBlendPerPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, r, g, b)
	imageP[imageIndex    ] = r
	imageP[imageIndex + 1] = g
	imageP[imageIndex + 2] = b
	imageP[imageIndex + 3] = 255 -- Only applied if the pixel in the draw buffer is alpha > 0
end

---+ Uses brush as mask
---+ Overwrites color if alpha value is 255
local function useBrushMaskLockAlphaPerPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, r, g, b, sourceP)
	if sourceP[imageIndex + 3] == 255 then
		imageP[imageIndex    ] = r
		imageP[imageIndex + 1] = g
		imageP[imageIndex + 2] = b
		imageP[imageIndex + 3] = 255
	end
end

---+ Uses brush color, pastes into this point
---+ Overwrites alpha and color at this point
local function useBrushColorBlendPerPixel(imageP, brushP, imageIndex, brushIndex, curX, curY)
	imageP[imageIndex    ] = brushP[brushIndex    ]
	imageP[imageIndex + 1] = brushP[brushIndex + 1]
	imageP[imageIndex + 2] = brushP[brushIndex + 2]
	imageP[imageIndex + 3] = brushP[brushIndex + 3]
end

---+ Uses brush color, pastes into this point
---+ Overwrites color if alpha value is 255
local function useBrushColorLockAlphaPerPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, sourceP)
	if sourceP[imageIndex + 3] == 255 then
		imageP[imageIndex    ] = brushP[brushIndex    ]
		imageP[imageIndex + 1] = brushP[brushIndex + 1]
		imageP[imageIndex + 2] = brushP[brushIndex + 2]
		imageP[imageIndex + 3] = brushP[brushIndex + 3]
	end
end

---+ Ignores brush type
---+ Sets a new color from the source and color ramps
local function useBrushAnyShadePerPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, sourceP, ramp)
	if sourceP[imageIndex + 3] > 0 then
		-- Alpha is not 0
		local sBit = bit.lshift(bit.lshift(sourceP[imageIndex], 8) + sourceP[imageIndex+1], 8) + sourceP[imageIndex+2]
		local cBit = ramp[sBit]
		if cBit ~= nil then
			local r, g, b =
				bit.rshift(cBit, 16),
				bit.band(bit.rshift(cBit, 8), 255),
				bit.band(cBit, 255)

			imageP[imageIndex    ] = r
			imageP[imageIndex + 1] = g
			imageP[imageIndex + 2] = b
			imageP[imageIndex + 3] = 255
		end
	end
end

---@type {[Brush.Type]: {[Brush.BlendMode]: function}}
local modeToMap = {
	mask = {
		blend = useBrushMaskBlendPerPixel,
		lockalpha = useBrushMaskLockAlphaPerPixel,
		shade = useBrushAnyShadePerPixel,
	},
	color = {
		blend = useBrushColorBlendPerPixel,
		lockalpha = useBrushColorLockAlphaPerPixel,
		shade = useBrushAnyShadePerPixel,
	}
}

---@param imageX integer
---@param imageY integer
function Pencil:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local drawCel = sprite.spriteState.drawCel
	local color =
		SpriteTool.primaryPressed and SpriteTool.primaryColor
		or
		SpriteTool.secondaryColor

	---@type Brush
	local brush = Pencil.brush:get()

	local bitmask = sprite.spriteState.bitmask
	local cr, cg, cb = love.math.colorToBytes(color[1], color[2], color[3])

	local brushTypeVal = brush.type:getValue()
	local blendModeVal = brush.blendMode:getValue()
	local callback = modeToMap[brushTypeVal][blendModeVal]

	---Returns the parameters as a tuple
	---@type fun(): ...
	local tupleFunc
	if brushTypeVal == "mask" then
		if blendModeVal == "blend" then
			tupleFunc = function()
				return
					cr, cg, cb
			end
		elseif blendModeVal == "lockalpha" then
			tupleFunc = function()
				return
					cr, cg, cb,
					ffi.cast("uint8_t*", sprite.spriteState:getCurrentCel().data:getFFIPointer())
			end
		elseif blendModeVal == "shade" then
			local forward, backward = sprite.spriteState.colorRamp:getRamps()
			local target = SpriteTool.primaryPressed and forward or backward
			tupleFunc = function()
				return
					ffi.cast("uint8_t*", sprite.spriteState:getCurrentCel().data:getFFIPointer()),
					target
			end
		end
	else
		if blendModeVal == "blend" then
			tupleFunc = function()
				return nil
			end
		elseif blendModeVal == "lockalpha" then
			tupleFunc = function()
				return
					ffi.cast("uint8_t*", sprite.spriteState:getCurrentCel().data:getFFIPointer())
			end
		elseif blendModeVal == "shade" then
			local forward, backward = sprite.spriteState.colorRamp:getRamps()
			local target = SpriteTool.primaryPressed and forward or backward
			tupleFunc = function()
				return
					ffi.cast("uint8_t*", sprite.spriteState:getCurrentCel().data:getFFIPointer()),
					target
			end
		end
	end

	local lastX, lastY = SpriteTool.lastX, SpriteTool.lastY

	SpriteTool:transformToCanvas(
		lastX, lastY, imageX, imageY,
		function(ax, ay, bx, by, xMult, yMult)
			brush:forEachPixel(
				callback,
				drawCel.data, ax, ay, bx, by,
				xMult, yMult,
				bitmask, command,
				tupleFunc()
			)
		end
	)

	drawCel:update()

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
end

---@param imageX integer
---@param imageY integer
function Pencil:stopPress(imageX, imageY)
	if not SpriteTool.drawing then return end
	local sprite = SpriteTool.sprite
	SpriteTool.drawing = false
	if not sprite then return end
	sprite.spriteState.includeDrawBuffer = false

	local cel = SpriteTool.cel
	if not cel then return end

	command:completeMark(sprite.spriteState.drawCel, "alphaBlend")
	sprite.undoStack:commit(command)
	SpriteTool.liftIntoSelection()
	sprite.undoStack:popGroup()

	local brush = SpriteTool.brush:get()
	local pasteMode = brush.patternMode:getValue()
	if pasteMode == "scrollbeginning" then
		brush.scrollOffsetX, brush.scrollOffsetY =
			0, 0
	elseif pasteMode == "scrolloffset" then
		brush.scrollOffsetX, brush.scrollOffsetY = brush.sourceOffsetX:get(), brush.sourceOffsetY:get()
	end

	cel:update()
end

---@type LabelProperty
Pencil.name = LabelProperty(Pencil, "Name", "Pencil")
local properties = {
	Pencil.name,
	SpriteTool.brush,
	SpriteTool.mirrorX,
	SpriteTool.mirrorY,
}

function Pencil:getProperties()
	return properties
end

return Pencil
