local Plan = require "lib.plan"
local Luvent = require "lib.luvent"
local VScroll = require "ui.components.containers.box.vscroll"

local TrackButton = require "plugins.sprite.ui.anim.animtrackbutton"

local timelineRules = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.keep())
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(26))

---@class AnimTimeline.Tracks: VScroll
local TrackContainer = VScroll:extend()

function TrackContainer:new(rules)
	TrackContainer.super.new(self, rules)
	self.allowScrolling = true
	self.scrollSpeed = 26
	self.minW = 78
	---@type Sprite?
	self.sprite = nil
	self.scrollChanged = Luvent.newEvent()
end

---@param sprite Sprite
function TrackContainer:onSpriteSelected(sprite)
	local selectedLayer = sprite.layers[sprite.spriteState.layer:get()]
	for _, layer in ipairs(sprite.layers) do
		---@type AnimTimeline.TrackButton
		local layerLabel = TrackButton(timelineRules, sprite, layer)
		layerLabel.animTrackLabel.selected = layer == selectedLayer
		self:addChild(layerLabel)
	end

	self._layerInsertedAction = sprite.layerInserted:addAction(function(buf, newLayer, index)
		self:addChild(TrackButton(timelineRules, sprite, newLayer), index)
	end)

	self._layerMovedAction = sprite.layerMoved:addAction(function(s, iLayer, i, jLayer, j)
		self.children[i], self.children[j]
			= self.children[j], self.children[i]
		self:refresh()
	end)

	self._layerRemovedAction = sprite.layerRemoved:addAction(function(s, layer, oldI)
		self:removeChild(self.children[oldI])
	end)

	self.sprite = sprite
end

function TrackContainer:onSpriteDeselected()
	self:clearChildren()
	self.sprite.layerInserted:removeAction(self._layerInsertedAction)
	self.sprite.layerMoved:removeAction(self._layerMovedAction)
	self._layerInsertedAction = nil
	self._layerMovedAction = nil
	self.sprite = nil
end

function TrackContainer:onLayerSelected(selectedLayer)
	for _, layerLabel in ipairs(self.children) do
		---@cast layerLabel AnimTimeline.TrackButton
		layerLabel.animTrackLabel.selected = layerLabel.layer == selectedLayer
	end
end

function TrackContainer:wheelmoved(...)
	---@diagnostic disable-next-line
	TrackContainer.super.wheelmoved(self, ...)
	self.scrollChanged:trigger(self.offset)
end

return TrackContainer
