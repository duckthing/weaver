local Resources = require "src.global.resources"
local SpriteResource = require "plugins.sprite.spriteresource"
local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"
local Palettes = require "src.global.palettes"

local IntegerProperty = require "src.properties.integer"
local EnumProperty = require "src.properties.enum"

---@class CreateSprite: Inspectable
local CreateSprite = Inspectable:extend()
CreateSprite.CLASS_NAME = "CreateSprite"
CreateSprite.OBJECT_NAME = "Sprite"

---@type SpriteEditor
local SpriteEditor = nil

---@type EnumProperty.Option[]
local presetOptions = {
	{
		name = "Simple",
		value = "simple",
	},
	{
		name = "Tilemap",
		value = "tilemap",
	},
}

---@type EnumProperty.Option[]
local tilemapOptions = {
	{
		name = "Custom",
		value = "custom",
	},
	{
		name = "4-way (sides)",
		value = "4-way",
	},
	{
		name = "8-way (sides and corners)",
		value = "8-way",
	},
}

function CreateSprite:new()
	CreateSprite.super.new(self)

	---@type EnumProperty
	self.preset = EnumProperty(self, "Preset", "simple")
	self.preset:setOptions(presetOptions)

	---@type EnumProperty
	self.tilemapType = EnumProperty(self, "Tilemap Type", "4-way")
	self.tilemapType:setOptions(tilemapOptions)

	---@type IntegerProperty
	self.width = IntegerProperty(self, "Width", 32)
	---@type IntegerProperty
	self.height = IntegerProperty(self, "Height", 32)

	---@type IntegerProperty
	self.tileWidth = IntegerProperty(self, "Tile Width", 32)
	---@type IntegerProperty
	self.tileHeight = IntegerProperty(self, "Tile Height", 32)

	---@type IntegerProperty
	self.tileRowCount = IntegerProperty(self, "# of rows", 1)
	---@type IntegerProperty
	self.tileColumnCount = IntegerProperty(self, "# of columns", 1)

	---@type BoolProperty
	-- self.indexed = BoolProperty(self, "Indexed", false)

	self.width:getRange()
		:setMin(1)

	self.height:getRange()
		:setMin(1)

	self.tileWidth:getRange()
		:setMin(1)

	self.tileHeight:getRange()
		:setMin(1)

	self.tileRowCount:getRange()
		:setMin(1)

	self.tileColumnCount:getRange()
		:setMin(1)

	self.preset.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
	end)

	self.tilemapType.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
	end)
end

function CreateSprite:getProperties()
	---@type Property[]
	local properties = {
		self.preset,
		-- self.indexed,
	}

	local preset = self.preset:getValue()
	local tilemapType = self.tilemapType:getValue()

	if preset == "simple" then
		properties[#properties+1] = self.width
		properties[#properties+1] = self.height
	elseif preset == "tilemap" then
		properties[#properties+1] = self.tilemapType
		properties[#properties+1] = self.tileWidth
		properties[#properties+1] = self.tileHeight

		if tilemapType == "custom" then
			properties[#properties+1] = self.tileRowCount
			properties[#properties+1] = self.tileColumnCount
		end
	end

	return properties
end

---@type Action[]
local actions = {
	Action(
		"Create",
		---@param action Action
		---@param self CreateSprite
		---@param ... unknown
		---@return boolean
		function (action, self, ...)
			local preset, tilemapType =
				self.preset:getValue(),
				self.tilemapType:getValue()

			local rows, columns = 1, 1
			local tileWidth, tileHeight =
				self.tileWidth:get(),
				self.tileHeight:get()

			if preset == "tilemap" then
				if tilemapType == "4-way" then
					rows, columns = 4, 4
				elseif tilemapType == "8-way" then
					rows, columns = 4, 12
				elseif tilemapType == "custom" then
					rows, columns =
						self.tileRowCount:get(),
						self.tileColumnCount:get()
				end

				self.width:set(tileWidth * columns)
				self.height:set(tileHeight * rows)
			end

			local width, height =
				self.width:get(),
				self.height:get()

			-- Find the default palette
			local paletteName = SpriteEditor.defaultPalette:get()

			---@type Palette
			local palette
			if paletteName ~= "" then
				for _, p in ipairs(Palettes.globalPalettes) do
					if p.name == paletteName then
						palette = p:clone()
					end
				end
			end
			if not palette then
				palette = Palettes.globalPalettes[love.math.random(1, #Palettes.globalPalettes)]:clone()
			end

			-- Create and select the new sprite
			---@type Sprite
			local resource = SpriteResource(width, height, nil, palette)
			local id = Resources.addResource(resource)

			-- Set the grid options from the preset
			if preset == "tilemap" then
				local gridOptions = resource.spriteState.gridOptions

				gridOptions.showGrid:set(true)
				gridOptions.gridW:set(tileWidth)
				gridOptions.gridH:set(tileHeight)
			end

			Resources.selectResourceId(id)
			return true
		end
	):setType("accept")
}

function CreateSprite:getActions()
	return actions
end

---Adds the SpriteEditor for referencing
---@param editor SpriteEditor
function CreateSprite.addSpriteEditor(editor)
	SpriteEditor = editor
end

return CreateSprite
