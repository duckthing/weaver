local SpriteTool = require "plugins.sprite.tools.spritetool"
local LabelProperty = require "src.properties.label"
local DrawCommand = require "plugins.sprite.commands.drawcommand"

---@class SpriteEraser: SpriteTool
local Eraser = SpriteTool:extend()

---@type DrawCommand
local command = nil

function Eraser:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index then
		local sprite = SpriteTool.sprite
		local canvas = SpriteTool.canvas
		if not sprite or not canvas then return end
		if SpriteTool.drawing then
			love.graphics.setColor(1, 1, 1)
		end

		-- local canvasScale = SpriteTool.canvas.scale
		-- if canvasScale > 3 then
		-- 	love.graphics.setLineWidth(4 / canvasScale)
		-- 	love.graphics.rectangle("line", imageX, imageY, 1, 1)
		-- else
		-- 	love.graphics.rectangle("fill", imageX, imageY, 1, 1)
		-- end
		love.graphics.setColor(1., 1., 1., 0.7)
		SpriteTool.brush:get():drawOnCanvas(imageX, imageY, "flat", canvas)
	end
end

function Eraser:canDraw()
	return Eraser.super.canDraw(SpriteTool) and SpriteTool.cel ~= nil
end


---@param imageX integer
---@param imageY integer
function Eraser:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local cel = SpriteTool.cel
	if not cel then return end

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY

	local activeLayer = SpriteTool.layer
	if not activeLayer then return end
	---@type love.ImageData
	local dbData = sprite.spriteState.drawCel.data

	sprite.undoStack:pushGroup()
	command = DrawCommand(sprite, cel)

	local liftCommand, _ = SpriteTool.applyFromSelection()
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

	dbData:paste(cel.data, 0, 0, 0, 0, sprite.width, sprite.height)
	Eraser:pressing(imageX, imageY)
	activeLayer.editorData.canvas.visible = false
	SpriteTool.drawing = true
	sprite.spriteState.includeDrawBuffer = true
end

local function callback(imageP, brushP, imageIndex, brushIndex, curX, curY, alphaValue)
	imageP[imageIndex    ] = 0
	imageP[imageIndex + 1] = 0
	imageP[imageIndex + 2] = 0
	imageP[imageIndex + 3] = 0
end

---@param imageX integer
---@param imageY integer
function Eraser:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local drawCel = sprite.spriteState.drawCel
	local bitmask = sprite.spriteState.bitmask

	---@type Brush
	local brush = SpriteTool.brush:get()

	local lastX, lastY = SpriteTool.lastX, SpriteTool.lastY

	SpriteTool:transformToCanvas(
		lastX, lastY, imageX, imageY,
		function(ax, ay, bx, by, ...)
			brush:forEachPixel(
				callback,
				drawCel.data, ax, ay, bx, by, bitmask, command,
				...
			)
		end,
		drawCel.data, lastX, lastY, imageX, imageY, bitmask, command
	)

	drawCel:update()

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
end

---@param imageX integer
---@param imageY integer
function Eraser:stopPress(imageX, imageY)
	if not SpriteTool.drawing then return end
	local sprite = SpriteTool.sprite
	if not sprite then return end

	local activeLayer = SpriteTool.layer
	if not activeLayer then return end
	local cel = SpriteTool.cel
	if not cel then return end
	local drawCel = sprite.spriteState.drawCel

	-- TODO: possible issue with love2d documentation reading out of bounds?
	-- https://www.love2d.org/wiki/ImageData:mapPixel
	--print(layerImageData:getSize())
	--print(4 * (width * height - 1))
	command:completeMark(drawCel, "copy")
	sprite.undoStack:commit(command)

	cel:update()
	activeLayer.editorData.canvas.visible = true

	local liftCommand = SpriteTool.liftIntoSelection()
	--[[ if liftCommand then
		command.transientRedo = true
		liftCommand.transientRedo = false
	end --]]
	sprite.undoStack:popGroup()

	local brush = SpriteTool.brush:get()
	local pasteMode = brush.patternMode:getValue()
	if pasteMode == "scrollbeginning" then
		brush.scrollOffsetX, brush.scrollOffsetY =
			0, 0
	elseif pasteMode == "scrolloffset" then
		brush.scrollOffsetX, brush.scrollOffsetY = brush.sourceOffsetX:get(), brush.sourceOffsetY:get()
	end


	SpriteTool.drawing = false
	sprite.spriteState.includeDrawBuffer = false
end

---@type LabelProperty
Eraser.name = LabelProperty(Eraser, "name", "Eraser")
local properties = {
	Eraser.name,
	SpriteTool.brush,
}

function Eraser:getProperties()
	return properties
end

return Eraser
