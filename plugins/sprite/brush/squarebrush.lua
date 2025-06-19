local ffi = require "ffi"
local Brush = require "plugins.sprite.brush.brush"
local IntegerProperty = require "src.properties.integer"
local BoolProperty = require "src.properties.bool"

local function squared(n)
	return n * n
end

---@class SquareBrush: Brush
local SquareBrush = Brush:extend()

---@type IntegerProperty
SquareBrush.size = IntegerProperty(SquareBrush, "Size", 1)
SquareBrush.size:getRange()
	:setMin(1)
	:setMax(64)
	:setStep(1)

---@type BoolProperty
SquareBrush.filled = BoolProperty(SquareBrush, "Filled", true)

function SquareBrush:new()
	SquareBrush.super.new(self)
	self.w = 1
	self.h = 1
	self:generate(self.size:get())

	SquareBrush.size.valueChanged:addAction(function(property, size)
		self:generate(size)
	end)

	SquareBrush.filled.valueChanged:addAction(function(property, _)
		self:generate()
	end)
end

---@param size integer?
function SquareBrush:generate(size)
	size = (size and SquareBrush.size:getRange():sanitizeNumber(size)) or SquareBrush.size:get()
	local filled = self.filled:get()
	local width = size
	local height = width
	local newData = love.image.newImageData(size, size, "r8")

	local dataFFI = ffi.cast("uint8_t*", newData:getFFIPointer())
	if filled then
		for x = 0, width - 1 do
			for y = 0, height - 1 do
				local index = x + (y * width)
				dataFFI[index] = 255
			end
		end
	else
		local secondY = height - 1
		for x = 0, width - 1 do
			dataFFI[x                  ] = 255
			dataFFI[x + secondY * width] = 255
		end

		local secondX = width - 1
		for y = 1, height - 2 do
			dataFFI[0       + y * width] = 255
			dataFFI[secondX + y * width] = 255
		end
	end

	SquareBrush.size:set(size)
	self.w, self.h = width, height
	self:setBrushData(newData)
end

function SquareBrush:grow(amount)
	SquareBrush.size:set(SquareBrush.size:get() + (amount or 1))
end

function SquareBrush:shrink(amount)
	SquareBrush.size:set(SquareBrush.size:get() - (amount or 1))
end

local properties = {
	SquareBrush.size,
	Brush.continuous,
	SquareBrush.filled,
}
function SquareBrush:getProperties()
	local newProperties = {}
	for _, property in ipairs(properties) do
		newProperties[#newProperties+1] = property
	end

	newProperties[#newProperties+1] = self.patternMode

	if self.patternMode:getValue() == "scrolloffset" then
		-- Add the scroll properties
		newProperties[#newProperties+1] = self.scrollOffsetX
		newProperties[#newProperties+1] = self.scrollOffsetY
	end

	return newProperties
end

return SquareBrush
