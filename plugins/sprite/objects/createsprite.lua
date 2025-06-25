local Resources = require "src.global.resources"
local SpriteResource = require "plugins.sprite.spriteresource"
local Inspectable = require "src.properties.inspectable"
local IntegerProperty = require "src.properties.integer"
local Action = require "src.data.action"
local Palettes = require "src.global.palettes"

---@class CreateSprite: Inspectable
local CreateSprite = Inspectable:extend()
CreateSprite.CLASS_NAME = "CreateSprite"

---@type SpriteEditor
local SpriteEditor = nil

function CreateSprite:new()
	CreateSprite.super.new(self)

	---@type IntegerProperty
	self.width = IntegerProperty(self, "Width", 32)
	---@type IntegerProperty
	self.height = IntegerProperty(self, "Height", 32)
	---@type BoolProperty
	-- self.indexed = BoolProperty(self, "Indexed", false)

	self.width:getRange()
		:setStep(1)
		:setMin(1)

	self.height:getRange()
		:setStep(1)
		:setMin(1)
end

function CreateSprite:getProperties()
	return {
		self.width,
		self.height,
		-- self.indexed,
	}
end

---@type Action[]
local actions = {
	Action(
		"Create",
		function (action, createSprite, ...)
			---@cast createSprite CreateSprite
			local width, height =
				createSprite.width:get(),
				createSprite.height:get()

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

			local resource = SpriteResource(width, height, nil, palette)
			local id = Resources.addResource(resource)
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
