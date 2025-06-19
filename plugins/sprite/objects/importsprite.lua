local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Resources = require "src.global.resources"
local ImporterTemplate = require "src.objects.importertemplate"
local IntegerProperty = require "src.properties.integer"
local Handler = require "src.global.handler"

-- Formats
local SpritePngFormat = require "plugins.sprite.formats.spritepng"

---@class ImportSprite: ImporterTemplate
local ImportSprite = ImporterTemplate:extend()

function ImportSprite:new()
	ImportSprite.super.new(self)

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
	"wgf",
	"png",
}
function ImportSprite:getSupportedExtensions()
	return extensions
end

function ImportSprite:getProperties()
	return {
		self.path,
		self.rows,
		self.columns,
	}
end

---@type {[string]: Format}
local extensionToFormat = {
	["png"] = SpritePngFormat,
}

function ImportSprite:import()
	local path = self.path:get() -- /path/to/sprite.png
	---@type string
	local extension = Path.ext(path) or "" -- png
	if extension == "wgf" then return Handler.importAndHandle(path) end

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
			print(("No sprite importer found for %s"):format(extension))
		end
	end
	return true
end

return ImportSprite
