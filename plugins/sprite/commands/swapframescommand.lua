local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class SwapFramesCommand: SpriteCommand
local SwapFramesCommand = SpriteCommand:extend()
SwapFramesCommand.CLASS_NAME = "SwapFramesCommand"

---@param sprite Sprite
---@param frame1 Sprite.Frame
---@param frame2 Sprite.Frame
function SwapFramesCommand:new(sprite, frame1, frame2)
	SwapFramesCommand.super.new(self, sprite)

	self.frame1, self.frame2 = frame1, frame2
end

function SwapFramesCommand:undo()
	self.sprite:swapFrames(self.frame1.index, self.frame2.index)
end

function SwapFramesCommand:perform()
	self:undo()
end

function SwapFramesCommand:getPosition()
	return nil, math.min(#self.sprite.frames, self.frame1.index)
end

function SwapFramesCommand:release()
end

function SwapFramesCommand:hasChanges()
	return true
end

return SwapFramesCommand
