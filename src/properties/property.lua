local Plan = require "lib.plan"
local Object = require "lib.classic"
local Luvent = require "lib.luvent"

---@class Property: Object
local Property = Object:extend()
Property.type = "none"

---Creates a new Property object
---@param object Inspectable
---@param name string
---@param value any?
function Property:new(object, name, value)
	if object == nil then error("No Inspectable was passed to Property") end
	---@type Inspectable
	self.object = object
	---@type string
	self.name = name
	---@type any?
	self.value = value

	---@type Luvent
	self.valueChanged = Luvent.newEvent()
end

---Returns the property
---@return any?
function Property:get()
	return self.value
end

---Sets the value of the property
---@param value any
function Property:set(value)
	if self.value ~= value then
		self.value = value
		self.valueChanged:trigger(self, value)
	end
end

---Returns any data in a format that can be saved
---@return any
function Property:serialize()
	return self.value
end

---Sets the value from a deserialized value
---@param data any
function Property:deserialize(data)
	self:set(data)
end

---Removes all events tied to this Property
function Property:destroy()
	self.valueChanged:removeAllActions()
end

local DefaultHElement = Plan.Container:extend()
function DefaultHElement:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("...", self.x, self.y)
end

---Creates the UI element for displaying to the user.
---
---This one is for horizontal sorting
---@return Plan.Container
function Property:getHElement()
	return DefaultHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(0))
		:addWidth(Plan.pixel(30))
		:addHeight(Plan.parent())
	)
end

---Creates the UI element for displaying to the user.
---
---This one is for vertical sorting
---@return Plan.Container
function Property:getVElement()
	return DefaultHElement(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.pixel(30))
	)
end

function Property:__tostring()
	return ("%s: "):format(self.type)..tostring(self.value)
end

return Property
