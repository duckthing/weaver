local Plan = require "lib.plan"

---@class SplitHandle: Plan.Container
local SplitHandle = Plan.Container:extend()
SplitHandle.CLASS_NAME = "SplitHandle"

local hDragCursor = love.mouse.getSystemCursor("sizens")
local vDragCursor = love.mouse.getSystemCursor("sizewe")

local hFull = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.pixel(-5))
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(10))

local vFull = Plan.Rules.new()
	:addX(Plan.pixel(-5))
	:addY(Plan.pixel(0))
	:addWidth(Plan.pixel(10))
	:addHeight(Plan.parent())

---@param split HSplit | VSplit
---@param isVertical boolean
function SplitHandle:new(split, isVertical)
	local handleRules
	if isVertical then
		handleRules = hFull
	else
		handleRules = vFull
	end
	SplitHandle.super.new(self, handleRules)
	self.dragging = false
	self.hovering = false
	self.split = split
	self.isVertical = isVertical
	self.parent = split
end

---@param x integer
---@param y integer
---@param button integer
function SplitHandle:mousepressed(x, y, button)
	if button == 1 then
		self.dragging = true
		self:getFocus()
	end
end

function SplitHandle:mousereleased(_, _, button)
	if self.dragging and button == 1 then
		self.dragging = false
		self:releaseFocus()
		if not self.hovering then
			love.mouse.setCursor()
		end
	end
end

function SplitHandle:pointerentered()
	-- Show the drag cursor
	if not self.dragging then
		if self.isVertical then
			love.mouse.setCursor(hDragCursor)
		else
			love.mouse.setCursor(vDragCursor)
		end
	end
	self.hovering = true
end

function SplitHandle:pointerexited()
	-- Hide the drag cursor
	if not self.dragging then
		love.mouse.setCursor()
	end
	self.hovering = false
end

function SplitHandle:mousemoved(x, y)
	if self.dragging then
		local parent = self.parent
		local newSplitPos = 0
		if self.isVertical then
			newSplitPos = y - parent.y
		else
			newSplitPos = x - parent.x
		end
		parent.splitPosition = math.max(parent.minPosition, math.min(newSplitPos, parent.maxPosition))
		parent:updateSplit()
	end
end

function SplitHandle:draw()
	if self.dragging then
		love.graphics.setColor(0, 0, 0, 0.3)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	end
end

function SplitHandle:refresh()
	-- TODO: Find better solution for handle depth/priority?
	self._depth = self._depth + 100
	SplitHandle.super.refresh(self)
end

return SplitHandle
