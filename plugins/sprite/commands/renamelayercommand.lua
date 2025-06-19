local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class RenameLayerCommand: SpriteCommand
local RenameLayerCommand = SpriteCommand:extend()
RenameLayerCommand.CLASS_NAME = "RenameLayerCommand"

---@param sprite Sprite
---@param layer Sprite.Layer
---@param newName string
function RenameLayerCommand:new(sprite, layer, newName)
	RenameLayerCommand.super.new(self, sprite)

	self.layer = layer
	self.oldName = layer.name:get()
	self.newName = newName
end

function RenameLayerCommand:undo()
	self.layer.name:set(self.oldName)
end

function RenameLayerCommand:perform()
	self.layer.name:set(self.newName)
end

function RenameLayerCommand:getPosition()
	return self.layer.index, nil
end

function RenameLayerCommand:release()
end

function RenameLayerCommand:hasChanges()
	return self.oldName ~= self.newName
end

return RenameLayerCommand
