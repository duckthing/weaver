local Path = require "lib.path"
local Resources = require "src.global.resources"
local nativefs = require "lib.nativefs"
local ExporterTemplate = require "src.objects.exportertemplate"
local IntegerProperty = require "src.properties.integer"
local FilePathProperty = require "src.properties.filepath"
local LabelProperty = require "src.properties.label"
local BoolProperty = require "src.properties.bool"
local PngFormat = require "plugins.sprite.formats.spritepng"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local State = require "src.global.state"

---@class ExportSprite: ExporterTemplate
local ExportSprite = ExporterTemplate:extend()

---@type SpriteEditor
local SpriteEditor = nil

---@param sprite Sprite
function ExportSprite:new(sprite)
	ExportSprite.super.new(self)

	---@type BoolProperty
	self.exportImage = BoolProperty(self, "Export Image?", true)
	---@type IntegerProperty
	self.scale = IntegerProperty(self, "Scale", 1)
	self.scale:getRange()
		:setMin(1)
	---@type IntegerProperty
	self.rows = IntegerProperty(self, "Rows", 1)
	---@type FilePathProperty
	self.imagePath = FilePathProperty(self, "Image Path", State.getAssetDirectory()..sprite.name:get())
	self.imagePath:setPathMode("write")
	self.imagePath:addFilter("png")

	---@type BoolProperty
	self.exportData = BoolProperty(self, "Export Data?", false)
	---@type FilePathProperty
	self.dataPath = FilePathProperty(self, "Data Path", State.getAssetDirectory()..sprite.name:get())
	self.dataPath:setPathMode("write")
	self.dataPath:addFilter(SpriteEditor.defaultDataExtension:getValue(), true)
	self.dataPath:addFilter("lua")
	self.dataPath:addFilter("json")

	self.scale:getRange()
		:setMin(1)
		:setStep(1)

	sprite.name.valueChanged:addAction(function(property, newName)
		-- Remove the extension, if it's there
		newName, _ = Path.nameext(newName)
		self.imagePath:set(self.imagePath:getParentDirectory()..newName.."."..self.imagePath:getExtension())
		self.dataPath:set(self.dataPath:getParentDirectory()..newName.."."..self.dataPath:getExtension())
	end)

	self.imagePath.valueChanged:addAction(function()
		self.dataPath:set(self.imagePath:getParentDirectory()..self.imagePath:getItemName().."."..self.dataPath:getExtension())
	end)
	self.exportImage.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
	end)
	self.exportData.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
	end)
end

function ExportSprite:export()
	ExportSprite.super.export(self)

	local scale = self.scale:get()
	local rows = self.rows:get()

	local pathInfo = nativefs.getInfo(self.imagePath:getParentDirectory(), "directory")
	local dataPathInfo = self.exportData:get() and nativefs.getInfo(self.dataPath:getParentDirectory(), "directory")
	if pathInfo or (self.exportData:get() and dataPathInfo) then
		---@type Sprite
		local sprite = Resources.getCurrentResource()
		SpriteTool.applyFromSelection()
		---@diagnostic disable-next-line
		PngFormat:export(sprite, {
			scale = scale,
			rows = rows,
			imagePath = self.exportImage:get() and self.imagePath:get(),
			dataPath = self.exportData:get() and self.dataPath:get()
		})
	else
		print("Invalid directory (might not exist)")
	end
end

ExportSprite.separator = LabelProperty(ExportSprite, "", "\n")
function ExportSprite:getProperties()
	---@type Property[]
	local properties = {
		self.exportImage,
	}

	if self.exportImage:get() then
		-- properties[#properties+1] = self.scale
		properties[#properties+1] = self.imagePath
		properties[#properties+1] = self.rows
		properties[#properties+1] = self.scale
	end

	properties[#properties+1] = ExportSprite.separator
	properties[#properties+1] = self.exportData
	if self.exportData:get() then
		properties[#properties+1] = self.dataPath
	end

	return properties
end

---@param editor SpriteEditor
function ExportSprite.addSpriteEditor(editor)
	SpriteEditor = editor
end

return ExportSprite
