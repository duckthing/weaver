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
	self.oldRotation = state.selectionRotation
	self.oldOriginX, self.oldOriginY = state.selectionOriginX, state.selectionOriginY

	---@type integer, integer
	self.newX, self.newY = nil, nil
	---@type number, number
	self.newScaleX, self.newScaleY = nil, nil
	---@type number
	self.newRotation = state.selectionRotation
	---@type number, number
	self.newOriginX, self.newOriginY = nil, nil

	self.oldIncludeMimic = state.includeMimic
	self.newIncludeMimic = true
	self.oldIncludeBitmask = state.includeBitmask
	self.newIncludeBitmask = true

	self.relevantLayer = state.layer:get()
	self.relevantFrame = state.frame:get()

	---@type boolean # Whether this can change the rendering, such as "includeMimic"
	self.allowRenderState = true
end

function SelectionTransformCommand:completeTransform()
	local state = self.spriteState
	self.newX = state.selectionX
	self.newY = state.selectionY

	self.newScaleX = state.selectionScaleX
	self.newScaleY = state.selectionScaleY

	self.newOriginX = state.selectionOriginX
	self.newOriginY = state.selectionOriginY

	self.newRotation = state.selectionRotation

	self.newIncludeMimic = state.includeMimic
	self.newIncludeBitmask = state.includeBitmask
end

function SelectionTransformCommand:perform()
	local state = self.spriteState

	state.selectionX = self.newX
	state.selectionY = self.newY
	state.selectionScaleX = self.newScaleX
	state.selectionScaleY = self.newScaleY
	state.selectionRotation = self.newRotation
	state.selectionOriginX = self.newOriginX
	state.selectionOriginY = self.newOriginY

	if self.allowRenderState then
		state.includeMimic = self.newIncludeMimic
		state.includeBitmask = self.newIncludeBitmask
	end
	SelectionTransformCommand.SpriteTool.updateCanvas()
end

function SelectionTransformCommand:undo()
	local state = self.spriteState

	state.selectionX = self.oldX
	state.selectionY = self.oldY
	state.selectionScaleX = self.oldScaleX
	state.selectionScaleY = self.oldScaleY
	state.selectionRotation = self.oldRotation
	state.selectionOriginX = self.oldOriginX
	state.selectionOriginY = self.oldOriginY

	if self.allowRenderState then
		state.includeMimic = self.oldIncludeMimic
		state.includeBitmask = self.oldIncludeBitmask
	end
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
		or
		(self.oldRotation ~= self.newRotation)
		or
		(self.oldOriginX ~= self.newOriginX) or (self.oldOriginY ~= self.newOriginY)
end

return SelectionTransformCommand
