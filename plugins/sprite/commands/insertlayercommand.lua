local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class InsertLayerCommand: SpriteCommand
local InsertLayerCommand = SpriteCommand:extend()
InsertLayerCommand.CLASS_NAME = "InsertLayerCommand"

---@param sprite Sprite
---@param shouldInsert boolean
---@param layer Sprite.Layer
function InsertLayerCommand:new(sprite, shouldInsert, layer)
	InsertLayerCommand.super.new(self, sprite)

	self.shouldInsert = shouldInsert
	self.layer = layer
end

function InsertLayerCommand:undo()
	local sprite = self.sprite
	local layer = self.layer

	if not self.shouldInsert then
		sprite:insertLayer(layer.index, layer)
	else
		sprite:removeLayer(layer.index)
	end
end

function InsertLayerCommand:perform()
	self.shouldInsert = not self.shouldInsert
	self:undo()
	self.shouldInsert = not self.shouldInsert
end

function InsertLayerCommand:getPosition()
	return math.min(#self.sprite.layers, self.layer.index), nil
end

function InsertLayerCommand:release()
end

function InsertLayerCommand:hasChanges()
	return true
end

return InsertLayerCommand
