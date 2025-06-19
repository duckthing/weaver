local Resource = require "src.data.resource"

---@class SettingsResource: Resource
local SettingsBuffer = Resource:extend()
SettingsBuffer.TYPE = "settings"

function SettingsBuffer:new()
	SettingsBuffer.super.new(self)
	self.name:set("Settings")
end

return SettingsBuffer
