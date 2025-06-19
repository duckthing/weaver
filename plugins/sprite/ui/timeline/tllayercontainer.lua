local Plan = require "lib.plan"
local Luvent = require "lib.luvent"
local VScroll = require "ui.components.containers.box.vscroll"

local LayerTimeline = require "plugins.sprite.ui.timeline.tllayer"

local timelineRules = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.keep())
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(26))

---@class Timeline.Layers: VScroll
local LayerContainer = VScroll:extend()

function LayerContainer:new(rules)
	LayerContainer.super.new(self, rules)
	self.allowScrolling = true
	self.scrollSpeed = 26
	self.minW = 78
	---@type Sprite?
	self.sprite = nil
	self.scrollChanged = Luvent.newEvent()
end

---@param sprite Sprite
function LayerContainer:onSpriteSelected(sprite)
	local selectedLayer = sprite.layers[sprite.spriteState.layer:get()]
	for _, layer in ipairs(sprite.layers) do
		local layerLabel = LayerTimeline(timelineRules, sprite, layer)
		layerLabel.tlLayerLabel.selected = layer == selectedLayer
		self:addChild(layerLabel)
	end

	self._layerInsertedAction = sprite.layerInserted:addAction(function(buf, newLayer, index)
		self:addChild(LayerTimeline(timelineRules, sprite, newLayer), index)
	end)

	self._layerMovedAction = sprite.layerMoved:addAction(function(s, iLayer, i, jLayer, j)
		self.children[i], self.children[j]
			= self.children[j], self.children[i]
		self:refresh()
	end)

	self._layerRemovedAction = sprite.layerRemoved:addAction(function(s, layer, oldI)
		table.remove(self.children, oldI)
		self:refresh()
	end)

	self.sprite = sprite
end

function LayerContainer:onSpriteDeselected()
	self:clearChildren()
	self.sprite.layerInserted:removeAction(self._layerInsertedAction)
	self.sprite.layerMoved:removeAction(self._layerMovedAction)
	self._layerInsertedAction = nil
	self._layerMovedAction = nil
	self.sprite = nil
end

function LayerContainer:onLayerSelected(selectedLayer)
	for _, layerLabel in ipairs(self.children) do
		---@cast layerLabel Timeline.Layer
		layerLabel.tlLayerLabel.selected = layerLabel.layer == selectedLayer
	end
end

function LayerContainer:wheelmoved(...)
	---@diagnostic disable-next-line
	LayerContainer.super.wheelmoved(self, ...)
	self.scrollChanged:trigger(self.offset)
end

return LayerContainer
