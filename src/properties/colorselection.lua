local Plan = require "lib.plan"
local IconButton = require "ui.components.button.iconbutton"
local VBox = require "ui.components.containers.box.vbox"
local HBox = require "ui.components.containers.box.hbox"
local Label = require "ui.components.text.label"
local Modal = require "src.global.modal"
local ColorSelectModal = require "ui.components.containers.modals.colorselect"
local ColorProperty = require "src.properties.color"
local SpriteSheet = require "src.spritesheet"

local HexEdit = ColorSelectModal.HexEdit

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class ColorSelectionProperty: ColorProperty
local ColorSelectionProperty = ColorProperty:extend()

function ColorSelectionProperty:new(object, name, value)
	ColorSelectionProperty.super.new(self, object, name, value)
	---@type Palette.Color
	self.color = value
	---@type integer
	self.index = 0
	---@type Palette?
	self.palette = nil
	---@type integer
	self.defaultIndex = 1
end

function ColorSelectionProperty:deserialize(data)
	if type(data) == "table" then
		self:userSetColor(data[1], data[2], data[3])
	end
end

function ColorSelectionProperty:triggerValueChanged()
	self.valueChanged:trigger(self, self.color, self.index)
end

---Sets this color, and follows locked palette rules. Make sure these are in the range of 0..1.
---@param r number
---@param g number
---@param b number
function ColorSelectionProperty:userSetColor(r, g, b)
	local palette = self.palette

	r = math.max(0, math.min(r, 1))
	g = math.max(0, math.min(g, 1))
	b = math.max(0, math.min(b, 1))

	if (palette and not palette.locked) or self:getIndex() == 0 then
		-- Edit the current color, which may be in the palette
		local color = self:getColor()
		color[1], color[2], color[3] = r, g, b
		self:triggerValueChanged()
	else
		-- Locked, doesn't exist, or is outside of the palette, create a new color object instead
		self:setColorByValue({r, g, b})
	end
end

---Finds the index of the color in the palette and sets it to that or nil
---@param color Palette.Color
function ColorSelectionProperty:findIndexAndSetColor(color)
	local palette = self.palette
	if palette then
		-- Find the color in the palette
		for i, c in ipairs(palette.colors) do
			if c[1] == color[1] and c[2] == color[2] and c[3] == color[3] then
				-- Colors match
				self:setColorByIndex(i)
				return
			end
		end
	end

	self:setColorByValue(color)
end

---Sets the color by a color value, without finding the index of the color in the palette
---@param color Palette.Color
function ColorSelectionProperty:setColorByValue(color)
	if self.color ~= color then
		self.color = color
		self.index = 0
		self:triggerValueChanged()
	end
end

---Sets the color by the index of that color in the palette
---@param index integer
function ColorSelectionProperty:setColorByIndex(index)
	if self.palette then
		local newIndex = math.min(#self.palette.colors, index)
		local newColor = self.palette.colors[newIndex]
		if newColor ~= nil and self:getColor() ~= newColor then
			self.index = newIndex
			self.color = newColor
			self:triggerValueChanged()
		end
	end
end

---Sets the palette this ColorSelection will use
---@param palette Palette?
function ColorSelectionProperty:setPalette(palette)
	self.palette = palette
	local defaultIndex = self.defaultIndex
	if defaultIndex ~= 0 and palette then
		-- Update the color if there is a default index
		self.index = 0
		self:setColorByIndex(defaultIndex)
	end
end

---Sets the default index, which updates the color when the palette is changed
---@param defaultIndex integer
function ColorSelectionProperty:setDefaultIndex(defaultIndex)
	self.defaultIndex = defaultIndex
end

---@return Palette.Color
function ColorSelectionProperty:getColor()
	return self.color
end

---@return integer
function ColorSelectionProperty:getIndex()
	return self.index
end

---@class ColorSelectionProperty.VElement: VBox
local ColorSelectionPropertyVElement = VBox:extend()

---@param rules Plan.Rules
---@param property ColorSelectionProperty
function ColorSelectionPropertyVElement:new(rules, property)
	ColorSelectionPropertyVElement.super.new(self, rules)
	self.property = property

	---@type ColorSelect.HexEdit
	local hexEdit = HexEdit(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.max(26))
			:addHeight(Plan.parent()),
		property:get()
	)
	hexEdit:bindToProperty(property)
	self.hexEdit = hexEdit
	hexEdit.label:setText(property.name)

	---@type Button
	local pickColorButton = IconButton(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(20))
			:addWidth(Plan.pixel(26))
			:addHeight(Plan.aspect(1)),
		function(button)
			Modal.pushColorSelect(self.property)
		end,
		iconSpriteSheet,
		18,
		2
	)
	self.button = pickColorButton

	---@type HBox
	local hbox = HBox(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.parent())
	)
	self.hbox = hbox

	hbox:addChild(hexEdit)
	hbox:addChild(pickColorButton)
	self:addChild(hbox)

	--[[ self._valueChangedAction = property.valueChanged:addAction(function(p, value)
		self.hexEdit.lineEdit:setText(value)
	end) --]]
end

function ColorSelectionProperty:getVElement()
	return ColorSelectionPropertyVElement(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(46)),
		self
	)
end

return ColorSelectionProperty
