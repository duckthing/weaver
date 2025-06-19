local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class SelectionTransformCommand: SpriteCommand
local SelectionTransformCommand = SpriteCommand:extend()
SelectionTransformCommand.CLASS_NAME = "SelectionTransformCommand"
---@type SpriteTool
SelectionTransformCommand.SpriteTool = nil

---@param sprite Sprite
function SelectionTransformCommand:new(sprite)
	SelectionTransformCommand.super.new(self, sprite)
	local state = sprite.spriteState
	self.spriteState = state

	self.oldX = state.selectionX
	self.oldY = state.selectionY

	---@type integer, integer
	self.newX, self.newY = nil, nil

	self.oldIncludeMimic = state.includeMimic
	self.newIncludeMimic = true

	self.relevantLayer = state.layer:get()
	self.relevantFrame = state.frame:get()
end

function SelectionTransformCommand:completeTransform()
	local state = self.spriteState
	self.newX = state.selectionX
	self.newY = state.selectionY
end

function SelectionTransformCommand:perform()
	local state = self.spriteState
	state.selectionX = self.newX
	state.selectionY = self.newY
	state.includeMimic = self.newIncludeMimic
	SelectionTransformCommand.SpriteTool.updateCanvas()
end

function SelectionTransformCommand:undo()
	local state = self.spriteState
	state.selectionX = self.oldX
	state.selectionY = self.oldY
	state.includeMimic = self.oldIncludeMimic
	SelectionTransformCommand.SpriteTool.updateCanvas()
end

function SelectionTransformCommand:getPosition()
	return self.relevantLayer, self.relevantFrame
end

function SelectionTransformCommand:hasChanges()
	return (self.oldX ~= self.newX) or (self.oldY ~= self.newY)
end

return SelectionTransformCommand
