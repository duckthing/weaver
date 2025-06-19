local GenBox = require "ui.components.containers.box.genbox"

---@class VBox: GenBox
local VBox = GenBox:extend()
VBox.CLASS_NAME = "VBox"
VBox._position = "y"
VBox._size = "h"

return VBox
