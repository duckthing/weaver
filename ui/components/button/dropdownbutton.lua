local LabelButton = require "ui.components.button.labelbutton"
local Modal = require "src.global.modal"

---@class DropdownButton: LabelButton
local DropdownButton = LabelButton:extend()

local FORMAT_STRING = "%s: %s"

---@param rules Plan.Rules
---@param property EnumProperty?
function DropdownButton:new(rules, property)
	DropdownButton.super.new(self, rules, nil, (property and FORMAT_STRING:format(property.name, property.value.name) or "No Options"))
	---@type EnumProperty?
	self.property = nil
	self:bindToProperty(property)
end

function DropdownButton:onClick()
	if self.property then
		Modal.pushDropdown(self.x, self.y + self.h, self.property, self.w)
	end
end

function DropdownButton:wheelmoved(_, y)
	local property = self.property
	if not property then return end
	if y > 0 then
		self.property:set(property.options[(property.index % #property.options) + 1])
	elseif y < 0 then
		if property.index == 1 then
			self.property:set(property.options[#property.options])
		else
			self.property:set(property.options[property.index - 1])
		end
	end
end

---Binds this DropdownButton to an EnumProperty
---@param newProperty EnumProperty?
function DropdownButton:bindToProperty(newProperty)
	if self.property then
		-- Remove the old events
		self.property.valueChanged:removeAction(self._valueChangedAction)
		self._valueChangedAction = nil
	end

	self.property = newProperty

	if newProperty then
		-- Add the new events, if the new property exists
		self:setLabel(FORMAT_STRING:format(newProperty.name, newProperty.value.name))
		self._valueChangedAction = newProperty.valueChanged:addAction(function(property, newOption)
			self:setLabel(FORMAT_STRING:format(property.name, newOption.name))
		end)
	end
end

function DropdownButton:onRemovedFromParent()
	self:bindToProperty()
end

return DropdownButton
