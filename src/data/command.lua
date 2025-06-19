local Object = require "lib.classic"

---@class Command: Object
local Command = Object:extend()
Command.CLASS_NAME = "Command"
---@type boolean # If we are undoing, should we keep undoing after this?
Command.transientUndo = false
---@type boolean # If we are redoing, should we keep redoing after this?
Command.transientRedo = false

function Command:new()
	Command.super.new(self)
end

function Command:undo()
end

function Command:perform()
end

function Command:release()
end

---Returns true if this Command has made changes
---@return boolean
function Command:hasChanges()
	return true
end

---"Focuses" on the relevant part. For a SpriteCommand, it sets the layer and frame this Command corresponds to.
function Command:focus()
end

function Command:__tostring()
	return self.CLASS_NAME
end

return Command
