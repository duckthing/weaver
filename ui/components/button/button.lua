local NinePatch = require "src.ninepatch"
local BaseButton = require "ui.components.button.basebutton"

---@type love.Image
local buttonTexture = love.graphics.newImage("assets/buttons.png")
buttonTexture:setFilter("nearest", "nearest")

local normalButtonNP = NinePatch.new(3, 1, 3, 3, 1, 3, buttonTexture, 2, 1)
local pressedButtonNP = NinePatch.new(3, 1, 3, 3, 1, 3, buttonTexture, 2, 2)

---@class Button: BaseButton
local Button = BaseButton:extend()
Button.CLASS_NAME = "Button"

function Button:new(rules, onClick)
	Button.super.new(self, rules, onClick)
end

function Button:draw()
	love.graphics.setColor(1, 1, 1)
	if not self.pressing then
		normalButtonNP:draw(self.x, self.y, self.w, self.h, 2)
	else
		pressedButtonNP:draw(self.x, self.y, self.w, self.h, 2)
	end
end

return Button
