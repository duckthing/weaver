local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Resources = require "src.global.resources"
local ImporterTemplate = require "src.objects.importertemplate"
local IntegerProperty = require "src.properties.integer"
local Handler = require "src.global.handler"

-- Formats
local SpritePngFormat = require "plugins.sprite.formats.spritepng"

---@class ImportProject: ImporterTemplate
local ImportProject = ImporterTemplate:extend()

function ImportProject:new()
	ImportProject.super.new(self)

	self.path:addFilter("wgf")
	self.path:addFilter("png")

	---@type IntegerProperty
	self.rows= IntegerProperty(self, "Rows", 1)
	---@type IntegerProperty
	self.columns = IntegerProperty(self, "Columns", 1)

	self.rows:getRange()
		:setStep(1)
		:setMin(1)
end

local extensions = {
	"wproj"
}
function ImportProject:getSupportedExtensions()
	return extensions
end

function ImportProject:getProperties()
	return {
		self.path,
		self.rows,
		self.columns,
	}
end

---@type {[string]: Format}
local extensionToFormat = {
	["wproj"] = SpritePngFormat,
}

function ImportProject:import()
	local path = self.path:get() -- /path/to/sprite.png
	---@type string
	local extension = Path.ext(path) or "" -- png

	local info = nativefs.getInfo(path, "file")
	if info then
		local file = nativefs.newFile(path)
		local format = extensionToFormat[extension]
		if format then
			local success, resource = format:import(path, file, self)
			if success and resource then
				local id = Resources.addResource(resource)
				Resources.selectResourceId(id)
			else
				-- Error message
				print(resource)
			end
		else
			print(("No project importer found for %s"):format(extension))
		end
	end
	return true
end

return ImportProject
