local Property = require "src.properties.property"

---@class ColorProperty: Property
local ColorProperty = Property:extend()

---@param object Inspectable
---@param name string
---@param value Palette.Color
function ColorProperty:new(object, name, value)
	ColorProperty.super.new(self, object, name, value)
end

return ColorProperty
