local Plan = require "lib.plan"
local Fonts = require "src.global.fonts"
local Luvent = require "lib.luvent"
local BaseButton = require "ui.components.button.basebutton"
local SpriteSheet = require "src.spritesheet"

local defaultFont = Fonts.getDefaultFont()
---@type love.Image
local checkboxImage = love.graphics.newImage("assets/checkbox.png")
---@type SpriteSheet
local checkboxSheet = SpriteSheet.new(checkboxImage, 2, 1)

---@class CheckboxButton: BaseButton
local CheckboxButton = BaseButton:extend()

---@param self CheckboxButton
local function toggleCheckbox(self)
	local newValue = not self.checked
	self:setChecked(newValue)
	self.checkboxPressed:trigger(newValue)
	if self._boundProperty then
		self._boundProperty:set(newValue)
	end
end

---@param rules Plan.Rules
---@param checked boolean?
---@param label string?
function CheckboxButton:new(rules, checked, label)
	CheckboxButton.super.new(self, rules, toggleCheckbox)
	---@type boolean
	self.checked = checked or false
	---@type string
	self.label = label or ""
	---@type Property?
	self._boundProperty = nil
	---@type string?
	self._boundPropertyAction = nil
	---@type love.Text
	self._textObj = love.graphics.newText(defaultFont, self.label)
	---@type integer
	self._frame = (self.checked and 2) or 1
	---@type integer
	self.paddingX = 10
	---@type integer, integer, integer, integer
	self._offsetX, self._offsetY, self._checkX, self._checkY =
		0, 0, 0, 0

	---@type Luvent
	self.checkboxPressed = Luvent.newEvent()
end

---Sets the checked value without triggering the event
---@param checked boolean
function CheckboxButton:setChecked(checked)
	self.checked = checked
	self._frame = (checked and 2) or 1
end

---Binds the CheckboxButton to a BoolProperty changing.
---Call without a property to remove it.
---@param newProperty BoolProperty?
function CheckboxButton:bindToProperty(newProperty)
	local oldProperty = self._boundProperty

	-- Both new and old properties are the same, do nothing
	if newProperty == oldProperty then return end
	self._boundProperty = newProperty

	-- Different from new property, remove the action bound to the property
	if oldProperty then
		-- Remove the action from the old property
		oldProperty.valueChanged:removeAction(self._boundPropertyAction)
		self._boundPropertyAction = nil
	end

	if newProperty then
		self._boundPropertyAction =
			newProperty.valueChanged:addAction(function(property, value)
				self:setChecked(value)
			end)
		self:setChecked(newProperty:get())
		self:setLabel(newProperty.name)
	end
end

local margin = 5
local checkboxSize = 20

---@param label string?
function CheckboxButton:setLabel(label)
	self.label = label or ""
	self._textObj:setFont(defaultFont)
	self._textObj:set(self.label)

	local textW, _ = self._textObj:getDimensions()
	local halfPaddingX = self.paddingX * 0.5

	self._checkX = halfPaddingX + self.x
	self._offsetX = self._checkX + checkboxSize + margin
	local newW = self._offsetX - self.x + halfPaddingX + textW
	if self.w ~= newW then
		self.w = newW
		self:bubble("_bubbleSizeChanged")
	end
end

function CheckboxButton:refresh()
	CheckboxButton.super.refresh(self)
	local textW, textH = self._textObj:getDimensions()
	local halfPaddingX = self.paddingX * 0.5
	self._checkX = halfPaddingX + self.x
	self._checkY = (self.h - checkboxSize) * 0.5 + self.y
	self._offsetX = self._checkX + checkboxSize + margin
	self._offsetY = (self.h - textH) * 0.5 + self.y

	local newW = self._offsetX - self.x + halfPaddingX + textW
	self.w = newW
	-- TODO: Clean this
	self.w = self.rules:getWidth():realise("w", self, self.rules)
end

function CheckboxButton:draw()
	local hovering, pressing = self.hovering, self.pressing

	if pressing then
		love.graphics.setColor(0.15, 0.15, 0.3)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
		love.graphics.setColor(0.6, 0.6, 0.6)
	elseif hovering then
		love.graphics.setColor(0.3, 0.3, 0.5)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
		love.graphics.setColor(1, 1, 1)
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(self._textObj, self._offsetX, self._offsetY)
	checkboxSheet:draw(self._frame, self._checkX, self._checkY, 2, 2)
	love.graphics.setColor(1, 1, 1)
end

function CheckboxButton:destroy(recursive)
	CheckboxButton.super.destroy(self, recursive)
	self:bindToProperty()
end

return CheckboxButton
