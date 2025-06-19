local NinePatch = require "src.ninepatch"
local BaseButton = require "ui.components.button.basebutton"

local backgroundTexture = love.graphics.newImage("assets/timeline_button.png")
backgroundTexture:setFilter("nearest", "nearest")
local backgroundNP = NinePatch.new(2, 1, 2, 2, 1, 2, backgroundTexture)

---@class Timeline.Button: BaseButton
local TLButton = BaseButton:extend()

---@param rules Plan.Rules
---@param onClick function
---@param scale integer
function TLButton:new(rules, onClick, scale)
	TLButton.super.new(self, rules, onClick)
	self.scale = scale
end

function TLButton:draw()
	if self.pressing then
		love.graphics.setColor(0.1, 0.1, 0.2)
	elseif self.hovering then
		love.graphics.setColor(0.25, 0.25, 0.5)
	else
		love.graphics.setColor(0.2, 0.2, 0.4)
	end
	backgroundNP:draw(self.x, self.y, self.w, self.h, self.scale)
	TLButton.super.draw(self)
end

return TLButton
