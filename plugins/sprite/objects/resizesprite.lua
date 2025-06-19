local Inspectable = require "src.properties.inspectable"
local IntegerProperty = require "src.properties.integer"
local Action = require "src.data.action"

---@class ResizeSprite: Inspectable
local ResizeSprite = Inspectable:extend()

---@param sprite Sprite
function ResizeSprite:new(sprite)
	ResizeSprite.super.new(self)

	---@type IntegerProperty
	self.width = IntegerProperty(self, "Width", sprite.width)
	---@type IntegerProperty
	self.height = IntegerProperty(self, "Height", sprite.height)
	---@type IntegerProperty
	self.offsetX = IntegerProperty(self, "Offset X", 0)
	---@type IntegerProperty
	self.offsetY = IntegerProperty(self, "Offset Y", 0)
	---@type Sprite
	self.sprite = sprite

	self.width:getRange()
		:setMin(1)

	self.height:getRange()
		:setMin(1)
end

function ResizeSprite:getProperties()
	return {
		self.width,
		self.height,
		self.offsetX,
		self.offsetY,
	}
end

---@type Action[]
local actions = {
	Action(
		"Resize",
		function (action, resizeSprite)
			---@cast resizeSprite ResizeSprite
			local width, height, offsetX, offsetY =
				resizeSprite.width:get(),
				resizeSprite.height:get(),
				resizeSprite.offsetX:get(),
				resizeSprite.offsetY:get()

			resizeSprite.sprite:resize(width, height, offsetX, offsetY)
			return true
		end
	):setType("accept")
}

function ResizeSprite:getActions()
	return actions
end

return ResizeSprite
