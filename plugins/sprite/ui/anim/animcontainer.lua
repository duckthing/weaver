local Plan = require "lib.plan"
local Luvent = require "lib.luvent"

local VSplit = require "ui.components.containers.split.vsplit"
local AnimSheet = require "plugins.sprite.ui.anim.animsheet"
local TrackContainer = require "plugins.sprite.ui.anim.animtrackcontainer"
local AnimActions = require "plugins.sprite.ui.anim.animactions"
local TLHeader = require "plugins.sprite.ui.anim.animheader"

---@class AnimTimeline: Plan.Container
local AnimContainer = Plan.Container:extend()

---@class AnimTimeline.LCSplit: VSplit
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

function AnimContainer:new(rules)
	AnimContainer.super.new(self, rules)
	self._clipMode = "clip"
	self.minH = 34
	---@type AnimTimeline.Tracks
	self.trackContainer = TrackContainer(Plan.RuleFactory.full())

	---@type AnimTimeline.Sheet
	self.animSheet = AnimSheet(Plan.RuleFactory.full())

	---@type AnimTimeline.Header
	self.header = TLHeader(headerRules)

	---@type AnimTimeline.Actions
	self.animActions = AnimActions(actionsRules)

	---@type AnimTimeline.LCSplit
	self.trackTable = LCSplit(tableRules, self.trackContainer, self.animSheet)
	self.trackTable.resizeMode = "keepfirst"
	self.trackTable:setSize(208)

	---@type Sprite?
	self.activeSprite = nil
	---@type SpriteState?
	self.spriteState = nil

	---@type string?
	self._layerChangedAction = nil
	---@type string?
	self._frameChangedAction = nil

	self:addChild(self.header)
	self:addChild(self.animActions)
	self:addChild(self.trackTable)

	self.trackContainer.scrollChanged:addAction(function(posY)
		self.animSheet.scrollY = posY
		self.animSheet:recalculateBoundaries()
		self.header:recalculateBoundaries()
	end)

	self.animSheet.scrollChanged:addAction(function(posX, posY)
		self.trackContainer.targetOffset = posY
		self.trackContainer:refresh()
		self.header.scrollX = posX
		self.header:recalculateBoundaries()
	end)

	self.trackTable.splitChanged:addAction(function(splitX)
		self.header.splitX = splitX
		self.header:refresh()
	end)

	self.header.scrollChanged:addAction(function(posX)
		self.animSheet.scrollX = posX
		self.animSheet:recalculateBoundaries()
	end)
end

function AnimContainer:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	AnimContainer.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

---@param sprite Sprite
function AnimContainer:onSpriteSelected(sprite)
	self.trackContainer:onSpriteSelected(sprite)
	self.animSheet:onSpriteSelected(sprite)
	self.header:onSpriteSelected(sprite)
	self.animActions:onSpriteSelected(sprite)

	self.activeSprite = sprite

	local state = sprite.spriteState
	self.spriteState = state
	self.header.splitX = self.trackTable.splitPosition
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

function AnimContainer:onSpriteDeselected()
	self.trackContainer:onSpriteDeselected()
	self.animSheet:onSpriteDeselected()
	self.header:onSpriteDeselected()
	self.animActions:onSpriteDeselected()

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
function AnimContainer:onLayerSelected(selectedLayer)
	self.trackContainer:onLayerSelected(selectedLayer)
	self.animSheet:onLayerSelected(selectedLayer)
end

---@param selectedFrame Sprite.Frame
function AnimContainer:onFrameSelected(selectedFrame)
	self.animSheet:onFrameSelected(selectedFrame)
end

-- (Receive bubble) Select layer
---@param sourceElement Plan.Container
---@param selectedLayer Sprite.Layer
---@return false
function AnimContainer:_bSelectLayer(sourceElement, selectedLayer)
	self.spriteState.layer:set(selectedLayer.index)
	return false
end

-- (Receive bubble) Select frame
---@param sourceElement Plan.Container
---@param selectedFrame Sprite.Frame
---@return false
function AnimContainer:_bSelectFrame(sourceElement, selectedFrame)
	self.spriteState.frame:set(selectedFrame.index)
	return false
end

return AnimContainer
