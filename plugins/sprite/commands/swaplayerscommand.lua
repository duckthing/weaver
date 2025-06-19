local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class SwapLayersCommand: SpriteCommand
local SwapLayersCommand = SpriteCommand:extend()
SwapLayersCommand.CLASS_NAME = "SwapLayersCommand"

---@param sprite Sprite
---@param layer1 Sprite.Layer
---@param layer2 Sprite.Layer
function SwapLayersCommand:new(sprite, layer1, layer2)
	SwapLayersCommand.super.new(self, sprite)

	self.layer1, self.layer2 = layer1, layer2
end

function SwapLayersCommand:undo()
	self.sprite:swapLayers(self.layer1.index, self.layer2.index)
end

function SwapLayersCommand:perform()
	self:undo()
end

function SwapLayersCommand:getPosition()
	return math.min(#self.sprite.layers, self.layer1.index), nil
end

function SwapLayersCommand:release()
end

function SwapLayersCommand:hasChanges()
	return true
end

return SwapLayersCommand
