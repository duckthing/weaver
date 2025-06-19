local Inspectable = require "src.properties.inspectable"
local StringProperty = require "src.properties.string"

---@class Sprite.Animation: Inspectable
local Animation = Inspectable:extend()

---@param sprite Sprite
function Animation:new(sprite)
	Animation.super.new(self)

	self.sprite = sprite
	---@type StringProperty
	self.name = StringProperty(self, "Name", "New Animation")
end

return Animation
