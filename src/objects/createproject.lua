local nativefs = require "lib.nativefs"
local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"
local Project = require "src.data.project"
local Status = require "src.global.status"

local IntegerProperty = require "src.properties.integer"
local StringProperty = require "src.properties.string"
local FilePathProperty = require "src.properties.filepath"

---@class CreateProject: Inspectable
local CreateProject = Inspectable:extend()
CreateProject.CLASS_NAME = "CreateProject"

function CreateProject:new()
	CreateProject.super.new(self)

	---@type FilePathProperty
	self.path = FilePathProperty(self, "Project Folder", love.filesystem.getUserDirectory())
	self.path:setPathMode("directory")

	---@type StringProperty
	self.name = StringProperty(self, "Project Name", "Project")
end

function CreateProject:getProperties()
	return {
		self.path,
		self.name,
	}
end

---@type Action[]
local actions = {
	Action(
		"Create",
		function (action, createProject)
			---@cast createProject CreateProject
			local path = createProject.path:get()
			local name = createProject.name:get()

			---@cast nativefs love.filesystem
			local info = nativefs.getInfo(path)
			if info and info.type ~= "directory" then
				Status.pushTemporaryMessage("Path is not a directory; it is a file", "error", 5)
				return false
			end

			-- Try to create the folder if it doesn't exist
			if not info then
				local created = nativefs.createDirectory(path)
				if not created then
					Status.pushTemporaryMessage("Could not create folder", "error", 5)
					return false
				end
			end

			---@type Project
			local project = Project()
			project.name = name
			project.root = path
			return true
		end
	):setType("accept")
}

function CreateProject:getActions()
	return actions
end

---Adds the SpriteEditor for referencing
---@param editor SpriteEditor
function CreateProject.addSpriteEditor(editor)
	SpriteEditor = editor
end

return CreateProject
