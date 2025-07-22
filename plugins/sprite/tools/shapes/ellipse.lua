local Shape = require "plugins.sprite.tools.shapes.shape"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Pencil = require "plugins.sprite.tools.pencil"
local Brush = require "plugins.sprite.brush.brush"
local bline = require "src.common.bline"
local bellipse = require "src.common.bellipse"
local DrawCommand = require "plugins.sprite.commands.drawcommand"

---@class Ellipse: Shape
local Ellipse = Shape:extend()
Ellipse.TYPE = "Ellipse"

function Ellipse:draw(ax, ay, bx, by)
	local brush = SpriteTool.brush:get()

	bellipse(ax, ay, bx, by,
	function (curX, curY)
		brush:drawOnCanvas(curX, curY, "flat", SpriteTool.canvas)
	end)
end

--[[ local lastX, lastY = 0, 0
local callback = function (curX, curY)
	lastX, lastY = curX, curY
	if not SpriteTool.drawing then
		Pencil:startPress(curX, curY)
	else
		Pencil:pressing(curX, curY)
	end
end --]]

function Ellipse:apply(ax1, ay1, bx2, by2)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	local lastContinuous = Brush.continuous:get()
	local lastAlgo = Brush:getAlgorithm()
	Brush.continuous:set(true)
	Brush:setAlgorithm(bellipse)

	---@type DrawCommand
	local command = DrawCommand(sprite, SpriteTool.cel)
	local drawCel = sprite.spriteState.drawCel

	local callback, tupleFunc = Pencil:getPixelCallback(command)
	if not callback or not tupleFunc then error() end

	local brush = SpriteTool.brush:get()


	SpriteTool:transformToCanvas(
		ax1, ay1, bx2, by2,
		function(ax, ay, bx, by, xMult, yMult)
			brush:forEachPixel(
				callback,
				drawCel.data, ax, ay, bx, by,
				xMult, yMult,
				tupleFunc()
			)
		end
	)

	Brush.continuous:set(lastContinuous)
	Brush:setAlgorithm(lastAlgo)

	command:completeMark(sprite.spriteState.drawCel, "alphaBlend")
	sprite.undoStack:commit(command)
end

return Ellipse
