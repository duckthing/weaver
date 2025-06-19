local Plan = require "lib.plan"
local Button = require "ui.components.button.button"
local Fonts = require "src.global.fonts"

local defaultFont = Fonts.getDefaultFont()

---@class LabelButton: Button
local LabelButton = Button:extend()

---@param rules Plan.Rules
---@param onClick fun(self: self): nil
---@param label string
function LabelButton:new(rules, onClick, label)
	LabelButton.super.new(self, rules, onClick)
	---@type string
	self.label = label or ""
	---@type love.Text
	self._textObj = love.graphics.newText(defaultFont, self.label)
	---@type number
	self._offsetX = 0
	---@type number
	self._offsetY = 0
	self.paddingX = 16
	self.dw = 0

	local textW, _ = self._textObj:getWidth()
	self.w = textW + self.paddingX
	self.dw = self.w
end

function LabelButton:setLabel(label)
	label = tostring(label) or ""
	self.label = label
	self._textObj:set(label)
	local textW, textH = self._textObj:getDimensions()
	if self.w ~= textW + self.paddingX then
		self.w = textW + self.paddingX
		self.dw = self.w
		self:bubble("_bubbleSizeChanged")
	end
end

function LabelButton:draw()
	LabelButton.super.draw(self)
	if self.pressing then
		love.graphics.setColor(0.6, 0.6, 0.6)
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(self._textObj, self._offsetX, self._offsetY)
	love.graphics.setColor(1, 1, 1)
end

function LabelButton:refresh()
	local textW, textH = self._textObj:getDimensions()
	if self.w ~= textW + self.paddingX then
		self.w = textW + self.paddingX
		self.dw = self.w
		self:bubble("_bubbleSizeChanged")
	end
	LabelButton.super.refresh(self)
	self._offsetX = (self.w - textW) * 0.5 + self.x
	self._offsetY = (self.h - textH) * 0.5 + self.y
end

function LabelButton:getDesiredDimensions()
	return self.dw, self._textObj:getHeight() + self.paddingX
end

return LabelButton
