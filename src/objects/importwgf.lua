local nativefs = require "lib.nativefs"
local Resources = require "src.global.resources"
local ImporterTemplate = require "src.objects.importertemplate"
local FilePathProperty = require "src.properties.filepath"

-- Formats
local WgfFormat = require "src.formats.wgf"

---@class ImportWgf: ImporterTemplate
local ImportWgf = ImporterTemplate:extend()

function ImportWgf:new()
	ImportWgf.super.new(self)

	---@type FilePathProperty
	self.path = FilePathProperty(self, "Path", love.filesystem.getUserDirectory().."Desktop/sprite.wgf")
	self.path:addFilter(".wgf")
end

function ImportWgf:getProperties()
	return {
		self.path,
	}
end

function ImportWgf:import()
	local path = self.path:get() -- /path/to/file.wgf
	---@type string
	local extension = path:match("^.+(%..+)$") -- .wgf
	if extension ~= ".wgf" then return false end

	local info = nativefs.getInfo(path, "file")
	if info then
		local file = nativefs.newFile(path)
		local success, resource = WgfFormat:import(path, file)
		if success and resource then
			---@cast resource Resource
			local id = Resources.addResource(resource)
			Resources.selectResourceId(id)
		else
			-- Error message
			print(resource)
		end
	end
	return true
end

return ImportWgf
