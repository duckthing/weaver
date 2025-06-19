local Plan = require "lib.plan"
local Property = require "src.properties.property"
local CheckboxButton = require "ui.components.button.checkboxbutton"

---@class BoolProperty: Property
local BoolProperty = Property:extend()

function BoolProperty:new(...)
	BoolProperty.super.new(self, ...)
	self.type = "boolean"
end

---Returns the value
---@return boolean
function BoolProperty:get()
	return self.value
end

---Switches from true to false, and false to true
---@return boolean
function BoolProperty:toggle()
	self:set(not self:get())
	return self:get()
end

---@class BoolProperty.HElement: CheckboxButton
local BooleanHElement = CheckboxButton:extend()

---@param rules Plan.Rules
---@param property BoolProperty
function BooleanHElement:new(rules, property)
	BooleanHElement.super.new(self, rules)
	self:bindToProperty(property)
end

function BoolProperty:getHElement()
	return BooleanHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(4))
		:addWidth(Plan.keep())
		:addHeight(Plan.max(8)),
		self
	)
end

---@class BoolProperty.VElement: CheckboxButton
local BooleanVElement = CheckboxButton:extend()

---@param rules Plan.Rules
---@param property BoolProperty
function BooleanVElement:new(rules, property)
	BooleanVElement.super.new(self, rules)
	self:bindToProperty(property)
end

function BoolProperty:getVElement()
	return BooleanVElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.pixel(28)),
		self
	)
end

function BoolProperty:__tostring()
	return "BoolProperty: "..tostring(self.value)
end

return BoolProperty
