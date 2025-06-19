local Object = require "lib.classic"

---@class Project: Object
local Project = Object:extend()

---@class Project.Item: Object
local Item = Object:extend()

function Project:new()
	---@type string
	self.name = "Project"
	---@type Project.Item[]
	self.items = {}
	---@type string
	self.root = ""
end

return Project
