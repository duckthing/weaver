local ffi = require "ffi"
local bit = require "bit"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local DrawCommand = require "plugins.sprite.commands.drawcommand"
local Status = require "src.global.status"

local LabelProperty = require "src.properties.label"
local EnumProperty = require "src.properties.enum"

---@class SpriteDrawShape: SpriteTool
local DrawShape = SpriteTool:extend()

local startX, startY = 0, 0

---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function DrawShape:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index then
		local color =
			SpriteTool.primaryPressed and SpriteTool.primaryColor
			or
			SpriteTool.secondaryColor
		local brush = SpriteTool.brush:get()
		if brush.blendMode:getValue() == "shade" then
			love.graphics.setColor(1, 1, 1, 0.6)
		else
			love.graphics.setColor(color)
		end

		-- World coords are added, as other methods are normalized to image coords
		-- This normalizes them to the draw method
		local spriteState = SpriteTool.sprite.spriteState
		if SpriteTool.drawing then
			local worldX, worldY =
				spriteState.imageX, spriteState.imageY
			---@type Shape
			local shape = DrawShape.shape:getValue()
			shape:draw(
				startX + worldX, startY + worldY,
				imageX, imageY
			)
		else
			brush:drawOnCanvas(imageX, imageY, "flat", SpriteTool.canvas)
		end
	end
end


---@param imageX integer
---@param imageY integer
function DrawShape:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
	startX, startY = imageX, imageY
	SpriteTool.drawing = true

	sprite.undoStack:pushGroup()
	SpriteTool.applyFromSelection()
	SpriteTool:ensureCel()

	DrawShape:pressing(imageX, imageY)
end

---@param imageX integer
---@param imageY integer
function DrawShape:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local drawCel = sprite.spriteState.drawCel
	local color =
		SpriteTool.primaryPressed and SpriteTool.primaryColor
		or
		SpriteTool.secondaryColor

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
end

---@param imageX integer
---@param imageY integer
function DrawShape:stopPress(imageX, imageY)
	if not SpriteTool.drawing then return end
	local sprite = SpriteTool.sprite
	SpriteTool.drawing = false
	if not sprite then return end

	---@type Shape
	local shape = DrawShape.shape:getValue()
	shape:apply(startX, startY, imageX, imageY)

	local brush = SpriteTool.brush:get()
	if not brush.continuous:get() then
		Status.pushTemporaryMessage("Brush is not continuous; drawing points only", "warning", 3)
	end

	sprite.undoStack:popGroup()
end

local options = {
	{
		name = "Line",
		value = require "plugins.sprite.tools.shapes.line",
	},
	{
		name = "Rectangle",
		value = require "plugins.sprite.tools.shapes.rectangle",
	},
	{
		name = "Ellipse",
		value = require "plugins.sprite.tools.shapes.ellipse",
	},
	{
		name = "Stamp",
		value = require "plugins.sprite.tools.shapes.stamp",
	},
}

---@type LabelProperty
DrawShape.name = LabelProperty(DrawShape, "Name", "Draw Shape")
---@type EnumProperty
DrawShape.shape = EnumProperty(DrawShape, "Shape", "Line")
DrawShape.shape:setOptions(options)

local properties = {
	DrawShape.name,
	DrawShape.shape,
	SpriteTool.brush,
	SpriteTool.mirrorX,
	SpriteTool.mirrorY,
}

function DrawShape:getProperties()
	return properties
end

return DrawShape
