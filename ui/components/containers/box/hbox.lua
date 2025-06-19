local GenBox = require "ui.components.containers.box.genbox"

---@class HBox: GenBox
local HBox = GenBox:extend()
HBox.CLASS_NAME = "HBox"
HBox._position = "x"
HBox._size = "w"

return HBox
