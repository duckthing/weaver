local Plan = require "lib.plan"
local HScroll = require "ui.components.containers.box.hscroll"
local LabelButton = require "ui.components.button.labelbutton"
local PopupMenu = require "ui.components.containers.modals.popupmenu"

---@class Toolbar: HScroll
local Toolbar = HScroll:extend()

---@class Toolbar.Button: LabelButton
local ToolbarButton = LabelButton:extend()

---@param self Toolbar.Button
local function toggleButton(self)
	self.popupMenu:popup()
end

---@param rules Plan.Rules
---@param items Toolbar.Item
---@param context Action.Context?
function ToolbarButton:new(rules, items, context)
	ToolbarButton.super.new(self, rules, toggleButton)
	self.paddingX = 24
	---@type Toolbar.Item
	self.menuItem = items

	---@type PopupMenu
	self.popupMenu = PopupMenu(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.relative(1))
			:addWidth(Plan.keep())
			:addHeight(Plan.keep()),
		items.items,
		nil,
		context
	)
	self:addChild(self.popupMenu)

	self:setLabel(items.name)
end

function ToolbarButton:draw()
	if self.popupMenu.isPoppedUp then
		love.graphics.setColor(0.12, 0.12, 0.25)
	elseif self.hovering then
		love.graphics.setColor(0.3, 0.3, 0.5)
	else
		love.graphics.setColor(0.2, 0.2, 0.4)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self._textObj, self._offsetX, self._offsetY)
end

---@class Toolbar.Item
---@field name string
---@field items Action[]

function Toolbar:new(rules, items)
	Toolbar.super.new(self, rules)
	self.padding = 0
	self.margin = 0

	---@type Toolbar.Item[]
	self.toolbarItems = items or {}
	self:setItems(self.toolbarItems)
end

---Sets the items of this Toolbar
---@param items Toolbar.Item[]
---@param context table?
function Toolbar:setItems(items, context)
	self:clearChildren(true)
	for _, item in ipairs(items) do
		local child = ToolbarButton(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.keep())
				:addHeight(Plan.parent()),
			item,
			context
		)
		self:addChild(child)
	end
end

function Toolbar:draw()
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	Toolbar.super.draw(self)
end

return Toolbar
