local Shape = require "plugins.sprite.tools.shapes.shape"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Pencil = require "plugins.sprite.tools.pencil"
local bline = require "src.common.bline"

---@class Line: Shape
local Line = Shape:extend()
Line.TYPE = "Line"

function Line:draw(ax, ay, bx, by)
	local brush = SpriteTool.brush:get()

	bline(ax, ay, bx, by,
	function (curX, curY)
		brush:drawOnCanvas(curX, curY, "flat", SpriteTool.canvas)
	end)
end

function Line:apply(ax, ay, bx, by)
	Pencil:startPress(ax, ay)
	Pencil:pressing(bx, by)
	Pencil:stopPress(bx, by)
end

return Line
