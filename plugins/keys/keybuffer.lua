local Resource = require "src.data.resource"

---@class KeyResource: Resource
local KeyBuffer = Resource:extend()
KeyBuffer.TYPE = "key"

function KeyBuffer:new()
	KeyBuffer.super.new(self)
	self.name:set("Keybinds")
end

return KeyBuffer
