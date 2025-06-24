local Popup = require "ui.components.containers.modals.popup"
local Fonts = require "src.global.fonts"
local Luvent = require "lib.luvent"
local Contexts = require "src.global.contexts"
local Context = require "src.data.context"
local Action = require "src.data.action"

local defaultFont = Fonts.getDefaultFont()

---@class PopupMenu: Popup
local PopupMenu = Popup:extend()
PopupMenu.CLASS_NAME = "PopupMenu"

local padding = 10
local margin = 8

---@type Keybinds.ActionsMap
local actions = {
	popup_close = Action(
		"Close popup",
		function (action, source, presenter, context)
			context.presenter:close()
		end
	)
}

---@type Keybinds.KeyCombinations
local defaultKeybinds = {
	normal = {
		escape = "popup_close"
	}
}

---@type Context
local PopupMenuContext = Context(actions, defaultKeybinds)
PopupMenuContext.sinkAllEvents = true
PopupMenuContext.keybinds:resetToDefault()

---@param rules Plan.Rules
---@param items Action[]?
---@param source any
---@param context Action.Context?
function PopupMenu:new(rules, items, source, context)
	PopupMenu.super.new(self, rules)
	---@type string
	self.name = "Menu"
	---@type Action[]
	self.items = items or {}

	self.itemSelected = Luvent.newEvent()
	self._minWidth = padding * 2
	self._minHeight = padding * 2

	---@type ContextRef
	self._menuContext = nil

	if items then
		self:setItems(items, source, context)
	end
end

---Sets the items in this PopupMenu
---@param items Action[]
---@param source any
---@param context Action.Context?
function PopupMenu:setItems(items, source, context)
	local largestWidth = 0
	self.source = source
	self.context = context

	for _, item in ipairs(items) do
		local currWidth = defaultFont:getWidth(item.name)
		if currWidth > largestWidth then
			largestWidth = currWidth
		end
	end

	self._minWidth = largestWidth + padding * 2
	self._minHeight = math.max(0, #items - 1) * margin + padding * 2 + #items * defaultFont:getHeight()
	self.items = items
	---@type integer
	self.hoveredIndex = 4
	self.hovering = false
end

function PopupMenu:getDesiredDimensions()
	return self._minWidth, self._minHeight
end

function PopupMenu:refresh()
	self.w, self.h = self._minWidth, self._minHeight
	PopupMenu.super.refresh(self)
end

function PopupMenu:mousemoved(_, my)
	local py = self.y
	local ry = my - py
	self.hoveredIndex = math.floor((ry - padding) / (defaultFont:getHeight() + margin)) + 1
end

function PopupMenu:pointerentered()
	self.hovering = true
end

function PopupMenu:pointerexited()
	self.hovering = false
	self.hoveredIndex = 0
end

function PopupMenu:mousepressed()
	self.pressing = true
end

function PopupMenu:mousereleased()
	local item = self.items[self.hoveredIndex]
	if self.pressing and item and item.name ~= "" then
		self:close()
		item:run(self.source, self, self.context)
		self.itemSelected:trigger(item)
		self.hoveredIndex = 0
		self.hovering = false
	end
	self.pressing = false
end

function PopupMenu:modaldraw()
	--- Background
	love.graphics.setColor(0.15, 0.15, 0.3)
	local px, py, pw, ph = self.x, self.y, self.w, self.h
	love.graphics.rectangle("fill", px, py, self._minWidth, self._minHeight, 4, 4)

	love.graphics.setColor(1, 1, 1)
	local textHeight = defaultFont:getHeight()
	for i, item in ipairs(self.items) do
		local label = item.name
		if i == self.hoveredIndex and label ~= "" then
			if self.pressing then
				love.graphics.setColor(0.12, 0.12, 0.24)
			else
				love.graphics.setColor(0.25, 0.25, 0.5)
			end
			love.graphics.rectangle("fill", px, py + padding + (i - 1) * (textHeight + margin) - margin * 0.5, self.w, textHeight + margin)
			love.graphics.setColor(1, 1, 1)
		end

		love.graphics.print(label, defaultFont, px + padding, py + padding + (i - 1) * (textHeight + margin))
	end
end

function PopupMenu:popup()
	self._menuContext = PopupMenuContext:asReference()
	self._menuContext["%presenter"] = self
	Contexts.pushContext(self._menuContext)
	PopupMenu.super.popup(self)
end

function PopupMenu:close()
	Contexts.popContext(self._menuContext)
	self._menuContext = nil
	PopupMenu.super.close(self)
end

function PopupMenu:outofbounds(event, ...)
	if event == "mousereleased" then
		self.pressing = false
	else
		PopupMenu.super.outofbounds(self, event, ...)
	end
end

return PopupMenu
