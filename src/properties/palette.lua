local Property = require "src.properties.property"

---@class PaletteProperty: Property
local PaletteProperty = Property:extend()

---@return Palette?
function PaletteProperty:get()
	return self.value
end

return PaletteProperty
