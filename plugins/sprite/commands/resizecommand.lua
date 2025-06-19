local SpriteCommand = require "plugins.sprite.commands.spritecommand"
local BitMask = require "plugins.sprite.data.bitmask"
local ffi = require "ffi"

---@class ResizeCommand: SpriteCommand
local ResizeCommand = SpriteCommand:extend()
ResizeCommand.CLASS_NAME = "ResizeCommand"

---@param sprite Sprite
---@param oldWidth integer
---@param oldHeight integer
---@param newWidth integer
---@param newHeight integer
---@param oldIndicesMap {[Sprite.Layer]: integer[]}
---@param newIndicesMap {[Sprite.Layer]: integer[]}
---@param oldInternalCelMap {[string]: Sprite.Cel}
---@param newInternalCelMap {[string]: Sprite.Cel}
function ResizeCommand:new(
	sprite,
	oldWidth, oldHeight, newWidth, newHeight,
	oldIndicesMap, newIndicesMap,
	oldInternalCelMap, newInternalCelMap
)
	ResizeCommand.super.new(self, sprite)
	self.oldWidth, self.oldHeight, self.newWidth, self.newHeight =
		oldWidth, oldHeight,
		newWidth, newHeight

	---@type {[Sprite.Layer]: integer[]}
	self.oldIndicesMap = oldIndicesMap
	---@type {[Sprite.Layer]: integer[]}
	self.newIndicesMap = newIndicesMap

	self.oldInternalCelMap = oldInternalCelMap
	self.newInternalCelMap = newInternalCelMap

	self.oldBitmask = sprite.spriteState.bitmask
	self.oldBitmaskRenderer = sprite.spriteState.bitmaskRenderer
	---@type Bitmask
	self.newBitmask = BitMask.new(newWidth, newHeight)
	self.newBitmaskRenderer = self.newBitmask:newRenderer()
end

function ResizeCommand:undo()
	local sprite = self.sprite
	local spriteState = sprite.spriteState
	sprite.width, sprite.height =
		self.oldWidth, self.oldHeight
	for layer, oldIndices in pairs(self.oldIndicesMap) do
		layer.celIndices = oldIndices
	end

	-- Revert to the old internal cels
	for key, oldCel in pairs(self.oldInternalCelMap) do
		spriteState[key] = oldCel
	end

	spriteState.bitmask = self.oldBitmask
	spriteState.bitmaskRenderer = self.oldBitmaskRenderer

	-- Fire related events
	sprite.spriteResized:trigger(self.oldWidth, self.oldHeight)

	-- This also fires related updates, but in a hacky way
	-- TODO: Replace the "fake update"
	local frameProperty = spriteState.frame
	local oldValue = frameProperty:get()
	frameProperty.range.value = 0
	frameProperty:set(oldValue)
end

function ResizeCommand:perform()
	local sprite = self.sprite
	local spriteState = sprite.spriteState
	sprite.width, sprite.height =
		self.newWidth, self.newHeight
	for layer, newIndices in pairs(self.newIndicesMap) do
		layer.celIndices = newIndices
	end

	-- Swap to the new internal cels
	for key, newCel in pairs(self.newInternalCelMap) do
		spriteState[key] = newCel
	end

	spriteState.bitmask = self.newBitmask
	spriteState.bitmaskRenderer = self.newBitmaskRenderer

	-- Fire related events
	sprite.spriteResized:trigger(self.newWidth, self.newHeight)

	-- This also fires related updates, but in a hacky way
	-- TODO: Replace the "fake update"
	local frameProperty = spriteState.frame
	local oldValue = frameProperty:get()
	frameProperty.range.value = 0
	frameProperty:set(oldValue)
end

function ResizeCommand:release()
	self.sprite = nil
	self.oldIndicesMap = nil
	self.newIndicesMap = nil
end

function ResizeCommand:hasChanges()
	return true
end

return ResizeCommand
