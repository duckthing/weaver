local ffi = require "ffi"
local Brush = require "plugins.sprite.brush.brush"
local IntegerProperty = require "src.properties.integer"
local BoolProperty = require "src.properties.bool"
local bellipse = require "src.common.bellipse"
local bfilledellipse = require "src.common.bfilledellipse"

local function squared(n)
	return n * n
end

local function isInsideCircle(ax, ay, cx, cy, radiusSquared)
	return squared(cx - ax + 0.5) + squared(cy - ay + 0.5) <= radiusSquared
end

---@class CircleBrush: Brush
local CircleBrush = Brush:extend()

---@type IntegerProperty
CircleBrush.size = IntegerProperty(CircleBrush, "Diameter", 1)
CircleBrush.size:getRange()
	:setMin(1)
	:setMax(64)
	:setStep(1)

---@type BoolProperty
CircleBrush.filled = BoolProperty(CircleBrush, "Filled", true)

function CircleBrush:new()
	CircleBrush.super.new(self)
	self.w = 1
	self.h = 1
	self:generate(self.size:get())

	CircleBrush.size.valueChanged:addAction(function(property, diameter)
		self:generate(diameter)
	end)

	CircleBrush.filled.valueChanged:addAction(function(property, _)
		self:generate()
	end)
end

local function setPixel(x, y, pointer, w)
	pointer[x + y * w] = 255
end

---@param diameter integer?
function CircleBrush:generate(diameter)
	diameter = (diameter and CircleBrush.size:getRange():sanitizeNumber(diameter)) or CircleBrush.size:get()
	local filled = CircleBrush.filled:get()

	local width = diameter
	local height = width
	local newData = love.image.newImageData(width, height, "r8")
	local dataFFI = ffi.cast("uint8_t*", newData:getFFIPointer())

	local fillAlgorithm
	if filled then
		fillAlgorithm = bfilledellipse
	else
		fillAlgorithm = bellipse
	end

	fillAlgorithm(0, 0, width - 1, height - 1, setPixel, dataFFI, width)

	CircleBrush.size:set(diameter)
	self.w, self.h = width, height
	self:setBrushData(newData)
end

function CircleBrush:grow(amount)
	CircleBrush.size:set(CircleBrush.size:get() + (amount or 1))
end

function CircleBrush:shrink(amount)
	CircleBrush.size:set(CircleBrush.size:get() - (amount or 1))
end

local properties = {
	CircleBrush.size,
	Brush.continuous,
	CircleBrush.filled,
}
function CircleBrush:getProperties()
	local newProperties = {}
	for _, property in ipairs(properties) do
		newProperties[#newProperties+1] = property
	end

	newProperties[#newProperties+1] = self.patternMode

	if self.patternMode:getValue() == "scrolloffset" then
		-- Add the scroll properties
		newProperties[#newProperties+1] = self.sourceOffsetX
		newProperties[#newProperties+1] = self.sourceOffsetY
	end

	return newProperties
end

return CircleBrush
