local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class SetDurationCommand: SpriteCommand
local SetDurationCommand = SpriteCommand:extend()
SetDurationCommand.CLASS_NAME = "SetDurationCommand"

---@param sprite Sprite
---@param frame Sprite.Frame
---@param newDuration number
function SetDurationCommand:new(sprite, frame, newDuration)
	SetDurationCommand.super.new(self, sprite)

	self.frame = frame
	self.oldDuration = frame.duration:get()
	self.newDuration = newDuration
end

function SetDurationCommand:undo()
	self.frame.duration:set(self.oldDuration)
end

function SetDurationCommand:perform()
	self.frame.duration:set(self.newDuration)
end

function SetDurationCommand:getPosition()
	return nil, self.frame.index
end

function SetDurationCommand:release()
end

function SetDurationCommand:hasChanges()
	return true
end

return SetDurationCommand
