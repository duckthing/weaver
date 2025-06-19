local GenFlex = require "ui.components.containers.flex.genflex"

---@alias VFlex.Justify
---| GenFlex.Justify

---@class VFlex: GenFlex
local VFlex = GenFlex:extend()
VFlex.CLASS_NAME = "VFlex"
VFlex._position = "y"
VFlex._size = "h"

function VFlex:getDesiredDimensions()
	return nil, self._requestedSize
end

return VFlex
