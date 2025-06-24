local ffi = require "ffi"
local bit = require "bit"
local HSX = require "lib.hsx"
local Plan = require "lib.plan"
local PopupWindow = require "ui.components.containers.modals.popupwindow"
local VScroll = require "ui.components.containers.box.vscroll"
local Slidebox = require "ui.components.range.slidebox"
local Range = require "src.data.range"
local LineEdit = require "ui.components.text.lineedit"
local VBox = require "ui.components.containers.box.vbox"
local HBox = require "ui.components.containers.box.hbox"
local Label = require "ui.components.text.label"

---@class ColorSelect: PopupWindow
local ColorSelect = PopupWindow:extend()
ColorSelect.CLASS_NAME = "ColorSelect"

---@class ColorSelect.Wheel: Plan.Container
local ColorWheel = Plan.Container:extend()
ColorWheel.CLASS_NAME = "ColorWheel"

---@class ColorSelect.HueSlider: Slidebox
local HueSlider = Slidebox:extend()
HueSlider.CLASS_NAME = "HueSlider"

local wheelShaderCode = [[
extern float hue;

// From the LOVE2D wiki (https://www.love2d.org/wiki/HSV_color)
vec3 hsv(float h,float s,float v) { return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v; }

vec4 effect(vec4 color, Image texture, vec2 texture_pos, vec2 screen_pos)
{
	return vec4(hsv(hue, texture_pos.x, 1. - texture_pos.y), 1.);
}
]]

local hueShaderCode = [[
extern float hue;

// From the LOVE2D wiki (https://www.love2d.org/wiki/HSV_color)
vec3 hsv(float h,float s,float v) { return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v; }

vec4 effect(vec4 color, Image texture, vec2 texture_pos, vec2 screen_pos)
{
	return vec4(hsv(texture_pos.x, 1., 1.), 1.);
}
]]

local wheelShader = love.graphics.newShader(wheelShaderCode)
local hueShader = love.graphics.newShader(hueShaderCode)

local whiteSquare
do
	local whiteSquareData = love.image.newImageData(1, 1, "rgba8")
	local pointer = ffi.cast("uint8_t*", whiteSquareData:getFFIPointer())
	for i = 0, 3 do
		pointer[i] = 255
	end
	whiteSquare = love.graphics.newImage(whiteSquareData)
end

function ColorWheel:new(...)
	ColorWheel.super.new(self, ...)

	---@type ColorSelectionProperty?
	self.property = nil

	---@type number, number
	self.cursorX, self.cursorY = 0, 0

	---@type number
	self.hue = 0.

	self.pressed = false
end

function ColorWheel:draw()
	love.graphics.push("all")

	-- Draw the wheel
	love.graphics.setShader(wheelShader)
	wheelShader:send("hue", self.hue)
	love.graphics.draw(whiteSquare, self.x, self.y, 0, self.w, self.h)

	love.graphics.setShader()
	local offsetX, offsetY =
		self.w * self.cursorX,
		self.h * self.cursorY

	love.graphics.setLineWidth(2)
	love.graphics.setColor(0, 0, 0)
	love.graphics.circle("line", self.x + offsetX, self.y + offsetY, 4)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("line", self.x + offsetX, self.y + offsetY, 6)

	love.graphics.pop()
end

---@param property ColorSelectionProperty?
function ColorWheel:bindToProperty(property)
	if property == self.property then return end
	self.property = property
	if not property then return end

	local colorRGB = property:getColor()
	local r, g, b = colorRGB[1], colorRGB[2], colorRGB[3]
	local h, s, v = HSX.rgb2hsv(r, g, b)

	self.hue = h

	self.cursorX, self.cursorY =
		s,
		1 - v
end

function ColorWheel:moveCursor(mx, my)
	self.cursorX, self.cursorY =
		math.max(0, math.min((mx - self.x) / self.w, 1)),
		math.max(0, math.min((my - self.y) / self.h, 1))
end

function ColorWheel:updateProperty()
	local property = self.property
	if property then
		local r, g, b = HSX.hsv2rgb(self.hue, self.cursorX, 1 - self.cursorY)
		property:userSetColor(r, g, b)
	end
end

function ColorWheel:mousemoved(mx, my)
	if self.pressed then
		self:moveCursor(mx, my)
		self:updateProperty()
	end
end

function ColorWheel:mousepressed(mx, my, button)
	if button == 1 then
		self.pressed = true
		self:getFocus()
		self:moveCursor(mx, my)
		self:updateProperty()
	end
end

function ColorWheel:mousereleased(_, _, button)
	if button == 1 and self.pressed then
		self.pressed = false
		self:releaseFocus()
		self:updateProperty()
	end
end

function ColorWheel:wheelmoved(x, y)
	local xShift = x * 0.01
	local yShift = y * -0.01

	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
		-- Swap the axis
		xShift, yShift = -yShift, -xShift
	end

	self.cursorX = math.max(0, math.min(self.cursorX + xShift, 1))
	self.cursorY = math.max(0, math.min(self.cursorY + yShift, 1))
	self:updateProperty()
end

function HueSlider:new(rules)
	---@type Range
	local range = Range()
	range:setMin(0)
		:setMax(1)

	HueSlider.super.new(self, rules, range)
	self.updateLive = true

	---@type ColorSelectionProperty?
	self.property = nil

	---@type ColorSelect.Wheel
	self.wheel = nil

	range.valueChanged:addAction(function(_, newValue)
		self.wheel.hue = newValue
		self.wheel:updateProperty()
	end)
end

function HueSlider:draw()
	love.graphics.push("all")
	love.graphics.setShader(hueShader)
	love.graphics.draw(whiteSquare, self.x, self.y, 0, self.w, self.h)

	local offsetX = self.range.value * self.w
	local offsetY = self.h * 0.5
	love.graphics.setShader()
	love.graphics.setLineWidth(2)
	love.graphics.setColor(0, 0, 0)
	love.graphics.circle("line", self.x + offsetX, self.y + offsetY, 4)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("line", self.x + offsetX, self.y + offsetY, 6)

	love.graphics.pop()
end

function HueSlider:wheelmoved(x, y)
	local range = self.range

	local stepAmount = 0.01
	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
		stepAmount = 0.00039 -- Around 1/256
	end

	local newValue = range:getValue() + stepAmount * (x + y)
	if newValue < 0 then
		newValue = newValue + 1
	elseif newValue > 1 then
		newValue = newValue - 1
	end
	range:setValue(newValue)
end

---@param property ColorSelectionProperty?
function HueSlider:bindToProperty(property)
	if property == self.property then return end
	self.property = property
	if not property then return end

	local colorRGB = property:getColor()
	local r, g, b = colorRGB[1], colorRGB[2], colorRGB[3]
	local h, s, v = HSX.rgb2hsv(r, g, b)

	self.hue = h
end

---@class ColorSelect.HexEdit: VBox
local HexEdit = VBox:extend()

---@param color Palette.Color
---@return string
local function toHexString(color)
	local r, g, b = love.math.colorToBytes(color[1], color[2], color[3])
	local hex = r * 0x010000 + g * 0x000100 + b * 0x000001
	return ("%06X"):format(hex)
end

---@param str string
---@return integer
---@return integer
---@return integer
local function fromHexString(str)
	local number = tonumber(str, 16) or 0
	local r, g, b = 0, 0, 0

	b = bit.band(number, 255)
	number = bit.rshift(number, 8)
	g = bit.band(number, 255)
	number = bit.rshift(number, 8)
	r = bit.band(number, 255)

	---@diagnostic disable-next-line
	return love.math.colorFromBytes(r, g, b)
end

---@param rules Plan.Rules
function HexEdit:new(rules)
	HexEdit.super.new(self, rules)
	self.maxLength = 6

	---@type ColorSelectionProperty?
	self.property = nil

	---@type Label
	local label = Label(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(20)),
		"Hex"
	)

	self.label = label
	self:addChild(label)

	---@type LineEdit
	local lineEdit = LineEdit(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(26)),
		"000000"
	)
	lineEdit.preferStart = false
	self.lineEdit = lineEdit

	---@type HBox
	local hbox = HBox(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(26))
	)
	self.hbox = hbox

	hbox:addChild(lineEdit)
	self:addChild(hbox)
end

---@param property ColorSelectionProperty?
function HexEdit:bindToProperty(property)
	if property == self.property then return end

	local oldProperty = self.property
	self.property = property

	if oldProperty then
		oldProperty.valueChanged:removeAction(self._valueChangedAction)
		self._valueChangedAction = nil
	end

	if property == nil then return end

	self.lineEdit:setText(toHexString(property:getColor()))
	self.lineEdit.textSubmitted:addAction(function(text)
		local r, g, b = fromHexString(text)
		property:userSetColor(fromHexString(text))
		self:bubble("_bHexInputSet")
	end)

	self._valueChangedAction = property.valueChanged:addAction(function(p, value)
		self.lineEdit:setText(toHexString(value))
	end)
end

function ColorSelect:_bHexInputSet()
	local color = self.property:getColor()
	local h, s, v = HSX.rgb2hsv(color[1], color[2], color[3])

	self.colorWheel.cursorX = s
	self.colorWheel.cursorY = 1 - v
	self.hueSlider.range:setValue(h)
end

function ColorSelect:new(rules, actions, title)
	ColorSelect.super.new(self, rules, actions, title or "Pick Color")

	self.vscroll = VScroll(
		Plan.RuleFactory.full()
	)
	self.vscroll.margin = 4

	---@type ColorSelect.Wheel
	self.colorWheel = ColorWheel(
		Plan.Rules.new()
			:addX(Plan.pixel(4))
			:addY(Plan.pixel(0))
			:addWidth(Plan.max(8))
			:addHeight(Plan.aspect(1))
	)

	---@type ColorSelect.HueSlider
	self.hueSlider = HueSlider(
		Plan.Rules.new()
			:addX(Plan.pixel(4))
			:addY(Plan.keep())
			:addWidth(Plan.max(8))
			:addHeight(Plan.pixel(20))
	)
	self.hueSlider.wheel = self.colorWheel

	---@type ColorSelect.HexEdit
	self.hexEdit = HexEdit(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(46))
	)

	self.vscroll:addChild(self.colorWheel)
	self.vscroll:addChild(self.hueSlider)
	self.vscroll:addChild(self.hexEdit)

	self:addChild(self.vscroll)

	---@type ColorSelectionProperty?
	self.property = nil
end

---@param property ColorSelectionProperty?
function ColorSelect:bindToProperty(property)
	if property == self.property then return end

	self.property = property
	self.colorWheel:bindToProperty(property)
	self.hexEdit:bindToProperty(property)
end

return ColorSelect
