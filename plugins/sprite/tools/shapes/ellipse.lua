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
	local brush = SpriteTool.brush:get()
	-- Out of bounds, with offsets added so that patterns can be calculated
	local oobX, oobY =
		-brush.w * 2 - math.abs(brush.offsetX) - ax1 % brush.w,
		-brush.h * 2 - math.abs(brush.offsetY) - ay1 % brush.h
	Pencil:startPress(oobX, oobY)

	local lastContinuous = Brush.continuous:get()
	local lastAlgo = Brush:getAlgorithm()
	Brush.continuous:set(true)
	Brush:setAlgorithm(bellipse)

	local command = Pencil:_getDrawCommand()
	if not command then error() end

	local drawCel = sprite.spriteState.drawCel

	local callback, tupleFunc = Pencil:getPixelCallback(command)
	if not callback or not tupleFunc then error() end

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

	Pencil:stopPress(oobX, oobY)
end

return Ellipse
