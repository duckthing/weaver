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

	self.oldX, self.oldY = state.selectionX, state.selectionY
	self.oldScaleX, self.oldScaleY = state.selectionScaleX, state.selectionScaleY

	---@type integer, integer
	self.newX, self.newY = nil, nil
	---@type number, number
	self.newScaleX, self.newScaleY = nil, nil

	self.oldIncludeMimic = state.includeMimic
	self.newIncludeMimic = true

	self.relevantLayer = state.layer:get()
	self.relevantFrame = state.frame:get()
end

function SelectionTransformCommand:completeTransform()
	local state = self.spriteState
	self.newX = state.selectionX
	self.newY = state.selectionY

	self.newScaleX = state.selectionScaleX
	self.newScaleY = state.selectionScaleY
end

function SelectionTransformCommand:perform()
	local state = self.spriteState

	state.selectionX = self.newX
	state.selectionY = self.newY
	state.selectionScaleX = self.newScaleX
	state.selectionScaleY = self.newScaleY

	state.includeMimic = self.newIncludeMimic
	SelectionTransformCommand.SpriteTool.updateCanvas()
end

function SelectionTransformCommand:undo()
	local state = self.spriteState

	state.selectionX = self.oldX
	state.selectionY = self.oldY
	state.selectionScaleX = self.oldScaleX
	state.selectionScaleY = self.oldScaleY

	state.includeMimic = self.oldIncludeMimic
	SelectionTransformCommand.SpriteTool.updateCanvas()
end

function SelectionTransformCommand:getPosition()
	return self.relevantLayer, self.relevantFrame
end

function SelectionTransformCommand:hasChanges()
	return
		(self.oldX ~= self.newX) or (self.oldY ~= self.newY)
		or
		(self.oldScaleX ~= self.newScaleX) or (self.oldScaleY ~= self.newScaleY)
end

return SelectionTransformCommand
