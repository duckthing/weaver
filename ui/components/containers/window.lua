local Plan = require "lib.plan"
local LabelButton = require "ui.components.button.labelbutton"
local NinePatch = require "src.ninepatch"
local VBox = require "ui.components.containers.box.vbox"
local HFlex = require "ui.components.containers.flex.hflex"
local Label = require "ui.components.text.label"
local Contexts = require "src.global.contexts"
local Context = require "src.data.context"
local Action = require "src.data.action"

local titlebarTexture = love.graphics.newImage("assets/panel/panel_titlebar.png")
local contentTexture = love.graphics.newImage("assets/panel/panel_content.png")
titlebarTexture:setFilter("nearest")
contentTexture:setFilter("nearest")

local titlebarNP = NinePatch.new(3, 1, 3, 3, 1, 3, titlebarTexture)
local contentNP = NinePatch.new(2, 1, 2, 1, 1, 2, contentTexture)

---@class Window: Plan.Container
---@overload fun(rules: Plan.Rules, actions: Action[]?, title: string?): Window
local Window = Plan.Container:extend()
Window.CLASS_NAME = "Window"

---@type Action[]
Window.DEFAULT_ACTIONS = {
	Action(
		"Close",
		function ()
			return true
		end
	):setType("close")
}

local TITLEBAR_SIZE = 26
local ACTIONSBAR_SIZE = 30
local BORDER_SIZE = 8

---@class Window.Titlebar: Plan.Container
local Titlebar = Plan.Container:extend()

function Titlebar:new(rules, text)
	Titlebar.super.new(self, rules)
	---@type Label
	self.label = Label(
		Plan.RuleFactory.full(),
		text
	)
	self.label:setPadding(8)
	self:addChild(self.label)
end

function Titlebar:draw()
	love.graphics.setColor(1, 1, 1)
	titlebarNP:draw(self.x, self.y, self.w, self.h, 2)
	Titlebar.super.draw(self)
end

---@class Window.ActionsBar: HFlex
local ActionsBar = HFlex:extend()

function ActionsBar:new(rules)
	ActionsBar.super.new(self, rules)
	self.justify = "spacebetween"
	self.padding = 4
end

function ActionsBar:draw()
	love.graphics.setColor(0.3, 0.3, 0.6)
	love.graphics.rectangle("fill", self.x + 2, self.y, self.w - 4, self.h - 2)
	love.graphics.setColor(1, 1, 1)
	contentNP:draw(self.x, self.y, self.w, self.h, 2)
	ActionsBar.super.draw(self)
end

---@class Window.Content: Plan.Container
local ContentContainer = Plan.Container:extend()

function ContentContainer:draw()
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x - BORDER_SIZE + 2, self.y, self.w + BORDER_SIZE * 2 - 4, self.h - 2)
	love.graphics.setColor(1, 1, 1)
	ContentContainer.super.draw(self)
	contentNP:draw(self.x - BORDER_SIZE, self.y, self.w + BORDER_SIZE * 2, self.h, 2)
end

---@param rules Plan.Rules
---@param actions Action[]?
---@param title string?
function Window:new(rules, actions, title)
	Window.super.new(self, rules)
	---@type VBox
	self._styleContainer = VBox(Plan.RuleFactory.full())
	self:intAddChild(self._styleContainer)
	---@type Window.Titlebar
	self.titlebar = Titlebar(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(TITLEBAR_SIZE)),
		title
	)
	---@type Window.Content
	self.container = ContentContainer(
		Plan.Rules.new()
			:addX(Plan.pixel(BORDER_SIZE))
			:addY(Plan.keep())
			:addWidth(Plan.max(BORDER_SIZE * 2))
			:addHeight(Plan.max(TITLEBAR_SIZE + ACTIONSBAR_SIZE))
	)
	---@type Window.ActionsBar
	self.actionsbar = ActionsBar(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(ACTIONSBAR_SIZE))
	)
	self._styleContainer:addChild(self.titlebar)
	self._styleContainer:addChild(self.container)
	self._styleContainer:addChild(self.actionsbar)

	---@type ContextRef
	self._windowContext = nil
	---@type Button[]
	self._actionButtons = {}
	---@type Action[]
	self.actions = nil
	self:setActions(actions or Window.DEFAULT_ACTIONS)
end

---Sets the actions that appear on the bottom
---@param actions Action[]?
---@param source any
---@param context Action.Context?
function Window:setActions(actions, source, context)
	self.actions = actions or {}

	-- Remove the already existing buttons
	for _, button in ipairs(self._actionButtons) do
		self.actionsbar:removeChild(button, true)
	end

	-- The callback ran when any button is clicked
	local callback = function(button)
		if button.action then
			button.action:run(source, self, context)
		end
	end

	-- Create all the buttons for the bar
	self._actionButtons = {}
	for _, action in ipairs(self.actions) do
		local button = LabelButton(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(3))
				:addWidth(Plan.keep())
				:addHeight(Plan.pixel(22)),
			callback,
			action.name
		)
		button.action = action
		self.actionsbar:addChild(button)
		self._actionButtons[#self._actionButtons+1] = button
	end

	if self._inUITree then
		self:refresh()
	end
end

---Sets the title of this PopupWindow
---@param title string?
function Window:setTitle(title)
	self.titlebar.label:setText(title or "")
end

function Window:addChild(child, atIndex)
	self.container:addChild(child, atIndex)
end

function Window:removeChild(child)
	self.container:removeChild(child)
end

function Window:clearChildren(...)
	self._styleContainer:clearChildren(...)
end

---Adds a child directly to this PopupWindow, instead of the inner container
---@param child Plan.Container
---@param atIndex integer?
function Window:intAddChild(child, atIndex)
	Window.super.addChild(self, child, atIndex)
end

---Removes a child directly to this PopupWindow, instead of the inner container
---@param child Plan.Container
function Window:intRemoveChild(child)
	Window.super.removeChild(self, child)
end

---Merges all toolbar actions
---@param allCollections Action[][]
function Window:mergeActions(allCollections)
	---@type Action[]
	local mergedItems = {}
	---@type {[string]: integer}
	local nameMap = {}

	for _, popupActions in ipairs(allCollections) do
		for _, action in ipairs(popupActions) do
			local mergedIndex = nameMap[action.name]
			if not mergedIndex then
				mergedIndex = #mergedItems + 1
				nameMap[action.name] = mergedIndex
			end

			mergedItems[mergedIndex] = action
		end
	end

	self.mergedActions = mergedItems
	return mergedItems
end

function Window:close()
	self._active = false
end

return Window
