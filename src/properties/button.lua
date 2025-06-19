local Plan = require "lib.plan"
local Property = require "src.properties.property"
local LabelButton = require "ui.components.button.labelbutton"

---@class ButtonProperty: Property
local ButtonProperty = Property:extend()

---@alias ButtonProperty.Callback
---| fun(self: ButtonProperty.HElement): nil

function ButtonProperty:new(...)
	ButtonProperty.super.new(self, ...)
	self.type = "boolean"
	---@type ButtonProperty.Callback
	self.value = self.value
end

---Sets the function
---@param value ButtonProperty.Callback
function ButtonProperty:set(value)
	self.value = value
end

---Returns the value
---@return ButtonProperty.Callback
function ButtonProperty:get()
	return self.value
end

function ButtonProperty:serialize()
	return nil
end

---@class ButtonProperty.HElement: LabelButton
local BooleanHElement = LabelButton:extend()

---@param rules Plan.Rules
---@param property ButtonProperty
function BooleanHElement:new(rules, property)
	BooleanHElement.super.new(self, rules, property.value, property.name)
end

function ButtonProperty:getHElement()
	return BooleanHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(4))
		:addWidth(Plan.content(Plan.pixel(0)))
		:addHeight(Plan.max(8)),
		self
	)
end

---@class ButtonProperty.VElement: LabelButton
local BooleanVElement = LabelButton:extend()

---@param rules Plan.Rules
---@param property ButtonProperty
function BooleanVElement:new(rules, property)
	BooleanVElement.super.new(self, rules, property.value, property.name)
end

function ButtonProperty:getVElement()
	return BooleanVElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.content(Plan.pixel(0))),
		self
	)
end

function ButtonProperty:__tostring()
	return "ButtonProperty: "..tostring(self.value)
end

return ButtonProperty
