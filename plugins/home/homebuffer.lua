local Resource = require "src.data.resource"

---@class HomeResource: Resource
local HomeResource = Resource:extend()
HomeResource.TYPE = "home"

function HomeResource:new()
	HomeResource.super.new(self)
	self.name:set("Home")
end

return HomeResource
