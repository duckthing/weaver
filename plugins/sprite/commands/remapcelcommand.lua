local SpriteCommand = require "plugins.sprite.commands.spritecommand"

---@class RemapCelCommand: SpriteCommand
local RemapCelCommand = SpriteCommand:extend()
RemapCelCommand.CLASS_NAME = "RemapCelCommand"

---@param sprite Sprite
function RemapCelCommand:new(sprite)
	RemapCelCommand.super.new(self, sprite)

	---@type {[Sprite.Layer]: {[integer]: integer}}
	self.oldLayerFrameIndex = {}
	---@type {[Sprite.Layer]: {[integer]: integer}}
	self.newLayerFrameIndex = {}
end

---Stores the original value of the cel index
---@param layer Sprite.Layer
---@param frameI integer
function RemapCelCommand:storeOriginal(layer, frameI)
	local map = self.oldLayerFrameIndex
	if not map[layer] then map[layer] = {} end
	map[layer][frameI] = layer.celIndices[frameI]
end

---Stores the new value of the cel index
---@param layer Sprite.Layer
---@param frameI integer
function RemapCelCommand:storeNew(layer, frameI)
	local map = self.newLayerFrameIndex
	if not map[layer] then map[layer] = {} end
	map[layer][frameI] = layer.celIndices[frameI]
end

function RemapCelCommand:undo()
	for layer, mappedFrames in pairs(self.oldLayerFrameIndex) do
		for frameIndex, oldFrame in pairs(mappedFrames) do
			layer.celIndices[frameIndex] = oldFrame
		end
	end
	self.sprite.celIndexEdited:trigger()
end

function RemapCelCommand:perform()
	for layer, mappedFrames in pairs(self.newLayerFrameIndex) do
		for frameIndex, newFrame in pairs(mappedFrames) do
			layer.celIndices[frameIndex] = newFrame
		end
	end
	self.sprite.celIndexEdited:trigger()
end

function RemapCelCommand:release()
	self.oldLayerFrameIndex = nil
	self.newLayerFrameIndex = nil
end

function RemapCelCommand:hasChanges()
	for layer, mappedFrames in pairs(self.oldLayerFrameIndex) do
		for frameIndex, oldFrame in pairs(mappedFrames) do
			if not self.newLayerFrameIndex[layer] then error("Missing the new changes for a layer") end
			if self.newLayerFrameIndex[layer][frameIndex] ~= oldFrame then
				return true
			end
		end
	end
	return false
end

return RemapCelCommand
