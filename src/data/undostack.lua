local Object = require "lib.classic"
local Status = require "src.global.status"
local Luvent = require "lib.luvent"
local CommandGroup = require "src.data.commandgroup"

---@class UndoStack: Object
local UndoStack = Object:extend()

function UndoStack:new()
	UndoStack.super.new(self)
	---@type Command[]
	self.stack = {}
	---@type integer
	self.maxSize = 30
	---@type integer
	self.index = 0
	---@type integer # How many commands have been released at the start due to being over the max size. Useful for seeing if there has been changes to a buffer.
	self.totalShifted = 0
	---@type boolean # True if we're mid-step, and shouldn't commit to the history
	self.midStep = false

	self.indexChanged = Luvent.newEvent()

	---@type CommandGroup[]
	self.groups = {}
end

---Creates a CommandGroup, where Commands are added to.
function UndoStack:pushGroup()
	self.groups[#self.groups+1] = CommandGroup()
end

---Pops a CommandGroup
function UndoStack:popGroup()
	local group = self.groups[#self.groups]
	self.groups[#self.groups] = nil
	self:commitWithoutPerforming(group)
end

---Returns the current CommandGroup, or nil if it doesn't exist
---@return CommandGroup?
function UndoStack:getCurrentGroup()
	return self.groups[#self.groups]
end

---Performs one undo step
function UndoStack:undo()
	local index = self.index
	if index < 1 then
		-- No more undo commands
		Status.pushTemporaryMessage("No more undo commands", nil, 3)
		return
	end
	if #self.groups > 0 then
		-- In the middle of a command group
		Status.pushTemporaryMessage("Complete your current action first", nil, 3)
		return
	end

	-- Can undo
	self.midStep = true
	local command = self.stack[index]
	command:undo()
	-- command:focus()
	if self.stack[index - 1] then
		self.stack[index - 1]:focus()
	end
	-- print("UNDO", command)
	self.index = index - 1
	self.indexChanged:trigger(self.index)
	self.midStep = false
	if command.transientUndo then
		self:undo()
	end
end

---Performs one redo step
function UndoStack:redo()
	local index, stack = self.index, self.stack
	local stackSize = #stack
	if index >= stackSize or stackSize <= 0 then
		-- At the end of the command stack
		Status.pushTemporaryMessage("No more redo commands", nil, 3)
		return
	end
	if #self.groups > 0 then
		-- In the middle of a command group
		Status.pushTemporaryMessage("Complete your current action first", nil, 3)
		return
	end

	-- Can redo
	self.midStep = true
	local command = stack[index + 1]
	command:perform()
	command:focus()
	-- print("REDO", command)
	self.index = index + 1
	self.indexChanged:trigger(self.index)
	self.midStep = false
	if command.transientRedo then
		self:redo()
	end
end

---Adds a Command to the UndoStack without performing it
---@param command Command
---@return boolean success
function UndoStack:commitWithoutPerforming(command)
	if not command:hasChanges() then return false end

	---@type Command[]
	local stack
	local inGroup = false
	do
		local group = self:getCurrentGroup()
		if group then
			stack = group.commands
			inGroup = true
		else
			stack = self.stack
		end
	end

	if inGroup then
		stack[#stack+1] = command
		return true
	end

	-- index = current index
	-- index + 1 = new command index
	local index = self.index

	-- Release all commands that are ahead of this index
	for i = #stack, index + 1, -1 do
		stack[i]:release()
		stack[i] = nil
	end

	-- Add the new command
	stack[index+1] = command
	local diff = math.max(0, #stack - self.maxSize)

	self.index = index + 1 - diff

	-- Remove commands over the max size limit at the start
	for _ = 1, diff do
		table.remove(stack, 1):release()
	end

	-- ...and keep track of how many have been released
	if diff > 0 then
		self.totalShifted = self.totalShifted + diff
	end

	self.indexChanged:trigger(self.index)
	return true
end

---Adds a Command to the UndoStack and performs it
---@param command Command
function UndoStack:commit(command)
	if self:commitWithoutPerforming(command) then
		-- Successfully committed
		command:perform()
	end
end

---Removes all Commands and releases them
function UndoStack:clear()
	for i = #self.stack, 1, -1 do
		local command = self.stack[i]
		self.stack[i] = nil
		command:release()
	end
end

return UndoStack
