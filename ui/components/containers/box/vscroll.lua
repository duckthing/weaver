local VBox = require "ui.components.containers.box.vbox"

---@class VScroll: VBox
local VScroll = VBox:extend()
VScroll.CLASS_NAME = "VScroll"
---@type integer
VScroll.scrollSpeed = 50

function VScroll:new(rules)
	VScroll.super.new(self, rules)
	---@type boolean
	self.allowScrolling = true
end

function VScroll:wheelmoved(_, y)
	if self.allowScrolling then
		local factor = (self.direction == "first" and 1) or -1
		self.offset = self.offset - y * self.scrollSpeed * factor
		self:sort()
	end
end

return VScroll
