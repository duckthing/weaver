local Resources = require "src.global.resources"
local SpriteResource = require "plugins.sprite.spriteresource"
local Inspectable = require "src.properties.inspectable"
local IntegerProperty = require "src.properties.integer"
local Action = require "src.data.action"

---@class CreateSprite: Inspectable
local CreateSprite = Inspectable:extend()

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
		function (action, createSprite)
			---@cast createSprite CreateSprite
			local width, height =
				createSprite.width:get(),
				createSprite.height:get()
			local resource = SpriteResource(width, height)
			local id = Resources.addResource(resource)
			Resources.selectResourceId(id)
			return true
		end
	):setType("accept")
}

function CreateSprite:getActions()
	return actions
end

return CreateSprite
