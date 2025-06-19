local Plan = require "lib.plan"

local Container = Plan.Container

---@class BaseButton: Plan.Container
local BaseButton = Container:extend()

function BaseButton:new(rules, onClick)
	BaseButton.super.new(self, rules)
	if onClick then
		self.onClick = onClick
	end
	self.hovering = false
end

function BaseButton:pointerentered()
	self.hovering = true
end

function BaseButton:pointerexited()
	self.hovering = false
end

function BaseButton:mousepressed(x, y, button)
	if button == 1 then
		self.pressing = true
		self:getFocus()
	end
end

function BaseButton:mousereleased(x, y, button)
	if button == 1 and self.pressing then
		self.pressing = false
		self:releaseFocus()
		if self:isOverlapping(x, y) then
			self:onClick()
		end
	end
end

function BaseButton:onClick()
end

return BaseButton
