local Plan = require "lib.plan"
local Property = require "src.properties.property"
local LabelButton = require "ui.components.button.labelbutton"
local Modal = require "src.global.modal"
local DropdownButton = require "ui.components.button.dropdownbutton"

---@class EnumProperty: Property
local EnumProperty = Property:extend()

---@class EnumProperty.Option
---@field value any
---@field name string

function EnumProperty:new(object, name, defaultValue)
	EnumProperty.super.new(self, object, name, nil)
	self.type = "enum"
	---@type EnumProperty.Option[]
	self.options = {}
	---@type EnumProperty.Option
	self.value = nil
	---@type EnumProperty.Option | any
	self._defaultValue = defaultValue
	---@type integer
	self.index = 0
end

---Sets the options for this EnumProperty
---@param options EnumProperty.Option[]
function EnumProperty:setOptions(options)
	self.options = options
	local currentValue = self.value or self._defaultValue

	for _, option in ipairs(options) do
		-- Don't reset the value if it is a valid option
		-- ...or reset it to this option if the default value is the requested value
		if option == currentValue or option.value == currentValue then
			self:set(option)
			return
		end
	end

	-- Not a valid option, reset to first one
	self:set(options[1])
end

---Sets the EnumProperty.Option of this EnumProperty
---@param option EnumProperty.Option
function EnumProperty:set(option)
	if self.value == option then return end

	for i = 1, #self.options do
		if self.options[i] == option then
			self.value = option
			self.index = i
			self.valueChanged:trigger(self, option)
			return
		end
	end
end

---Sets the VALUE of this EnumProperty, which will search each option's value
---@param value any
function EnumProperty:setValue(value)
	if self.value == value then return end

	for i = 1, #self.options do
		local option = self.options[i]
		if self.options[i].value == value then
			self.value = option
			self.index = i
			self.valueChanged:trigger(self, value)
			return
		end
	end
end

---Returns the _Option_
---@return EnumProperty.Option
function EnumProperty:get()
	return self.value
end

---Returns the value of the current Option
---@return any
function EnumProperty:getValue()
	return self.value.value
end

function EnumProperty:getHElement()
	return DropdownButton(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(4))
		:addWidth(Plan.keep())
		:addHeight(Plan.max(8)),
		self
	)
end

function EnumProperty:__tostring()
	return "EnumProperty: "..tostring(self.value)
end

return EnumProperty
