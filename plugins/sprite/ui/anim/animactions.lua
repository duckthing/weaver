local Plan = require "lib.plan"
local SpriteSheet = require "src.spritesheet"
local IconButton = require "ui.components.button.iconbutton"
local DropdownButton = require "ui.components.button.dropdownbutton"
local Contexts = require "src.global.contexts"
local HFlex = require "ui.components.containers.flex.hflex"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class AnimTimeline.Actions: HFlex
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

---@class AnimTimeline.ActionButton: IconButton
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
	self.justify = "end"
	self.padding = 4

	local addFrameButton = TLActionButton(buttonRules, "new_frame", iconSpriteSheet, 16, 2)
	local removeFrameButton = TLActionButton(buttonRules, "delete_frame", iconSpriteSheet, 17, 2)
	local cloneFrameButton = TLActionButton(buttonRules, "clone_frame", iconSpriteSheet, 18, 2)

	---@type HFlex
	local playerControls = HFlex(containerRules)
	-- playerControls:addChild(animationDropdown)
	playerControls:addChild(addFrameButton)
	playerControls:addChild(removeFrameButton)
	playerControls:addChild(cloneFrameButton)
	playerControls.margin = 0
	playerControls.padding = 0
	playerControls.getDesiredDimensions = containersGetDesiredWidth

	-- self.animationDropdown = animationDropdown
	self:addChild(playerControls)
end

return TimelineActions
