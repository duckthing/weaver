local Plan = require "lib.plan"
local Property = require "src.properties.property"
local Label = require "ui.components.text.label"

---@class LabelProperty: Property
local LabelProperty = Property:extend()

function LabelProperty:new(...)
	LabelProperty.super.new(self, ...)
	self.type = "label"
end

---Returns the value
---@return integer
function LabelProperty:get()
	return self.value
end

---Sets the value of the property
---@param value integer
function LabelProperty:set(value)
	if self.value ~= value then
		self.value = value
		self.valueChanged:trigger(value)
	end
end

function LabelProperty:serialize()
	return nil
end

---@class LabelProperty.HElement: Plan.Container
local LabelHElement = Plan.Container:extend()

---@type Plan.Rules
local FULL_SPACE = Plan.RuleFactory.full()
---@param rules Plan.Rules
---@param property Property
function LabelHElement:new(rules, property)
	LabelHElement.super.new(self, rules)
	self.property = property
	---@type Label
	self.label = Label(FULL_SPACE, tostring(property.value))
	self.w, _ = self.label:getTextBounds()
	self:addChild(self.label)

	self.valueChangedAction = property.valueChanged:addAction(function(newText)
		self.label:setText(newText)
		local newW, _ = self.label:getTextBounds()
		if self.w ~= newW then
			self.w = newW
			self:bubble("_bubbleSizeChanged")
		end
	end)
end

function LabelHElement:getDesiredDimensions()
	return self.label:getDesiredDimensions()
end

function LabelProperty:getHElement()
	return LabelHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(0))
		:addWidth(Plan.content())
		:addHeight(Plan.parent()),
		self
	)
end


---@class LabelProperty.VElement: Plan.Container
local LabelVElement = Plan.Container:extend()

---@param rules Plan.Rules
---@param property Property
function LabelVElement:new(rules, property)
	LabelVElement.super.new(self, rules)
	self.property = property
	---@type Label
	self.label = Label(FULL_SPACE, tostring(property.value))
	self.label:setAlign("left")
	self.label:setJustify("top")
	self.label:setWrapLimit(1000000)
	self:addChild(self.label)

	self.valueChangedAction = property.valueChanged:addAction(function(newText)
		self.label:setText(newText)
	end)
end

function LabelVElement:getDesiredDimensions()
	return self.label:getDesiredDimensions()
end

function LabelVElement:refresh()
	LabelVElement.super.refresh(self)
	_, self.h = self:getDesiredDimensions()
end

function LabelProperty:getVElement()
	return LabelVElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.content()),
		self
	)
end

return LabelProperty
