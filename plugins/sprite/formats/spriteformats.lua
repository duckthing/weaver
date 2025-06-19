local Format = require "src.data.format"
local Modal = require "src.global.modal"
local ImportSprite = require "plugins.sprite.objects.importsprite"
local ExportSprite = require "plugins.sprite.objects.exportsprite"
local SpriteBuffer = require "plugins.sprite.spriteresource"

---@class SpriteFormats: Format
local SpriteFormats = Format:extend()
SpriteFormats.FORMAT_NAME = "SpriteFormats"
SpriteFormats.IMPORT_EXTENSIONS = ImportSprite:getSupportedExtensions()
SpriteFormats.EXPORT_FOR_TYPES = {SpriteBuffer}

function SpriteFormats:handleImport(path)
	---@type ImportSprite
	local importer = ImportSprite()
	importer.path:set(path)
	Modal.pushInspector(importer)
	return true
end

return SpriteFormats
