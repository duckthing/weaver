local ffi = require "ffi"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Blend = require "plugins.sprite.common.blend"
local LabelProperty = require "src.properties.label"
local BucketFillCommand = require "plugins.sprite.commands.bucketfillcommand"
local BoolProperty = require "src.properties.bool"
local EnumProperty = require "src.properties.enum"
local spanfill = require "src.common.spanfill"

---@class SpriteBucket: SpriteTool
local Bucket = SpriteTool:extend()

---@param imageY integer
---@param currLayerIndex integer
function Bucket:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index then
		local color = SpriteTool.primaryColor
		love.graphics.setColor(color)
		love.graphics.rectangle("fill", imageX, imageY, 1, 1)
	end
end

---Returns a function that checks if the pixel is "inside" and a setter function.
---"Inside" means this pixel should be set.
---When a pixel is "set", it is no longer "inside".
---
---Returns nil if the point is invalid.
---@param sprite Sprite
---@param startX integer
---@param startY integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@param layerFFI ffi.cdata*
---@param bitmask Bitmask
---@param command BucketFillCommand
---@return (fun(imageX: integer, imageY: integer): boolean)? inside
---@return (fun(imageX: integer, imageY: integer))? set
local function createInsideCheck(sprite, startX, startY, r, g, b, a, layerFFI, bitmask, command)
	local width, height = sprite.width, sprite.height

	if not (startX > -1 and startX < width and startY > -1 and startY < height) then
		-- Out of bounds
		return nil, nil
	end

	-- Get the color of the current pixel
	local j = ((startX) + (startY) * width) * 4
	local sr, sg, sb, sa =
					layerFFI[j    ],
					layerFFI[j + 1],
					layerFFI[j + 2],
					layerFFI[j + 3]

	-- Return nil if this pixel's colors are the same as the bucket colors
	-- Basically, don't set a pixel that already has the target color
	if not (sr ~= r or sg ~= g or sb ~= b or sa ~= a) then return nil, nil end

	local inside

	if sa == 0 then
		-- This pixel is clear, fill any transparent area
		if bitmask._active then
			-- Active bitmask, fill inside the area
			inside = function(imageX, imageY)
				if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
					local i = ((imageX) + (imageY) * width) * 4
					return layerFFI[i + 3] == 0 and bitmask:get(imageX, imageY)
				end
				return false
			end
		else
			-- Inactive bitmask, fill anywhere transparent
			inside = function(imageX, imageY)
				if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
					local i = ((imageX) + (imageY) * width) * 4
					return layerFFI[i + 3] == 0
				end
				return false
			end
		end
	else
		-- This pixel has a color, fill pixels with the same exact color
		if bitmask._active then
			-- Active bitmask, fill exact color within the mask
			inside = function(imageX, imageY)
				if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
					local i = ((imageX) + (imageY) * width) * 4
					return  layerFFI[i    ] == sr and
							layerFFI[i + 1] == sg and
							layerFFI[i + 2] == sb and
							layerFFI[i + 3] == sa and
							bitmask:get(imageX, imageY)
				end
				return false
			end
		else
			-- Inactive bitmask, fill exact color anywhere
			inside = function(imageX, imageY)
				if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
					local i = ((imageX) + (imageY) * width) * 4
					return  layerFFI[i    ] == sr and
							layerFFI[i + 1] == sg and
							layerFFI[i + 2] == sb and
							layerFFI[i + 3] == sa
				end
				return false
			end
		end
	end

	local set = function(imageX, imageY)
		command:markPixel(imageX, imageY)
		local i = ((imageX) + (imageY) * width) * 4
		layerFFI[i    ] = r
		layerFFI[i + 1] = g
		layerFFI[i + 2] = b
		layerFFI[i + 3] = a
	end

	return inside, set
end

---@param imageX integer
---@param imageY integer
function Bucket:startPress(imageX, imageY)
	-- Implements the span fill algorithm from wikipedia
	local sprite = SpriteTool.sprite
	if not sprite then return end
	SpriteTool.drawing = true
	sprite.undoStack:pushGroup()
	SpriteTool:ensureCel()
	---@type Sprite.Cel
	local currentCel = SpriteTool.cel
	---@type BucketFillCommand
	local command = BucketFillCommand(sprite, currentCel)

	local bitmask = sprite.spriteState.bitmask
	SpriteTool.applyFromSelection()
	local imageData = currentCel.data
	local data = ffi.cast("uint8_t*", imageData:getFFIPointer())
	local color = SpriteTool.primaryColor
	local r, g, b = love.math.colorToBytes(color[1], color[2], color[3])

	local mode = Bucket.mode:getValue()
	if mode == "4-way" then
		-- Fill connected pixels only
		local inside, set =
					createInsideCheck(sprite, imageX, imageY, r, g, b, 255, data, bitmask, command)
		-- Stop if there was an issue creating the check functions
		-- (Out of bounds, same color, etc.)
		if inside and set then
			-- TODO: Can bucket undo region marking be improved?
			spanfill(imageX, imageY, inside, set)
		end
	elseif mode == "Same color" then
		-- Replace same color
		local hoveredI = 4 * (imageX + imageY * sprite.width)
		local sr, sg, sb, sa =
			data[hoveredI    ],
			data[hoveredI + 1],
			data[hoveredI + 2],
			data[hoveredI + 3]

		if bitmask._active then
			-- Check bitmask
			for x = 0, sprite.width - 1 do
				for y = 0, sprite.height - 1 do
					local i = 4 * (x + y * sprite.width)
					if
						bitmask:get(x, y) and
						data[i    ] == sr and
						data[i + 1] == sg and
						data[i + 2] == sb and
						data[i + 3] == sa
					then
						command:markPixel(x, y)
						data[i    ] = r
						data[i + 1] = g
						data[i + 2] = b
						data[i + 3] = 255
					end
				end
			end
		else
			-- Don't check bitmask
			for x = 0, sprite.width - 1 do
				for y = 0, sprite.height - 1 do
					local i = 4 * (x + y * sprite.width)
					if
						data[i    ] == sr and
						data[i + 1] == sg and
						data[i + 2] == sb and
						data[i + 3] == sa
					then
						command:markPixel(x, y)
						data[i    ] = r
						data[i + 1] = g
						data[i + 2] = b
						data[i + 3] = 255
					end
				end
			end
		end
	elseif mode == "Everything" then
		-- Fill everything in the selection
		if bitmask._active then
			-- Check bitmask
			local bx, by, _, _, bw, bh = bitmask:getBounds()
			command:markRegion(bx, by, bw, bh)
			for x = 0, sprite.width - 1 do
				for y = 0, sprite.height - 1 do
					local i = 4 * (x + y * sprite.width)
					if bitmask:get(x, y) then
						data[i    ] = r
						data[i + 1] = g
						data[i + 2] = b
						data[i + 3] = 255
					end
				end
			end
		else
			-- Don't check bitmask
			command:markRegion(0, 0, sprite.width - 1, sprite.height - 1)
			for i = 0, ((sprite.width * sprite.height) - 1) * 4, 4 do
				data[i    ] = r
				data[i + 1] = g
				data[i + 2] = b
				data[i + 3] = 255
			end
		end
	end

	command:completeMark()
	sprite.undoStack:commit(command)
	SpriteTool.liftIntoSelection()
	sprite.undoStack:popGroup()

	-- Update the image
	currentCel.image:release()
	currentCel.image = love.graphics.newImage(imageData)
end

---@param imageX integer
---@param imageY integer
function Bucket:stopPress(imageX, imageY)
	if SpriteTool.drawing then
		SpriteTool.drawing = false
	end
end

---@type LabelProperty
Bucket.name = LabelProperty(Bucket, "Name", "Bucket")
---@type EnumProperty
Bucket.mode = EnumProperty(Bucket, "Fill Mode", false)
Bucket.mode:setOptions({
	{
		name = "4-way",
		value = "4-way"
	},
	{
		name = "Same color",
		value = "Same color"
	},
	{
		name = "Everything",
		value = "Everything"
	},
})
local properties = {
	Bucket.name,
	Bucket.mode,
}
function Bucket:getProperties()
	return properties
end

return Bucket
