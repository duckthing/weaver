local Plan = require "lib.plan"

---@class Viewport: Plan.Container
local Viewport = Plan.Container:extend()

function Viewport:new(rules)
	Viewport.super.new(self, rules)
	self.cameraX, self.cameraY = 0, 0
	self.scale = 1
end

---Converts a UI into a viewport point
---@param x integer
---@param y integer
---@return integer
---@return integer
function Viewport:screenToViewportPoint(x, y)
	local factor = 1 / self.scale
	return (x - self.x - self.w * 0.5) * factor + self.cameraX,
			(y - self.y - self.h * 0.5) * factor + self.cameraY
end

---Moves the canvas by cx and cy, taking into account scale.
---
---Positive X is right, positive Y is down.
---@param cx number
---@param cy number
function Viewport:translate(cx, cy)
	local factor = 1 / self.scale
	self.cameraX = self.cameraX + cx * factor
	self.cameraY = self.cameraY + cy * factor
end

---Multiplies the current scale by factor. Does NOT set the scale.
---@param factor number
function Viewport:multScale(factor)
	self.scale = self.scale * factor
end

---Zooms the viewport to a screen point.
---@param sx number
---@param sy number
---@param factor number
function Viewport:zoomToScreenPoint(sx, sy, factor)
	-- TODO: Make less hacky?
	local zoomPointX, zoomPointY = sx - self.x - self.w * 0.5, sy - self.y - self.h * 0.5
	self:translate(zoomPointX, zoomPointY)
	self:multScale(factor)
	self:translate(-zoomPointX, -zoomPointY)
end

function Viewport:pushTransform()
	local scale = self.scale
	local factor = 1 / scale
	love.graphics.push("all")
	love.graphics.translate(self.x, self.y)
	love.graphics.scale(scale)
	love.graphics.translate(-self.cameraX + self.w * 0.5 * factor, -self.cameraY + self.h * 0.5 * factor)
end

function Viewport:popTransform()
	love.graphics.pop()
end

return Viewport
