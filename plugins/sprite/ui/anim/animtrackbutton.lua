local Plan = require "lib.plan"
local SpriteSheet = require "src.spritesheet"
local HBox = require "ui.components.containers.box.hbox"
local AnimTrackLabel = require "plugins.sprite.ui.anim.animtrackname"
local AnimIconButton = require "plugins.sprite.ui.anim.animiconbutton"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class AnimTimeline.TrackButton: HBox
local AnimTrackButton = HBox:extend()
local animTrackLabelRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.max(0))
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
function AnimTrackButton:new(rules, sprite, layer)
	AnimTrackButton.super.new(self, rules)
	self.layer = layer

	local visibilityButton = AnimIconButton(buttonRules, onVisibilityPressed, iconSpriteSheet, 1, 2)
	local lockButton = AnimIconButton(buttonRules, onLockedPressed, iconSpriteSheet, 4, 2)
	local linkButton = AnimIconButton(buttonRules, onLinkedPressed, iconSpriteSheet, 7, 2)

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

	---@type AnimTimeline.TrackLabel
	local animTrackLabel = AnimTrackLabel(animTrackLabelRules, sprite, layer)
	self.animTrackLabel = animTrackLabel

	self:addChild(animTrackLabel)
end

function AnimTrackButton:onRemovedFromParent()
	AnimTrackButton.super.onRemovedFromParent(self)
	-- layer.visible.valueChanged:removeAction(self._layerVisibleChanged)
	-- layer.locked.valueChanged:removeAction(self._layerLockedChanged)
	-- layer.preferLinkedCels.valueChanged:removeAction(self._layerLinkedChanged)
end

return AnimTrackButton
