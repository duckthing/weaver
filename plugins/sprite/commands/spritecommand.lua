local Command = require "src.data.command"

---@class SpriteCommand: Command
local SpriteCommand = Command:extend()
SpriteCommand.CLASS_NAME = "SpriteCommand"

---@param sprite Sprite
function SpriteCommand:new(sprite)
	SpriteCommand.super.new(self)
	---@type Sprite
	self.sprite = sprite
end

---Returns the layer and frame position this command is relevant in. If nil, it doesn't apply.
---@return integer? layerIndex
---@return integer? frameIndex
function SpriteCommand:getPosition()
	return nil, nil
end

function SpriteCommand:focus()
	if self.sprite then
		local state = self.sprite.spriteState
		local relevantLayer, relevantFrame = self:getPosition()
		if relevantLayer then
			state.layer:set(relevantLayer)
		end
		if relevantFrame then
			state.frame:set(relevantFrame)
		end
	end
end

return SpriteCommand
