local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"
local FilePathProperty = require "src.properties.filepath"
local Modal = require "src.global.modal"

---@class ImporterTemplate: Inspectable
local ImporterTemplate = Inspectable:extend()

function ImporterTemplate:new()
	ImporterTemplate.super.new(self)
	---@type FilePathProperty
	self.path = FilePathProperty(self, "Path", love.filesystem.getUserDirectory().."Desktop/")
	self.path:setPathMode("read")
end

function ImporterTemplate:import()
end

---This function is called when the global open file dialog is closed
function ImporterTemplate:onPathSet()
	Modal.pushInspector(self)
end

---Returns an array of supported file extensions (such as ".wgf", ".png")
---@return string[]?
function ImporterTemplate:getSupportedExtensions()
	return nil
end

---@type Action[]
local actions = {
	Action(
		"Import",
		function (action, importer)
			---@cast importer ImporterTemplate
			importer:import()
			return true
		end
	):setType("accept"),
}

function ImporterTemplate:getActions()
	return actions
end

return ImporterTemplate
