local Plan = require "lib.plan"
local Property = require "src.properties.property"
local VBox = require "ui.components.containers.box.vbox"
local Label = require "ui.components.text.label"
local LineEdit = require "ui.components.text.lineedit"

---@class StringProperty: Property
local StringProperty = Property:extend()
StringProperty.name = "String"

function StringProperty:new(...)
	StringProperty.super.new(self, ...)
	self.type = "string"
end

---Returns the value
---@return string
function StringProperty:get()
	return self.value
end

---Sets the value of the property
---@param value string
function StringProperty:set(value)
	if self.value ~= value then
		self.value = value
		self.valueChanged:trigger(self, value)
	end
end

---@class StringProperty.VElement: Plan.Container
local StringVElement = VBox:extend()

---@param rules Plan.Rules
---@param property Property
function StringVElement:new(rules, property)
	StringVElement.super.new(self, rules)
	self.property = property

	---@type Label
	self.label = Label(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(20)),
		property.name
	)
	self:addChild(self.label)

	---@type LineEdit
	self.lineEdit= LineEdit(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(20)),
		property.value
	)
	self:addChild(self.lineEdit)

	self._textSubmittedAction = self.lineEdit.textSubmitted:addAction(function(value)
		self.property:set(value)
	end)

	property.valueChanged:addAction(function(property, newText)
		self.lineEdit:setText(newText)
	end)
end

function StringProperty:getVElement()
	return StringVElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.pixel(40)),
		self
	)
end

return StringProperty
