local GenFlex = require "ui.components.containers.flex.genflex"

---@alias HFlex.Justify
---| GenFlex.Justify

---@class HFlex: GenFlex
local HFlex = GenFlex:extend()
HFlex.CLASS_NAME = "HFlex"
HFlex._position = "x"
HFlex._size = "w"

function HFlex:getDesiredDimensions()
	return self._requestedSize, nil
end

return HFlex
