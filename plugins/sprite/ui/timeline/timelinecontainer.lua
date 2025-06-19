local Plan = require "lib.plan"
local Luvent = require "lib.luvent"

local VSplit = require "ui.components.containers.split.vsplit"
local CelTimelines = require "plugins.sprite.ui.timeline.tlcelcontainer"
local LayerTimelines = require "plugins.sprite.ui.timeline.tllayercontainer"
local TimelineActions = require "plugins.sprite.ui.timeline.tlactionbar"
local TLHeader = require "plugins.sprite.ui.timeline.tlheader"

---@class Timeline: Plan.Container
local TimelineContainer = Plan.Container:extend()

---@class Timeline.LCSplit: VSplit
local LCSplit = VSplit:extend()

function LCSplit:new(...)
	LCSplit.super.new(self, ...)
	self.splitChanged = Luvent.newEvent()
end

function LCSplit:draw()
	if self.h <= 0 then return end
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	LCSplit.super.draw(self)
end

function LCSplit:updateSplit(...)
	---@diagnostic disable-next-line
	LCSplit.super.updateSplit(self, ...)
	self.splitChanged:trigger(self.splitPosition)
end

local actionsRules = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.pixel(5))
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(24))

local tableRules = Plan.Rules.new()
	:addX(Plan.pixel(5))
	:addY(Plan.pixel(60))
	:addWidth(Plan.max(10))
	:addHeight(Plan.max(60))

local headerRules = Plan.Rules.new()
	:addX(Plan.pixel(5))
	:addY(Plan.pixel(34))
	:addWidth(Plan.max(10))
	:addHeight(Plan.pixel(26))

function TimelineContainer:new(rules)
	TimelineContainer.super.new(self, rules)
	self._clipMode = "clip"
	self.minH = 34
	---@type Timeline.Layers
	self.layerContainer = LayerTimelines(Plan.RuleFactory.full())

	---@type Timeline.Cels
	self.celContainer = CelTimelines(Plan.RuleFactory.full())

	---@type Timeline.Header
	self.header = TLHeader(headerRules)

	---@type Timeline.Actions
	self.timelineActions = TimelineActions(actionsRules)

	---@type Timeline.LCSplit
	self.layerTable = LCSplit(tableRules, self.layerContainer, self.celContainer)
	self.layerTable.splitPosition = 208
	self.layerTable.resizeMode = "keepfirst"
	---@type Sprite?
	self.activeSprite = nil
	---@type SpriteState?
	self.spriteState = nil

	---@type string?
	self._layerChangedAction = nil
	---@type string?
	self._frameChangedAction = nil

	self:addChild(self.header)
	self:addChild(self.timelineActions)
	self:addChild(self.layerTable)

	self.layerContainer.scrollChanged:addAction(function(posY)
		self.celContainer.scrollY = posY
		self.celContainer:recalculateBoundaries()
		self.header:recalculateBoundaries()
	end)

	self.celContainer.scrollChanged:addAction(function(posX, posY)
		self.layerContainer.offset = posY
		self.layerContainer:refresh()
		self.header.scrollX = posX
		self.header:recalculateBoundaries()
	end)

	self.layerTable.splitChanged:addAction(function(splitX)
		self.header.splitX = splitX
		self.header:refresh()
	end)

	self.header.scrollChanged:addAction(function(posX)
		self.celContainer.scrollX = posX
		self.celContainer:recalculateBoundaries()
	end)
end

function TimelineContainer:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	TimelineContainer.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

---@param sprite Sprite
function TimelineContainer:onSpriteSelected(sprite)
	self.layerContainer:onSpriteSelected(sprite)
	self.celContainer:onSpriteSelected(sprite)
	self.header:onSpriteSelected(sprite)
	self.timelineActions:onSpriteSelected(sprite)
	self.activeSprite = sprite
	local state = sprite.spriteState
	self.spriteState = state
	self.header.splitX = self.layerTable.splitPosition
	self.header:recalculateBoundaries()

	self._layerChangedAction = state.layer.valueChanged:addAction(function(property, value)
		local layer = self.activeSprite.layers[value]
		self:onLayerSelected(layer)
	end)

	self._frameChangedAction = state.frame.valueChanged:addAction(function(property, value)
		local frame = self.activeSprite.frames[value]
		self:onFrameSelected(frame)
	end)
end

function TimelineContainer:onSpriteDeselected()
	self.layerContainer:onSpriteDeselected()
	self.celContainer:onSpriteDeselected()
	self.header:onSpriteDeselected()
	self.timelineActions:onSpriteDeselected()

	---@type SpriteState
	local oldState = self.spriteState
	if self._layerChangedAction then
		oldState.layer.valueChanged:removeAction(self._layerChangedAction)
		self._layerChangedAction = nil
	end

	if self._frameChangedAction then
		oldState.frame.valueChanged:removeAction(self._frameChangedAction)
		self._frameChangedAction = nil
	end

	self.activeSprite = nil
	self.spriteState = nil
end

---@param selectedLayer Sprite.Layer
function TimelineContainer:onLayerSelected(selectedLayer)
	self.layerContainer:onLayerSelected(selectedLayer)
	self.celContainer:onLayerSelected(selectedLayer)
end

---@param selectedFrame Sprite.Frame
function TimelineContainer:onFrameSelected(selectedFrame)
	self.celContainer:onFrameSelected(selectedFrame)
end

-- (Receive bubble) Select layer
---@param sourceElement Plan.Container
---@param selectedLayer Sprite.Layer
---@return false
function TimelineContainer:_bSelectLayer(sourceElement, selectedLayer)
	self.spriteState.layer:set(selectedLayer.index)
	return false
end

-- (Receive bubble) Select frame
---@param sourceElement Plan.Container
---@param selectedFrame Sprite.Frame
---@return false
function TimelineContainer:_bSelectFrame(sourceElement, selectedFrame)
	self.spriteState.frame:set(selectedFrame.index)
	return false
end

return TimelineContainer
