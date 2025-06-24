-- TODO: This script is mostly a copy/paste of popupmenu, unify them

local Plan = require "lib.plan"
local Popup = require "ui.components.containers.modals.popup"
local Fonts = require "src.global.fonts"
local Luvent = require "lib.luvent"
local Contexts = require "src.global.contexts"
local Context = require "src.data.context"
local Action = require "src.data.action"

local defaultFont = Fonts.getDefaultFont()

---@class Dropdown: Popup
local Dropdown = Popup:extend()
Dropdown.CLASS_NAME = "Dropdown"

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
local DropdownContext = Context(actions, defaultKeybinds)
DropdownContext.sinkAllEvents = true

---@param rules Plan.Rules
---@param property EnumProperty
---@param minWidth integer?
function Dropdown:new(rules, property, minWidth)
	Dropdown.super.new(self, rules)
	---@type EnumProperty.Option[]
	self.items = property.options

	self._minWidth = padding * 2
	self._minHeight = padding * 2
	---@type integer
	self.requestedMinWidth = minWidth or 0

	---@type ContextRef
	self._menuContext = nil

	---@type EnumProperty
	self.property = property
	if property then
		self:bindToProperty(property)
	end
end

---@param property EnumProperty
function Dropdown:bindToProperty(property)
	self:setItems(property.options)
end

---Sets the items in this PopupMenu
---@param items EnumProperty.Option[]
function Dropdown:setItems(items)
	local largestWidth = 0

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

function Dropdown:getDesiredDimensions()
	return math.max(self._minWidth, self.requestedMinWidth), self._minHeight
end

function Dropdown:refresh()
	self.w, self.h =
		math.max(self._minWidth, self.requestedMinWidth),
		self._minHeight
	Dropdown.super.refresh(self)
end

function Dropdown:mousemoved(_, my)
	local py = self.y
	local ry = my - py
	self.hoveredIndex = math.floor((ry - padding) / (defaultFont:getHeight() + margin)) + 1
end

function Dropdown:pointerentered()
	self.hovering = true
end

function Dropdown:pointerexited()
	self.hovering = false
	self.hoveredIndex = 0
end

function Dropdown:mousepressed()
	self.pressing = true
end

function Dropdown:mousereleased()
	local option = self.items[self.hoveredIndex]
	if self.pressing and option and option.name ~= "" then
		self:close()
		self.property:set(option)
		self.hoveredIndex = 0
		self.hovering = false
	end
	self.pressing = false
end

function Dropdown:modaldraw()
	--- Background
	love.graphics.setColor(0.15, 0.15, 0.3)
	local px, py, pw, ph = self.x, self.y, self.w, self.h
	love.graphics.rectangle("fill", px, py, pw, ph, 4, 4)

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
			love.graphics.rectangle("fill", px, py + padding + (i - 1) * (textHeight + margin) - margin * 0.5, pw, textHeight + margin)
			love.graphics.setColor(1, 1, 1)
		end

		love.graphics.print(label, defaultFont, px + padding, py + padding + (i - 1) * (textHeight + margin))
	end
end

function Dropdown:popup()
	self._menuContext = DropdownContext:asReference()
	self._menuContext["%presenter"] = self
	Contexts.pushContext(self._menuContext)
	Dropdown.super.popup(self)
end

function Dropdown:close()
	Contexts.popContext(self._menuContext)
	self._menuContext = nil
	Dropdown.super.close(self)
end

function Dropdown:outofbounds(event, ...)
	if event == "mousereleased" then
		self.pressing = false
	else
		Dropdown.super.outofbounds(self, event, ...)
	end
end

return Dropdown
