local ffi = require "ffi"
local Brush = require "plugins.sprite.brush.brush"
local IntegerProperty = require "src.properties.integer"
local BoolProperty = require "src.properties.bool"
local EnumProperty = require "src.properties.enum"

---@class ImageBrush: Brush
local ImageBrush = Brush:extend()

---@param sprite Sprite
function ImageBrush:new(sprite, type)
	ImageBrush.super.new(self)
	local asMask = type == "mask"
	self.patternMode:setValue("scrolloffset")

	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	local includeSelection = spriteState.includeMimic
	local cel =
		(includeSelection and spriteState.selectionCel) or
		spriteState:getCurrentCel()

	if not bitmask._active then return end

	local bx, by, bright, bbottom, bw, bh = bitmask:getBounds()

	local celW, celH = cel.data:getDimensions()
	local celP = ffi.cast("uint8_t*", cel.data:getFFIPointer())

	---@type love.ImageData
	local data

	if asMask then
		data = love.image.newImageData(bw, bh, "r8")
		local dataP = ffi.cast("uint8_t*", data:getFFIPointer())
		self.type:setValue("mask")
		for x = bx, bright do
			for y = by, bbottom do
				local dataIndex = (x - bx) + (y - by) * bw
				dataP[dataIndex] = (bitmask:get(x, y) and 255) or 0
			end
		end
	else
		data = love.image.newImageData(bw, bh, sprite.format)
		local dataP = ffi.cast("uint8_t*", data:getFFIPointer())
		self.type:setValue("color")
		for x = bx, bright do
			for y = by, bbottom do
				if not bitmask:get(x, y) then goto continue end
				local celIndex = (x + y * celW) * 4
				local dataIndex = ((x - bx) + (y - by) * bw) * 4

				dataP[dataIndex    ] = celP[celIndex    ]
				dataP[dataIndex + 1] = celP[celIndex + 1]
				dataP[dataIndex + 2] = celP[celIndex + 2]
				dataP[dataIndex + 3] = celP[celIndex + 3]

				::continue::
			end
		end
	end

	self.w, self.h = bw, bh
	self.sourceOffsetX:set(bx % bw)
	self.sourceOffsetY:set(by % bh)
	self:setBrushData(data)
end

function ImageBrush:generate()
	print("Can't generate brush data as an ImageBrush")
end

local properties = {
	Brush.continuous,
}
function ImageBrush:getProperties()
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

return ImageBrush
