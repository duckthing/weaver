local Plan = require "lib.plan"

---@class Popup: Plan.Container
local Popup = Plan.Container:extend()

function Popup:new(rules)
	Popup.super.new(self, rules)
	self.isPoppedUp = false
	self.closeOnOutOfBounds = true
	self._active = false
	self._clipMode = "independent"
end

---Activates the Popup
function Popup:popup()
	if not self.isPoppedUp then
		self.isPoppedUp = true
		self:enable()
		self:_pushModal()
		self:onPopup()
	end
end

---Convenience function that centers the Popup and activates it.
---
---Requires that the X and Y rules do nothing/are Keep.
function Popup:popupCentered()
	local root = self:getRoot().root
	local dw, dh = self:getDesiredDimensions()
	local sw, sh =
		self.rules:getWidth():realise("w", self, self.rules, dw, dh),
		self.rules:getHeight():realise("h", self, self.rules, dw, dh)
	local rw, rh = root.w, root.h
	self.x, self.y =
		(rw - sw) * 0.5,
		(rh - sh) * 0.5
	self:popup()
end

function Popup:close()
	if self.isPoppedUp then
		self.isPoppedUp = false
		self:disable()
		self:_popModal()
		self:onClose()
	end
end

-- This prevents the popup from drawing children normally.
-- Use Popup:modaldraw() instead.
function Popup:draw() end

--- Use this function when you want to draw the modal when it is active.
function Popup:modaldraw()
	Popup.super.draw(self)
end
function Popup:onPopup() end
function Popup:onClose() end

--- If the popup is clicked out of bounds, this will run
--- with the corresponding parameters
---@param event string
function Popup:outofbounds(event, ...)
	if self.isPoppedUp and self.closeOnOutOfBounds then
		if event == "mousepressed" then
			local _, _, button = ...
			if button == 1 then
				self:close()
			end
		end
	end
end

return Popup
