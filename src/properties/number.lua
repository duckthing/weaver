local Plan = require "lib.plan"
local Property = require "src.properties.property"
local Label = require "ui.components.text.label"
local Range = require "src.data.range"
local Slidebox = require "ui.components.range.slidebox"
local VBox = require "ui.components.containers.box.vbox"
local LineEdit = require "ui.components.text.lineedit"

---@class NumberProperty: Property
local NumberProperty = Property:extend()
NumberProperty.type = "number"

function NumberProperty:new(object, name, value)
	NumberProperty.super.new(self, object, name, value)
	---@type Range
	self.range = Range()

	if value then
		self.range
			:setDefaultValue(value)
			:setValue(value)
	end

	self._onRangeValueChangedAction = self.range.valueChanged:addAction(function(range, value)
		self.value = value
		self.valueChanged:trigger(self, value)
	end)
	self.value = self.range.value
end

---Returns the value
---@return number
function NumberProperty:get()
	return self.value
end

---Sets the value of the property
---@param value number
function NumberProperty:set(value)
	-- The event is triggered in here
	self.range:setValue(value)
end

---Returns the Range object
---@return Range
function NumberProperty:getRange()
	return self.range
end

local nanString = tostring(0/0)

---@param self LineEdit
local function numberValidateInput(self)
	local value = tonumber(self.inputfield:getText())
	if value == nil or tostring(value) == nanString or math.abs(value) == math.huge then return false end

	value = self.property:getRange():sanitizeNumber(value)
	self:setText(tostring(value))
	return true
end

---@class NumberProperty.HElement: Slidebox
local NumberHElement = Slidebox:extend()

---@param rules Plan.Rules
---@param property NumberProperty
function NumberHElement:new(rules, property)
	NumberHElement.super.new(self, rules, property.range)
	self.property = property
	self:setName(self.property.name)
end

function NumberProperty:getHElement()
	return NumberHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(0))
		:addWidth(Plan.keep())
		:addHeight(Plan.parent()),
		self
	)
end

---@class NumberProperty.VElement: VBox
local NumberVElement = VBox:extend()

---@param rules Plan.Rules
---@param property NumberProperty
function NumberVElement:new(rules, property)
	NumberVElement.super.new(self, rules, property.range)
	self.property = property

	---@type Label
	local label = Label(Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(20)),
		self.property.name
	)

	self.label = label
	self:addChild(label)

	---@type LineEdit
	local lineEdit = LineEdit(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.pixel(20)),
		tostring(property:get())
	)

	lineEdit.validateInput = numberValidateInput
	self.lineEdit = lineEdit
	self.lineEdit.property = property

	self._textSubmittedAction = self.lineEdit.textSubmitted:addAction(function(text)
		property:set(tonumber(text))
	end)

	self._valueChangedAction = property.valueChanged:addAction(function(property, value)
		lineEdit:setText(tostring(value))
	end)

	self:addChild(lineEdit)
end

function NumberVElement:destroy(...)
	NumberVElement.super.destroy(self, ...)
	self.lineEdit.textSubmitted:removeAction(self._textSubmittedAction)
	self.property.valueChanged:removeAction(self._valueChangedAction)
end

function NumberProperty:getVElement()
	return NumberVElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.pixel(40)),
		self
	)
end

return NumberProperty
