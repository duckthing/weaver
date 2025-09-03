local Plan = require "lib.plan"
local Modal = require "src.global.modal"
local SpriteSheet = require "src.spritesheet"
local HBox = require "ui.components.containers.box.hbox"
local AnimIconButton = require "plugins.sprite.ui.anim.animiconbutton"
local NinePatch = require "src.ninepatch"
local Fonts = require "src.global.fonts"
local Luvent = require "lib.luvent"
local Contexts = require "src.global.contexts"
local Action = require "src.data.action"

local defaultFont = Fonts.getDefaultFont()

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

local backgroundTexture = love.graphics.newImage("assets/timeline_button.png")
backgroundTexture:setFilter("nearest", "nearest")
local backgroundNP = NinePatch.new(2, 1, 2, 2, 1, 2, backgroundTexture)

---@class AnimTimeline.Header: HBox
local AnimHeader = HBox:extend()

local buttonRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.aspect(1))
	:addHeight(Plan.parent())

---@type Action[]
local trackMenuItems = {
	Action(
		"Properties",
		function (action, source, presenter, context)
			Contexts.raiseAction("inspect_frame")
		end
	),
}

--[[ ---@param self AnimTimeline.TrackLabel
local function moveFrameLeft(self)
	Contexts.raiseAction("move_frame_left")
end

---@param self AnimTimeline.TrackLabel
local function moveFrameRight(self)
	Contexts.raiseAction("move_frame_right")
end --]]

local celSize = 26
function AnimHeader:new(rules)
	AnimHeader.super.new(self, rules)

	self.splitX = 0
	self.scrollX = 0
	self._lowerX = 0
	self._upperX = 0

	---@type Sprite?
	self.sprite = nil
	self.hoveringFrameIndex = 0
	self.pressingFrameIndex = 0
	self.hovering = false
	self.pressing = false
	self.pressCount = 1
	self.scrollChanged = Luvent.newEvent()

	-- local visiblityButton = AnimIconButton(buttonRules, setAllVisiblity, iconSpriteSheet, 1, 2)
	-- local lockButton = AnimIconButton(buttonRules, setAllLocked, iconSpriteSheet, 4, 2)
	-- local linkButton = AnimIconButton(buttonRules, setAllLinked, iconSpriteSheet, 7, 2)
	-- local addFrameButton = TLIconButton(buttonRules, addFrame, iconSpriteSheet, 16, 2)
	-- local removeFrameButton = TLIconButton(buttonRules, emptyFunc, iconSpriteSheet, 17, 2)
	-- local cloneFrameButton = TLIconButton(buttonRules, emptyFunc, iconSpriteSheet, 18, 2)
	--[[ local moveLeftButton = AnimIconButton(buttonRules, moveFrameLeft, iconSpriteSheet, 19, 2)
	local moveRightButton = AnimIconButton(buttonRules, moveFrameRight, iconSpriteSheet, 20, 2) --]]
	-- self:addChild(visiblityButton)
	-- self:addChild(lockButton)
	-- self:addChild(linkButton)
	-- self:addChild(addFrameButton)
	-- self:addChild(removeFrameButton)
	-- self:addChild(cloneFrameButton)
	--[[ self:addChild(moveLeftButton)
	self:addChild(moveRightButton) --]]
end

function AnimHeader:recalculateBoundaries()
	local buttonW = self.splitX
	self._lowerX = math.max(1, math.floor((self.splitX + self.scrollX - buttonW) / celSize) + 1)
	self._upperX = math.ceil((self.scrollX - buttonW + self.w) / celSize)
	local oldW = self.w
	self.w = buttonW
	AnimHeader.super.updateScroll(self)
	self.w = oldW
end

function AnimHeader:updateScroll()
	AnimHeader.super.updateScroll(self)
	if not self.sprite then return end
	self.scrollX = math.max(0, math.min(self.scrollX, #self.sprite.frames * celSize - self.w + self.splitX))
	self:recalculateBoundaries()
	self.scrollChanged:trigger(self.scrollX)
end

function AnimHeader:refresh()
	AnimHeader.super.refresh(self)
	self:recalculateBoundaries()
end

function AnimHeader:pointerentered()
	self.hovering = true
end

function AnimHeader:pointerexited()
	self.hovering = false
	self.hoveringFrameIndex = 0
end

function AnimHeader:mousemoved(newX, newY, changeX, changeY)
	if self.panning and self.sprite then
		self.scrollX = self.scrollX - changeX
		self:updateScroll()
	else
		local x =
			math.floor((newX - self.x + self.scrollX - self.splitX) / celSize) + 1
		self.hoveringFrameIndex = x
	end
end

function AnimHeader:mousereleased(mx, my, button)
	if self.pressing and self.pressingFrameIndex == self.hoveringFrameIndex then
		local frame = self.sprite.frames[self.hoveringFrameIndex]
		if frame then
			-- This index is valid
			local spriteState = self.spriteState
			if button == 1 then
				if self.pressCount >= 2 and spriteState.frame:get() == frame.index then
					-- Double clicked same frame; open properties
					self:bubble("_bSelectFrame", frame)
					Modal.pushInspector(frame)
				else
					self:bubble("_bSelectFrame", frame)
				end
			elseif button == 2 then
				self:bubble("_bSelectFrame", frame)
				Modal.pushMenu(mx, my, trackMenuItems, frame, Contexts.contextStack[#Contexts.contextStack])
			end
		end
	end

	self.panning = false
	self.pressing = false
	self:releaseFocus()
end

function AnimHeader:mousepressed(_, _, button, _, pressCount)
	if button == 3 or (button == 1 and love.keyboard.isDown("space")) then
		self.panning = true
		self:getFocus()
	elseif button == 1 or button == 2 then
		self.pressing = true
		self.pressingFrameIndex = self.hoveringFrameIndex
		self.pressCount = pressCount
		self:getFocus()
	end
end

function AnimHeader:wheelmoved(x, y)
	self.scrollX = self.scrollX + (x + y) * celSize
	self:updateScroll()
end

---@param sprite Sprite
function AnimHeader:onSpriteSelected(sprite)
	self.sprite = sprite
	self.spriteState = sprite.spriteState

	-- Add right click actions
	local actions = self.spriteState.context:getActions()
	if #trackMenuItems == 1 then
		table.insert(trackMenuItems, 1, actions.new_frame)
		table.insert(trackMenuItems, 2, actions.clone_frame)
		table.insert(trackMenuItems, 3, actions.clone_linked_frame)
		table.insert(trackMenuItems, 4, actions.delete_frame)
	end

	for _, child in ipairs(self.children) do
		child.sprite = sprite
	end
end

function AnimHeader:onSpriteDeselected()
	self.sprite = nil
	self.spriteState = nil

	for _, child in ipairs(self.children) do
		child.sprite = nil
	end
end

function AnimHeader:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

	-- The background
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	-- The buttons
	local oldW = self.w
	self.w = self.splitX
	AnimHeader.super.draw(self)
	self.w = oldW

	-- The spacer
	local remainingSpaceW = self.splitX - (#self.children) * celSize
	if remainingSpaceW > 0 then
		love.graphics.setColor(0.2, 0.2, 0.4)
		backgroundNP:draw(self.x + (#self.children) * celSize, self.y, remainingSpaceW, self.h, 2)
	end

	-- The frames
	if self.w - self.splitX < 0 then return end
	---@type Sprite
	local sprite = self.sprite
	---@type SpriteState
	local state = self.spriteState
	love.graphics.intersectScissor(self.x + self.splitX, self.y, self.w - self.splitX, self.h)
	local startX = self.x + self.splitX - self.scrollX
	local textYStart = (self.h - defaultFont:getHeight()) * 0.5

	local MAJOR_STEP = 50
	local animScale = state.animationScale:get()
	local stepSize = MAJOR_STEP * animScale

	---@type Sprite.Animation?
	local currentAnimation = state.currentAnimation:getValue()
	if currentAnimation then
		local duration = currentAnimation.duration:get()
		local w, h = self.w, self.h

		local tickHeight = h * 0.25
		local tickStart = h - tickHeight

		for i = 0, math.ceil(duration) do
			local cx, cy =
				startX + i * stepSize,
				self.y
			love.graphics.setColor(0.8, 0.8, 0.8, 1)
			love.graphics.print(tostring(i), startX + i * stepSize, cy + textYStart)

			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("fill", cx - 1, cy + tickStart, 2, tickHeight)
		end
	end

	-- Reset the scissor
	love.graphics.setScissor(ox, oy, ow, oh)
end

return AnimHeader
