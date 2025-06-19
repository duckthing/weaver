local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class InsertFrameCommand: SpriteCommand
local InsertFrameCommand = SpriteCommand:extend()
InsertFrameCommand.CLASS_NAME = "InsertFrameCommand"

---@param sprite Sprite
---@param shouldInsert boolean
---@param frame Sprite.Frame
function InsertFrameCommand:new(sprite, shouldInsert, frame)
	InsertFrameCommand.super.new(self, sprite)

	self.shouldInsert = shouldInsert
	self.frame = frame
	self.indices = {}

	local frameIndex = frame.index
	for i = 1, #sprite.layers do
		self.indices[i] = sprite.layers[i].celIndices[frameIndex]
	end
end

function InsertFrameCommand:undo()
	local sprite = self.sprite
	local frame = self.frame

	if not self.shouldInsert then
		local frameIndex = sprite:insertFrame(frame.index, frame)
		for i = 1, #self.indices do
			sprite.layers[i].celIndices[frameIndex] = self.indices[i]
		end
		sprite.celIndexEdited:trigger()
	else
		sprite:removeFrame(frame.index)
	end
end

function InsertFrameCommand:perform()
	self.shouldInsert = not self.shouldInsert
	self:undo()
	self.shouldInsert = not self.shouldInsert
end

function InsertFrameCommand:getPosition()
	return nil, math.min(#self.sprite.frames, self.frame.index)
end

function InsertFrameCommand:release()
end

function InsertFrameCommand:hasChanges()
	return true
end

return InsertFrameCommand
