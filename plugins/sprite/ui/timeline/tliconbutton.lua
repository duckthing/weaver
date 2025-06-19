local TLButton = require "plugins.sprite.ui.timeline.tlbutton"

---@class Timeline.IconButton: Button
local TLIconButton = TLButton:extend()

---@param rules Plan.Rules
---@param onClick fun(self: self): nil
---@param icon SpriteSheet
---@param frame integer
---@param scale integer
function TLIconButton:new(rules, onClick, icon, frame, scale)
	TLIconButton.super.new(self, rules, onClick)
	self.icon = icon
	self.frame = frame
	self.scale = scale
	self._offsetX = 0
	self._offsetY = 0
end

function TLIconButton:draw()
	TLIconButton.super.draw(self)
	if self.icon then
		love.graphics.setColor(1, 1, 1)
		local scale = self.scale
		self.icon:draw(self.frame, self.x + self._offsetX, self.y + self._offsetY, scale, scale)
	end
end

function TLIconButton:refresh()
	TLIconButton.super.refresh(self)
	local scale = self.scale
	local iw, ih = self.icon.frameSizeX * scale, self.icon.frameSizeY * scale
	self._offsetX, self._offsetY = (self.w - iw) * 0.5, (self.h - ih) * 0.5
end

return TLIconButton
