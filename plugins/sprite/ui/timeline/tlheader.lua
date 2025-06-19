local Plan = require "lib.plan"
local Modal = require "src.global.modal"
local SpriteSheet = require "src.spritesheet"
local HBox = require "ui.components.containers.box.hbox"
local TLIconButton = require "plugins.sprite.ui.timeline.tliconbutton"
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

---@class Timeline.Header: HBox
local TLHeader = HBox:extend()

local buttonRules = Plan.Rules.new()
	:addX(Plan.keep())
	:addY(Plan.pixel(0))
	:addWidth(Plan.aspect(1))
	:addHeight(Plan.parent())

---@type Action[]
local frameMenuItems = {
	Action(
		"Properties",
		function (action, source, presenter, context)
			Contexts.raiseAction("inspect_frame")
		end
	),
}

local function setAllVisiblity()
	Contexts.raiseAction("toggle_all_layer_visible")
end

local function setAllLocked()
	Contexts.raiseAction("toggle_all_layer_lock")
end

local function setAllLinked()
	Contexts.raiseAction("toggle_all_layer_link")
end

---@param self Timeline.LayerLabel
local function moveFrameLeft(self)
	Contexts.raiseAction("move_frame_left")
end

---@param self Timeline.LayerLabel
local function moveFrameRight(self)
	Contexts.raiseAction("move_frame_right")
end

local celSize = 26
function TLHeader:new(rules)
	TLHeader.super.new(self, rules)

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

	local visiblityButton = TLIconButton(buttonRules, setAllVisiblity, iconSpriteSheet, 1, 2)
	local lockButton = TLIconButton(buttonRules, setAllLocked, iconSpriteSheet, 4, 2)
	local linkButton = TLIconButton(buttonRules, setAllLinked, iconSpriteSheet, 7, 2)
	-- local addFrameButton = TLIconButton(buttonRules, addFrame, iconSpriteSheet, 16, 2)
	-- local removeFrameButton = TLIconButton(buttonRules, emptyFunc, iconSpriteSheet, 17, 2)
	-- local cloneFrameButton = TLIconButton(buttonRules, emptyFunc, iconSpriteSheet, 18, 2)
	local moveLeftButton = TLIconButton(buttonRules, moveFrameLeft, iconSpriteSheet, 19, 2)
	local moveRightButton = TLIconButton(buttonRules, moveFrameRight, iconSpriteSheet, 20, 2)
	self:addChild(visiblityButton)
	self:addChild(lockButton)
	self:addChild(linkButton)
	-- self:addChild(addFrameButton)
	-- self:addChild(removeFrameButton)
	-- self:addChild(cloneFrameButton)
	self:addChild(moveLeftButton)
	self:addChild(moveRightButton)
end

function TLHeader:recalculateBoundaries()
	local buttonW = self.splitX
	self._lowerX = math.max(1, math.floor((self.splitX + self.scrollX - buttonW) / celSize) + 1)
	self._upperX = math.ceil((self.scrollX - buttonW + self.w) / celSize)
	local oldW = self.w
	self.w = buttonW
	TLHeader.super.updateScroll(self)
	self.w = oldW
end

function TLHeader:updateScroll()
	TLHeader.super.updateScroll(self)
	if not self.sprite then return end
	self.scrollX = math.max(0, math.min(self.scrollX, #self.sprite.frames * celSize - self.w + self.splitX))
	self:recalculateBoundaries()
	self.scrollChanged:trigger(self.scrollX)
end

function TLHeader:refresh()
	TLHeader.super.refresh(self)
	self:recalculateBoundaries()
end

function TLHeader:pointerentered()
	self.hovering = true
end

function TLHeader:pointerexited()
	self.hovering = false
	self.hoveringFrameIndex = 0
end

function TLHeader:mousemoved(newX, newY, changeX, changeY)
	if self.panning and self.sprite then
		self.scrollX = self.scrollX - changeX
		self:updateScroll()
	else
		local x =
			math.floor((newX - self.x + self.scrollX - self.splitX) / celSize) + 1
		self.hoveringFrameIndex = x
	end
end

function TLHeader:mousereleased(mx, my, button)
	if self.pressing and self.pressingFrameIndex == self.hoveringFrameIndex then
		local frame = self.sprite.frames[self.hoveringFrameIndex]
		if frame then
			-- This index is valid
			self:bubble("_bSelectFrame", frame)
			if button == 1 and self.pressCount == 2 then
				-- Double clicked; open properties
				Modal.pushInspector(frame)
			elseif button == 2 then
				Modal.pushMenu(mx, my, frameMenuItems, frame, Contexts.contextStack[#Contexts.contextStack])
			end
		end
	end

	self.panning = false
	self.pressing = false
	self:releaseFocus()
end

function TLHeader:mousepressed(_, _, button, _, pressCount)
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

function TLHeader:wheelmoved(x, y)
	self.scrollX = self.scrollX + (x + y) * celSize
	self:updateScroll()
end

---@param sprite Sprite
function TLHeader:onSpriteSelected(sprite)
	self.sprite = sprite
	self.spriteState = sprite.spriteState

	-- Add right click actions
	local actions = self.spriteState.context:getActions()
	if #frameMenuItems == 1 then
		table.insert(frameMenuItems, 1, actions.new_frame)
		table.insert(frameMenuItems, 2, actions.clone_frame)
		table.insert(frameMenuItems, 3, actions.clone_linked_frame)
		table.insert(frameMenuItems, 4, actions.delete_frame)
	end

	for _, child in ipairs(self.children) do
		child.sprite = sprite
	end
end

function TLHeader:onSpriteDeselected()
	self.sprite = nil
	self.spriteState = nil

	for _, child in ipairs(self.children) do
		child.sprite = nil
	end
end

function TLHeader:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

	-- The background
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	-- The buttons
	local oldW = self.w
	self.w = self.splitX
	TLHeader.super.draw(self)
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
	local activeFrameIndex = state.frame:get()
	local hoveringFrameIndex = self.hoveringFrameIndex
	local pressingFrameIndex = self.pressingFrameIndex
	local hovering = self.hovering
	local pressing = self.pressing

	love.graphics.setFont(defaultFont)
	for x = self._lowerX, math.min(#sprite.frames, self._upperX) do
		if x == activeFrameIndex then
			love.graphics.setColor(0.3, 0.3, 0.5)
		else
			if hovering and x == hoveringFrameIndex then
				if pressing then
					if x == pressingFrameIndex then
						-- Is pressing the same thing originally
						love.graphics.setColor(0.1, 0.1, 0.2)
					end
				else
					-- Just hovering, not pressing anything
					love.graphics.setColor(0.25, 0.25, 0.5)
				end
			else
				-- Nothing
				love.graphics.setColor(0.2, 0.2, 0.4)
			end
		end

		if hovering and x == hoveringFrameIndex then
			if pressing then
				if x == pressingFrameIndex then
					-- Is pressing the same thing originally
					love.graphics.setColor(0.1, 0.1, 0.2)
				end
			else
				-- Just hovering, not pressing anything
				love.graphics.setColor(0.45, 0.45, 0.5)
			end
		end

		local cx, cy = startX + (x - 1) * celSize, self.y
		backgroundNP:draw(cx, cy, celSize, celSize, 2)
		love.graphics.setColor(1, 1, 1)
		---@type string
		local string
		if x < 10 then
			string = tostring(x)
		else
			string = ("%02d"):format(x % 100)
		end
		love.graphics.print(string, cx + (celSize - defaultFont:getWidth(string)) * 0.5, cy + textYStart)
	end

	-- Reset the scissor
	love.graphics.setScissor(ox, oy, ow, oh)
end

return TLHeader
