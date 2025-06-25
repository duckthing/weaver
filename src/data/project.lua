local Object = require "lib.classic"

---@class Project: Object
local Project = Object:extend()

function Project:new()
	---@type string
	self.name = "Project"
	---@type string # Local only; do not save
	self.root = ""
	---@type string # Default relative directory to make assets in
	self.assetDirectory = ""
end

return Project
