local Plan = require "lib.plan"
local Property = require "src.properties.property"
local Label = require "ui.components.text.label"
local Range = require "src.data.range"
local HBox = require "ui.components.containers.box.hbox"
local Button = require "ui.components.button.button"
local Slidebox = require "ui.components.range.slidebox"
local Brush = require "plugins.sprite.brush.brush"
local CircleBrush = require "plugins.sprite.brush.circlebrush"
local SquareBrush = require "plugins.sprite.brush.squarebrush"
local HFlex = require "ui.components.containers.flex.hflex"
local Modal = require "src.global.modal"
local EnumProperty = require "src.properties.enum"

---@class Brush.Button: Button
local BrushButton = Button:extend()

---@class BrushProperty: Property
local BrushProperty = Property:extend()
BrushProperty.type = "brush"

---@type EnumProperty.Option[]
local options = {
	{
		name = "Circle",
		value = CircleBrush(),
	},
	{
		name = "Square",
		value = SquareBrush(),
	},
}

---@type EnumProperty
local brushSelection = EnumProperty(BrushProperty, "Selection", "Circle")
brushSelection:setOptions(options)
brushSelection.value = nil -- Force an update when set

function BrushProperty:new(...)
	BrushProperty.super.new(self, ...)
	---@type Brush
	self.value = options[1].value

	brushSelection.valueChanged:addAction(function(_, newBrush)
		brushSelection.value = nil
		self:set(newBrush.value)
	end)
end

---Returns the value
---@return Brush
function BrushProperty:get()
	return self.value
end

---Sets the value of the property
---@param value Brush
function BrushProperty:set(value)
	if value ~= self.value then
		self.value = value
		self.valueChanged:trigger(self, value)
	end
end

---Adds a Brush to the dropdown, or overwrites an existing one
---@param brush Brush
---@param name string
function BrushProperty.addBrush(brush, name)
	for _, v in ipairs(options) do
		if v.name == name then
			v.value = brush
			return
		end
	end

	-- Add it, since it doesn't exist
	options[#options+1] = {
		name = name,
		value = brush,
	}
end

---@class BrushProperty.HElement: HBox
local BrushHElement = HBox:extend()

---@param rules Plan.Rules
---@param property BrushProperty
function BrushButton:new(rules, property)
	BrushButton.super.new(self, rules)
	self.onClick = function()
		Modal.pushDropdown(self.x, self.y + self.h, brushSelection)
	end

	---@type BrushProperty
	self.property = property

	-- Where the brush is drawn (updated on change)
	---@type integer, integer
	self.imageX, self.imageY = 0, 0

	property:get().brushDataChanged:addAction(function()
		self:updateImagePosition()
	end)

	---@param brush Brush
	property.valueChanged:addAction(function(_, brush)
		brush.brushDataChanged:addAction(function()
			self:updateImagePosition()
		end)
	end)
end

local PADDING = 6
function BrushButton:draw()
	BrushButton.super.draw(self)
	local x, y, w, h = self.x, self.y, self.w, self.h
	if w - PADDING * 2 < 0 or h - PADDING * 2 < 0 then return end

	local sx, sy, sw, sh = love.graphics.getScissor()
	love.graphics.intersectScissor(x + PADDING, y + PADDING, w - PADDING * 2, h - PADDING * 2)

	local brush = self.property:get()
	brush:draw(self.imageX + brush.offsetX, self.imageY + brush.offsetY)

	love.graphics.setScissor(sx, sy, sw, sh)
end

function BrushButton:updateImagePosition()
	local brush = self.property:get()
	local bw, bh = brush.w, brush.h
	local x, y, w, h = self.x, self.y, self.w, self.h
	local centerX, centerY = x + w * 0.5, y + h * 0.5
	self.imageX, self.imageY =
		math.floor(centerX - bw * 0.5),
		math.floor(centerY - bh * 0.5)
end

function BrushButton:refresh()
	BrushButton.super.refresh(self)
	self:updateImagePosition()
end

---@type Plan.Rules
local FULL_SPACE = Plan.RuleFactory.full()
---@type string
local FORMAT_TEXT = "%s: %d"
---@type integer
local DEFAULT_WIDTH = 150

---@param rules Plan.Rules
---@param property BrushProperty
function BrushHElement:new(rules, property)
	BrushHElement.super.new(self, rules)
	self.margin = 6
	---@type BrushProperty
	self.property = property
	---@type Button
	self.button = BrushButton(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(4))
			:addWidth(Plan.aspect(1))
			:addHeight(Plan.max(8)),
		property
	)
	self:addChild(self.button)

	local function onInspectablesChanged()
		for i = #self.children, 1, -1 do
			local child = self.children[i]
			if child ~= self.button then
				self:removeChild(child)
			end
		end

		for _, p in ipairs(property.value:getProperties()) do
			self:addChild(p:getHElement())
		end

		self.w = self._containerSize
		self:bubble("_bubbleSizeChanged")
	end

	onInspectablesChanged()
	self._brushInspectablesChanged = property:get().inspectablesChanged:addAction(onInspectablesChanged)

	local oldBrush = property:get()
	property.valueChanged:addAction(function(_, newBrush)
		oldBrush.inspectablesChanged:removeAction(self._brushInspectablesChanged)
		self._brushInspectablesChanged = newBrush.inspectablesChanged:addAction(onInspectablesChanged)
		oldBrush = newBrush
		onInspectablesChanged()
	end)
end

function BrushHElement:sort()
	---@diagnostic disable-next-line
	BrushHElement.super.sort(self)
	self.w = self._containerSize
	self._upperCull = #self.children
end

function BrushProperty:getHElement()
	return BrushHElement(Plan.Rules.new()
		:addX(Plan.keep())
		:addY(Plan.pixel(0))
		:addWidth(Plan.keep())
		:addHeight(Plan.parent()),
		self
	)
end

return BrushProperty
