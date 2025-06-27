local Resource = require "src.data.resource"

---@class Project: Resource
local Project = Resource:extend()

function Project:new()
	Project.super.new(self)

	self.name:set("Project")
	---@type string # Local only; do not save
	self.root = ""
	---@type string # Default relative directory to make assets in
	self.assetDirectory = ""
end

return Project
