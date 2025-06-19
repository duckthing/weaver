local NumberProperty = require "src.properties.number"

---@class IntegerProperty: NumberProperty
local IntegerProperty = NumberProperty:extend()

function IntegerProperty:new(object, name, value)
	IntegerProperty.super.new(self, object, name, value)
	self.type = "integer"
	self.range:setStep(1)
end

---Returns the value
---@return integer
function IntegerProperty:get()
	return self.value
end

---Sets the value of the property
---@param value integer
function IntegerProperty:set(value)
	-- The event is triggered in here
	self.range:setValue(value)
end

---Returns the Range object
---@return Range
function IntegerProperty:getRange()
	return self.range
end

return IntegerProperty
