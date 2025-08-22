local nativefs = require "lib.nativefs"
local Resources = require "src.global.resources"
local ImporterTemplate = require "src.objects.importertemplate"
local FilePathProperty = require "src.properties.filepath"

---@class ImportWgf: ImporterTemplate
local ImportWgf = ImporterTemplate:extend()

-- This is mostly unused
-- It's here so that OpenFileObject detects WGF, so it's basically dead code
-- TODO: Trim

function ImportWgf:new()
	ImportWgf.super.new(self)

	---@type FilePathProperty
	-- self.path = FilePathProperty(self, "Path", love.filesystem.getUserDirectory().."Desktop/sprite.wgf")
	-- self.path:addFilter("wgf")
end

function ImportWgf:getProperties()
	return {
		self.path,
	}
end

local extensions = {"wgf"}
function ImportWgf:getSupportedExtensions() return extensions end

function ImportWgf:import()
	-- Handler should do it
	return true
end

return ImportWgf
