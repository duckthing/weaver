local Plan = require "lib.plan"
local Popup = require "ui.components.containers.modals.popup"
local Window = require "ui.components.containers.window"
local LabelButton = require "ui.components.button.labelbutton"
local NinePatch = require "src.ninepatch"
local VBox = require "ui.components.containers.box.vbox"
local HFlex = require "ui.components.containers.flex.hflex"
local Label = require "ui.components.text.label"
local Contexts = require "src.global.contexts"
local Context = require "src.data.context"
local Action = require "src.data.action"

---@class PopupWindow: Popup
---@overload fun(rules: Plan.Rules, actions: Action[]?, title: string?): PopupWindow
local PopupWindow = Popup:extend()
PopupWindow.CLASS_NAME = "PopupWindow"

---@type Keybinds.ActionsMap
local keybindActions = {
	popup_close = Action(
		"Close Window",
		function (_, source, _, context)
			context.presenter:close()
		end
	),
	popup_accept = Action(
		"Accept",
		function (_, source, _, context)
			---@type Window
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

---@param rules Plan.Rules
---@param actions Action[]?
---@param title string?
function PopupWindow:new(rules, actions, title)
	PopupWindow.super.new(self, rules)

	local window = Window(Plan.RuleFactory.full(), actions, title)
	self.window = window
	window.close = function(w)
		Window.close(w)
		self:close()
	end
	self:intAddChild(window)
end

---Sets the actions that appear on the bottom
---@param actions Action[]?
---@param source any
---@param context Action.Context?
function PopupWindow:setActions(actions, source, context)
	local window = self.window
	window:setActions(actions, source, context)
	self:refresh()
end

---Sets the title of this PopupWindow
---@param title string?
function PopupWindow:setTitle(title)
	self.window:setTitle(title or "")
end

function PopupWindow:addChild(child, atIndex)
	self.window:addChild(child, atIndex)
end

function PopupWindow:removeChild(child)
	self.window:removeChild(child)
end

function PopupWindow:clearChildren(...)
	self.window:clearChildren(...)
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

	self.window.mergedActions = mergedItems
	return mergedItems
end

function PopupWindow:popup()
	self._windowContext = PopupWindowContext:asReference()
	self._windowContext["%presenter"] = self.window
	self.window._active = true
	Contexts.pushContext(self._windowContext)
	PopupWindow.super.popup(self)
end

function PopupWindow:close()
	Contexts.popContext(self._windowContext)
	self._windowContext = nil
	self.window._active = false
	PopupWindow.super.close(self)
end

return PopupWindow
