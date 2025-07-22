local Object = require "lib.classic"

--- Shapes are used for the DrawShape tool
--- There are no special algorithms here
---@class Shape: Object
local Shape = Object:extend()
Shape.TYPE = "Shape"

function Shape:new()
	Shape.super.new(self)
end

---Draws this shape from (ax, ay) to (bx, by) image coordinates
---@param ax integer
---@param ay integer
---@param bx integer
---@param by integer
function Shape:draw(ax, ay, bx, by)
end

---Applies this shape
---@param ax integer
---@param ay integer
---@param bx integer
---@param by integer
function Shape:apply(ax, ay, bx, by)
end

function Shape:_tostring()
	return self.TYPE
end

return Shape
