local Plan = require "lib.plan"
local SpriteSheet = require "src.spritesheet"
local HBox = require "ui.components.containers.box.hbox"
local TLLayerLabel = require "plugins.sprite.ui.timeline.tllayername"
local TLIconButton = require "plugins.sprite.ui.timeline.tliconbutton"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class Timeline.Layer: HBox
local LayerTimeline = HBox:extend()
local tlLayerLabelRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.max(78))
	:addHeight(Plan.parent())

local buttonRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.aspect(1))
	:addHeight(Plan.parent())

local function onVisibilityPressed(self)
	self.layer.visible:toggle()
end

local function onLockedPressed(self)
	self.layer.locked:toggle()
end

local function onLinkedPressed(self)
	self.layer.preferLinkedCels:toggle()
end

---@param rules Plan.Rules
---@param sprite Sprite
---@param layer Sprite.Layer
function LayerTimeline:new(rules, sprite, layer)
	LayerTimeline.super.new(self, rules)
	self.layer = layer

	local visibilityButton = TLIconButton(buttonRules, onVisibilityPressed, iconSpriteSheet, 1, 2)
	local lockButton = TLIconButton(buttonRules, onLockedPressed, iconSpriteSheet, 4, 2)
	local linkButton = TLIconButton(buttonRules, onLinkedPressed, iconSpriteSheet, 7, 2)

	visibilityButton.layer = layer
	if layer.visible:get() then
		-- Visible
		visibilityButton.frame = 1
	else
		-- Hidden
		visibilityButton.frame = 2
	end

	lockButton.layer = layer
	if layer.locked:get() then
		-- Locked
		lockButton.frame = 3
	else
		-- Unlocked
		lockButton.frame = 4
	end

	linkButton.layer = layer
	if layer.preferLinkedCels:get() then
		-- Unlinked
		linkButton.frame = 7
	else
		-- Linked
		linkButton.frame = 8
	end

	local tlLayerLabel = TLLayerLabel(tlLayerLabelRules, sprite, layer)
	---@type Timeline.LayerLabel
	self.tlLayerLabel = tlLayerLabel

	self:addChild(visibilityButton)
	self:addChild(lockButton)
	self:addChild(linkButton)
	self:addChild(tlLayerLabel)

	---@type string
	self._layerVisibleChanged = layer.visible.valueChanged:addAction(function(property, visible)
		if visible then
			-- Visible
			visibilityButton.frame = 1
		else
			-- Hidden
			visibilityButton.frame = 2
		end
	end)

	---@type string
	self._layerLockedChanged = layer.locked.valueChanged:addAction(function(property, locked)
		if locked then
			-- Locked
			lockButton.frame = 3
		else
			-- Not locked
			lockButton.frame = 4
		end
	end)

	---@type string
	self._layerLinkedChanged = layer.preferLinkedCels.valueChanged:addAction(function(property, linked)
		if linked then
			-- Linked
			linkButton.frame = 7
		else
			-- Unlinked
			linkButton.frame = 8
		end
	end)
end

function LayerTimeline:onRemovedFromParent()
	local layer = self.layer
	layer.visible.valueChanged:removeAction(self._layerVisibleChanged)
	layer.locked.valueChanged:removeAction(self._layerLockedChanged)
	layer.preferLinkedCels.valueChanged:removeAction(self._layerLinkedChanged)
end

return LayerTimeline
