local Plan = require "lib.plan"
local Button = require "ui.components.button.button"

---@class IconButton: Button
local IconButton = Button:extend()

---@param rules Plan.Rules
---@param onClick fun(self: self): nil
---@param icon SpriteSheet
---@param frame integer
---@param scale integer
function IconButton:new(rules, onClick, icon, frame, scale)
	IconButton.super.new(self, rules, onClick)
	self.icon = icon
	self.frame = frame
	self.scale = scale
	self._offsetX = 0
	self._offsetY = 0
end

function IconButton:draw()
	IconButton.super.draw(self)
	if self.icon then
		local scale = self.scale
		self.icon:draw(self.frame, self.x + self._offsetX, self.y + self._offsetY, scale, scale)
	end
end

function IconButton:refresh()
	IconButton.super.refresh(self)
	local scale = self.scale
	local iw, ih = self.icon.frameSizeX * scale, self.icon.frameSizeY * scale
	self._offsetX, self._offsetY = (self.w - iw) * 0.5, (self.h - ih) * 0.5
end

return IconButton
