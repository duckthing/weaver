local Resources = require "src.global.resources"
local Plan = require "lib.plan"
local HScroll = require "ui.components.containers.box.hscroll"
local BaseButton = require "ui.components.button.basebutton"
local NinePatch = require "src.ninepatch"
local SpriteSheet = require "src.spritesheet"
local Label = require "ui.components.text.label"

---@type love.Image
local resourceIconTexture = love.graphics.newImage("assets/resource_icons.png")
resourceIconTexture:setFilter("nearest", "nearest")

---@type love.Image
local tabTexture = love.graphics.newImage("assets/tab.png")
tabTexture:setFilter("nearest", "nearest")

local tabNP = NinePatch.new(3, 1, 3, 3, 1, 3, tabTexture)
local iconSheet = SpriteSheet.new(resourceIconTexture, 8, 1)

local closeButtonIcon = love.graphics.newImage("assets/close_button.png")
closeButtonIcon:setFilter("nearest", "nearest")

---@class TabButton.CloseTab: BaseButton
local CloseTabButton = BaseButton:extend()
CloseTabButton.CLASS_NAME = "CloseTabButton"

---@param self TabButton.CloseTab
local function onCloseTabButtonPressed(self)
	Resources.removeResource(self.resourceID)
end

function CloseTabButton:new(rules, resource)
	CloseTabButton.super.new(self, rules, onCloseTabButtonPressed)
	self.resourceID = resource.id
end

function CloseTabButton:draw()
	if self.hovering then
		love.graphics.setColor(0.6, 0.6, 0.6, 0.1)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
		if self.pressing then
			love.graphics.setColor(0.5, 0.2, 0.2)
		else
			love.graphics.setColor(0.9, 0.6, 0.6)
		end
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(closeButtonIcon, self.x + self.w * 0.5 - 7, self.y + self.h * 0.5 - 7, 0, 2, 2)
end

local closeTabRules = Plan.Rules.new()
	:addX(Plan.max(30))
	:addY(Plan.pixel(0))
	:addWidth(Plan.pixel(30))
	:addHeight(Plan.parent())

---@class TabButton: BaseButton
local TabButton = BaseButton:extend()
TabButton.CLASS_NAME = "TabButton"

---@param self TabButton
local function onTabButtonClicked(self)
	Resources.selectResourceId(self.resourceID)
end

local labelRules = Plan.Rules.new()
	:addX(Plan.pixel(30))
	:addY(Plan.pixel(0))
	:addWidth(Plan.max(60))
	:addHeight(Plan.parent())

---@param rules Plan.Rules
---@param resource Resource
function TabButton:new(rules, resource)
	TabButton.super.new(self, rules, onTabButtonClicked)
	self.resource = resource
	self.resourceID = resource.id
	---@type Label
	self.label = Label(
		labelRules,
		resource.name:get()
	)
	self:addChild(self.label)
	self.selected = false

	if resource.TYPE == "home" then
		self.iconIndex = 1
	elseif resource.TYPE == "sprite" then
		self.iconIndex = 4
	else
		self.iconIndex = 2
	end

	---@type TabButton.CloseTab
	self.closeButton = CloseTabButton(closeTabRules, resource)
	self:addChild(self.closeButton)

	-- When the Resource name changes
	self._nameChangedAction = resource.name.valueChanged:addAction(function(property, newName)
		if resource.modified:get() then
			-- Modified, add the * thing
			newName = "*"..newName
		end

		self.label:setText(newName)
	end)

	-- When the Resource is modified
	self._modifiedAction = resource.modified.valueChanged:addAction(function(property, isModified)
		if isModified then
			self.label:setText("*"..resource.name:get())
		else
			self.label:setText(resource.name:get())
		end
	end)
end

function TabButton:draw()
	local isTextBright = true
	if self.pressing then
		love.graphics.setColor(0.1, 0.1, 0.2)
	elseif self.hovering then
		love.graphics.setColor(0.38, 0.38, 0.65)
	elseif self.selected then
		love.graphics.setColor(0.3, 0.3, 0.6)
	else
		isTextBright = false
		love.graphics.setColor(0.15, 0.15, 0.3)
	end

	tabNP:draw(self.x, self.y, self.w, self.h, 2)

	if isTextBright then
		love.graphics.setColor(1, 1, 1)
	else
		love.graphics.setColor(0.6, 0.6, 0.6)
	end
	iconSheet:draw(self.iconIndex, self.x + 5, self.y + 5, 2, 2)

	if self.selected or self.hovering or self.closeButton.hovering then
		self.closeButton:enable()
		self.closeButton:draw()
	else
		self.closeButton:disable()
	end

	self.label:draw()
end

function TabButton:onRemovedFromParent()
	self.resource.name.valueChanged:removeAction(self._nameChangedAction)
	self.resource.modified.valueChanged:removeAction(self._modifiedAction)
	self._nameChangedAction = nil
	self._modifiedAction = nil
end

---@class Bufferline: HScroll
local Bufferline = HScroll:extend()

---@param rules Plan.Rules
function Bufferline:new(rules)
	Bufferline.super.new(self, rules)
	self.padding = 12
	self.margin = 6
	-- Create the tab buttons
	Resources.onNewResource:addAction(function(newResource)
		self:addChild(TabButton(
			Plan.Rules:new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.pixel(150))
				:addHeight(Plan.parent()),
			newResource)
		)
	end)
	-- Remove the tab buttons
	Resources.onResourceRemoved:addAction(function(removedBuffer)
		local removedID = removedBuffer.id
		for i = 1, #self.children do
			local child = self.children[i]
			---@cast child TabButton
			if child.resourceID == removedID then
				self:removeChild(child)
				break
			end
		end
	end)
	-- Change the highlights on the tab
	Resources.onResourceSelected:addAction(function (selectedResource)
		-- TODO: Make less hacky
		local selectedID = (selectedResource and selectedResource.id) or 0
		for i = 1, #self.children do
			local child = self.children[i]
			---@cast child TabButton
			child.selected = child.resourceID == selectedID
		end
	end)
end

function Bufferline:draw()
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	Bufferline.super.draw(self)
end

return Bufferline
