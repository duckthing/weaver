local Command = require "src.data.command"

---@class CommandGroup: Command
local CommandGroup = Command:extend()

function CommandGroup:new()
	CommandGroup.super.new(self)

	---@type Command[]
	self.commands = {}
end

---Adds a Command to this group.
---@param command Command
function CommandGroup:add(command)
	self.commands[#self.commands+1] = command
end

function CommandGroup:perform()
	for i = 1, #self.commands do
		self.commands[i]:perform()
	end
end

function CommandGroup:undo()
	for i = #self.commands, 1, -1 do
		self.commands[i]:undo()
	end
end

function CommandGroup:release()
	for i = #self.commands, 1, -1 do
		self.commands[i]:release()
	end
	self.commands = nil
end

function CommandGroup:focus()
	for i = 1, #self.commands do
		self.commands[i]:focus()
	end
end

function CommandGroup:hasChanges()
	for i = 1, #self.commands do
		if self.commands[i]:hasChanges() then
			return true
		end
	end
	return false
end

function CommandGroup:__tostring()
	local string = "CommandGroup ==\n"

	for _, command in ipairs(self.commands) do
		string = ("%s=%s\n"):format(string, tostring(command))
	end

	return string.."==============="
end

return CommandGroup
