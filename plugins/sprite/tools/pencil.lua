local ffi = require "ffi"
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
		love.graphics.setColor(color)
		Pencil.brush:get():drawOnCanvas(imageX, imageY, "flat", SpriteTool.canvas)
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
	local liftCommand, _ = SpriteTool.applyFromSelection()
	SpriteTool:ensureCel()
	command = DrawCommand(sprite, SpriteTool.cel)

	if liftCommand then
		liftCommand.transientUndo = false
		command.transientUndo = true
		-- command.transientRedo = true
	end

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

local function maskForEachPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, alphaValue, r, g, b)
	imageP[imageIndex    ] = r
	imageP[imageIndex + 1] = g
	imageP[imageIndex + 2] = b
	imageP[imageIndex + 3] = 255
end

local function colorForEachPixel(imageP, brushP, imageIndex, brushIndex, curX, curY, alphaValue)
	imageP[imageIndex    ] = brushP[brushIndex    ]
	imageP[imageIndex + 1] = brushP[brushIndex + 1]
	imageP[imageIndex + 2] = brushP[brushIndex + 2]
	imageP[imageIndex + 3] = brushP[brushIndex + 3]
end

---@param imageX integer
---@param imageY integer
function Pencil:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local drawCel = sprite.spriteState.drawCel
	local color = SpriteTool.primaryColor

	---@type Brush
	local brush = Pencil.brush:get()

	local bitmask = sprite.spriteState.bitmask
	local cr, cg, cb = love.math.colorToBytes(color[1], color[2], color[3])

	local callback = (brush.type:getValue() == "mask" and maskForEachPixel) or colorForEachPixel

	brush:forEachPixel(
		callback,
		drawCel.data, SpriteTool.lastX, SpriteTool.lastY, imageX, imageY, bitmask, command,
		cr, cg, cb
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
}

function Pencil:getProperties()
	return properties
end

return Pencil
