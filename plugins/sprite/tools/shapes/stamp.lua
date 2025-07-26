local Shape = require "plugins.sprite.tools.shapes.shape"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Pencil = require "plugins.sprite.tools.pencil"
local bline = require "src.common.bline"

---@class Stamp: Shape
local Stamp = Shape:extend()
Stamp.TYPE = "Stamp"

function Stamp:draw(ax, ay, bx, by)
	local brush = SpriteTool.brush:get()

	brush:drawOnCanvas(ax, ay, "flat", SpriteTool.canvas)
end

function Stamp:apply(ax, ay, bx, by)
	Pencil:startPress(ax, ay)
	Pencil:stopPress(ax, ay)
end

return Stamp
