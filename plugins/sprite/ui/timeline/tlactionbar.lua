local Plan = require "lib.plan"
local SpriteSheet = require "src.spritesheet"
local IconButton = require "ui.components.button.iconbutton"
local DropdownButton = require "ui.components.button.dropdownbutton"
local Contexts = require "src.global.contexts"
local HFlex = require "ui.components.containers.flex.hflex"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class Timeline.Actions: HFlex
local TimelineActions = HFlex:extend()

local buttonRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.keep())
	:addHeight(Plan.parent())

local containerRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.keep())
	:addHeight(Plan.parent())

local dropdownRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.keep())
	:addHeight(Plan.parent())

---@class Timeline.ActionButton: IconButton
local TLActionButton = IconButton:extend()

---@param rules Plan.Rules
---@param action string
---@param ... unknown
function TLActionButton:new(rules, action, ...)
	TLActionButton.super.new(self, rules, nil, ...)
	self.action = action
	self.sizeRatio = 1
end

function TLActionButton:onClick()
	Contexts.raiseAction(self.action)
end

local buttonSize = 38
function TLActionButton:getDesiredDimensions()
	return buttonSize, nil
end

---@param self Timeline.Actions
local function containersGetDesiredWidth(self)
	local totalSize = 0
	for i = 1, #self.children do
		local dw, _ = self.children[i]:getDesiredDimensions()
		totalSize = totalSize + (dw or buttonSize)
	end

	return totalSize, nil
end

function TimelineActions:new(rules)
	TimelineActions.super.new(self, rules)
	---@type HFlex.Justify
	self.justify = "spacebetween"
	self.padding = 4

	local addFrameButton = TLActionButton(buttonRules, "new_frame", iconSpriteSheet, 16, 2)
	local removeFrameButton = TLActionButton(buttonRules, "delete_frame", iconSpriteSheet, 17, 2)
	local cloneFrameButton = TLActionButton(buttonRules, "clone_frame", iconSpriteSheet, 18, 2)
	local skipBackButton = TLActionButton(buttonRules, "select_first_frame", iconSpriteSheet, 9, 2)
	local skipForwardButton = TLActionButton(buttonRules, "select_last_frame", iconSpriteSheet, 15, 2)
	local stepBackButton = TLActionButton(buttonRules, "select_previous_frame", iconSpriteSheet, 10, 2)
	local stepForwardButton = TLActionButton(buttonRules, "select_next_frame", iconSpriteSheet, 14, 2)
	local playButton = TLActionButton(buttonRules, "toggle_animation", iconSpriteSheet, 13, 2)
	playButton.getDesiredDimensions = TLActionButton.getDesiredDimensions
	-- playButton.sizeRatio = 1
	---@type DropdownButton
	-- local animationDropdown = DropdownButton(dropdownRules, nil)

	---@type HFlex
	local playerControls = HFlex(containerRules)
	-- playerControls:addChild(animationDropdown)
	playerControls:addChild(addFrameButton)
	playerControls:addChild(removeFrameButton)
	playerControls:addChild(cloneFrameButton)
	playerControls:addChild(skipBackButton)
	playerControls:addChild(stepBackButton)
	playerControls:addChild(playButton)
	playerControls:addChild(stepForwardButton)
	playerControls:addChild(skipForwardButton)
	playerControls.margin = 0
	playerControls.padding = 0
	playerControls.getDesiredDimensions = containersGetDesiredWidth

	local newLayerButton = TLActionButton(buttonRules, "new_layer", iconSpriteSheet, 16, 2)
	local deleteLayerButton = TLActionButton(buttonRules, "delete_layer", iconSpriteSheet, 17, 2)
	local cloneLayerButton = TLActionButton(buttonRules, "clone_layer", iconSpriteSheet, 18, 2)
	local moveLayerUpButton = TLActionButton(buttonRules, "move_layer_up", iconSpriteSheet, 21, 2)
	local moveLayerDownButton = TLActionButton(buttonRules, "move_layer_down", iconSpriteSheet, 22, 2)

	---@type HFlex
	local layerControls = HFlex(containerRules)
	layerControls:addChild(newLayerButton)
	layerControls:addChild(deleteLayerButton)
	layerControls:addChild(cloneLayerButton)
	layerControls:addChild(moveLayerUpButton)
	layerControls:addChild(moveLayerDownButton)
	layerControls.margin = 0
	layerControls.padding = 0
	layerControls.getDesiredDimensions = containersGetDesiredWidth

	-- self.animationDropdown = animationDropdown
	self:addChild(layerControls)
	self:addChild(playerControls)
end

---@param sprite Sprite
function TimelineActions:onSpriteSelected(sprite)
	-- self.animationDropdown:bindToProperty(sprite.spriteState.currentAnimation)
end

function TimelineActions:onSpriteDeselected()
	-- self.animationDropdown:bindToProperty()
end

return TimelineActions
