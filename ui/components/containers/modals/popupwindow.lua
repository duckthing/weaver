local Plan = require "lib.plan"
local Luvent = require "lib.luvent"
local Popup = require "ui.components.containers.modals.popup"
local LabelButton = require "ui.components.button.labelbutton"
local NinePatch = require "src.ninepatch"
local VBox = require "ui.components.containers.box.vbox"
local HBox = require "ui.components.containers.box.hbox"
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

---@class PopupWindow: Popup
local PopupWindow = Popup:extend()

---@type Keybinds.ActionsMap
local keybindActions = {
	popup_close = Action(
		"Close window",
		function (action, source, presenter, context)
			context.presenter:close()
		end
	),
	popup_accept = Action(
		"Accept",
		function (_, source, _, context)
			---@type PopupWindow
			local presenter = context.presenter

			-- It's intentional that we're going through buttons instead of the Actions
			-- Basically, buttons wrap the Action
			for _, button in ipairs(presenter._actionButtons) do
				---@type Action?
				local action = button.action
				if action and action:getType() == "accept" then
					button:onClick()
					return
				end
			end
		end
	)
}

---@type Keybinds.KeyCombinations
local defaultKeybinds = {
	normal = {
		escape = "popup_close",
		["return"] = "popup_accept",
	}
}

---@type Context
local PopupWindowContext = Context(keybindActions, defaultKeybinds)
PopupWindowContext.CONTEXT_NAME = "PopupWindow"
PopupWindowContext.sinkAllEvents = true
PopupWindowContext.keybinds:resetToDefault()

---@type Action[]
PopupWindow.DEFAULT_ACTIONS = {
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

---@class PopupWindow.Titlebar: Plan.Container
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

---@class PopupWindow.ActionsBar: HFlex
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

---@class PopupWindow.Content: Plan.Container
local ContentContainer = Plan.Container:extend()

function ContentContainer:draw()
	-- self.x = self.x + 2
	-- self.w = self.w - 4
	-- self.h = self.h - 2
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x - BORDER_SIZE + 2, self.y, self.w + BORDER_SIZE * 2 - 4, self.h - 2)
	love.graphics.setColor(1, 1, 1)
	ContentContainer.super.draw(self)
	-- self.x = self.x - 2
	-- self.w = self.w + 4
	-- self.h = self.h + 2
	contentNP:draw(self.x - BORDER_SIZE, self.y, self.w + BORDER_SIZE * 2, self.h, 2)
end

---@param rules Plan.Rules
---@param actions Action[]?
---@param title string?
function PopupWindow:new(rules, actions, title)
	PopupWindow.super.new(self, rules)
	---@type VBox
	self._styleContainer = VBox(Plan.RuleFactory.full())
	self:intAddChild(self._styleContainer)
	---@type PopupWindow.Titlebar
	self.titlebar = Titlebar(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(TITLEBAR_SIZE)),
		title
	)
	---@type PopupWindow.Content
	self.container = ContentContainer(
		Plan.Rules.new()
			:addX(Plan.pixel(BORDER_SIZE))
			:addY(Plan.keep())
			:addWidth(Plan.max(BORDER_SIZE * 2))
			:addHeight(Plan.max(TITLEBAR_SIZE + ACTIONSBAR_SIZE))
	)
	---@type PopupWindow.ActionsBar
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
	self:setActions(actions or PopupWindow.DEFAULT_ACTIONS)
end

---Sets the actions that appear on the bottom
---@param actions Action[]?
---@param source any
---@param context Action.Context?
function PopupWindow:setActions(actions, source, context)
	self.actions = actions or {}

	-- Remove the already existing buttons
	for _, button in ipairs(self._actionButtons) do
		self.actionsbar:removeChild(button, true)
	end

	-- The callback ran when any button is clicked
	local callback = function(button)
		if button.action then
			if button.action:run(source, self, context) then
				self:close()
			end
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

	self:refresh()
end

---Sets the title of this PopupWindow
---@param title string?
function PopupWindow:setTitle(title)
	self.titlebar.label:setText(title or "")
end

function PopupWindow:addChild(child, atIndex)
	self.container:addChild(child, atIndex)
end

function PopupWindow:removeChild(child)
	self.container:removeChild(child)
end

function PopupWindow:clearChildren(...)
	self._styleContainer:clearChildren(...)
end

---Adds a child directly to this PopupWindow, instead of the inner container
---@param child Plan.Container
---@param atIndex integer?
function PopupWindow:intAddChild(child, atIndex)
	PopupWindow.super.addChild(self, child, atIndex)
end

---Removes a child directly to this PopupWindow, instead of the inner container
---@param child Plan.Container
function PopupWindow:intRemoveChild(child)
	PopupWindow.super.removeChild(self, child)
end

--- Merges all toolbar actions
---@param allCollections Action[][]
function PopupWindow:mergeActions(allCollections)
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

function PopupWindow:popup()
	self._windowContext = PopupWindowContext:asReference()
	self._windowContext["%presenter"] = self
	Contexts.pushContext(self._windowContext)
	PopupWindow.super.popup(self)
end

function PopupWindow:close()
	Contexts.popContext(self._windowContext)
	self._windowContext = nil
	PopupWindow.super.close(self)
end

return PopupWindow
