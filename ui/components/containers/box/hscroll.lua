local HBox = require "ui.components.containers.box.hbox"

---@class HScroll: HBox
local HScroll = HBox:extend()
HScroll.CLASS_NAME = "HScroll"
---@type integer
HScroll.scrollSpeed = 50

function HScroll:new(rules)
	HScroll.super.new(self, rules)
	---@type boolean
	self.allowScrolling = true
end

function HScroll:wheelmoved(_, y)
	if self.allowScrolling then
		local factor = (self.direction == "first" and 1) or -1
		self.offset = self.offset - y * self.scrollSpeed * factor
		self:sort()
	end
end

return HScroll
