local Shape = require "plugins.sprite.tools.shapes.shape"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Pencil = require "plugins.sprite.tools.pencil"
local bline = require "src.common.bline"

---@class Square: Shape
local Square = Shape:extend()
Square.TYPE = "Square"

function Square:draw(ax, ay, bx, by)
	local brush = SpriteTool.brush:get()
	local drawFunc = function(curX, curY)
		brush:drawOnCanvas(curX, curY, "flat", SpriteTool.canvas)
	end

	bline(ax, ay, ax, by, drawFunc)
	bline(ax, ay, bx, ay, drawFunc)
	bline(bx, ay, bx, by, drawFunc)
	bline(ax, by, bx, by, drawFunc)
end

function Square:apply(ax, ay, bx, by)
	Pencil:startPress(ax, ay)

	Pencil:pressing(bx, ay)
	Pencil:pressing(bx, by)
	Pencil:pressing(ax, by)
	Pencil:pressing(ax, ay)

	Pencil:stopPress(ax, ay)
end

return Square
