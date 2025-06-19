local ffi = require "ffi"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local BaseSelectionTool = require "plugins.sprite.tools.baseselectiontool"
local LabelProperty = require "src.properties.label"
local BoolProperty = require "src.properties.bool"
local EnumProperty = require "src.properties.enum"
local SelectionCommand = require "plugins.sprite.commands.selectioncommand"
local spanfill = require "src.common.spanfill"

---@class SpriteMagicMarquee: BaseSelectionTool
local MagicMarquee = BaseSelectionTool:extend()

function MagicMarquee:draw(imageX, imageY, currLayerIndex)
	if BaseSelectionTool.draw(MagicMarquee, imageX, imageY, currLayerIndex) then return end
	if currLayerIndex == SpriteTool.layer.index then
		local sprite = SpriteTool.sprite
		local canvas = SpriteTool.canvas
		if not sprite or not canvas then return end
	end
end

---Returns a function that checks if the pixel is "inside" and a setter function.
---"Inside" means this pixel should be set.
---When a pixel is "set", it is no longer "inside".
---
---Returns nil if the point is invalid.
---@param bitmask Bitmask
---@param startX integer
---@param startY integer
---@param layerFFI ffi.cdata*
---@param command SelectionCommand
---@return (fun(imageX: integer, imageY: integer): boolean)? inside
---@return (fun(imageX: integer, imageY: integer))? set
local function createInsideCheck(bitmask, startX, startY, layerFFI, command)
	local width, height = bitmask.width, bitmask.height

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

	local inside

	if sa == 0 then
		-- This pixel is clear, fill any transparent area
		-- Inactive bitmask, fill anywhere transparent
		inside = function(imageX, imageY)
			if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
				local i = ((imageX) + (imageY) * width) * 4
				return layerFFI[i + 3] == 0 and not bitmask:get(imageX, imageY)
			end
			return false
		end
	else
		-- This pixel has a color, fill pixels with the same exact color
		-- Inactive bitmask, fill exact color anywhere
		inside = function(imageX, imageY)
			if imageX > -1 and imageX < width and imageY > -1 and imageY < height then
				local i = ((imageX) + (imageY) * width) * 4
				return  layerFFI[i    ] == sr and
						layerFFI[i + 1] == sg and
						layerFFI[i + 2] == sb and
						layerFFI[i + 3] == sa and
						not bitmask:get(imageX, imageY)
			end
			return false
		end
	end

	local set = function(imageX, imageY)
		command:markRegion(imageX, imageY, 1, 1)
		bitmask:set(imageX, imageY, true)
	end

	return inside, set
end

---@param imageX integer
---@param imageY integer
function MagicMarquee:startPress(imageX, imageY)
	if BaseSelectionTool.startPress(MagicMarquee, imageX, imageY) then return end
	local sprite = SpriteTool.sprite
	local cel = SpriteTool.cel
	if not sprite then return end
	local bitmask = sprite.spriteState.bitmask
	sprite.undoStack:pushGroup()
	---@type SelectionCommand
	local command = SelectionCommand(sprite, bitmask)

	-- TODO: Make this go through all layers
	if not cel then
		-- Empty cel, select all
		-- Check the bounds first
		command:markRegion(0, 0, sprite.width, sprite.height)
		if imageX < 0 or imageY < 0 or imageX >= sprite.width or imageY >= sprite.height then
			-- Outside of bounds, deselect all
			bitmask:reset(false)
			bitmask:setActive(false)
		else
			-- Inside of bounds, select all
			bitmask:reset(true)
			bitmask:setActive(true)
		end
		command:completeMark()
		sprite.undoStack:commit(command)
		sprite.undoStack:popGroup()
		sprite.spriteState.bitmaskRenderer:update()
		SpriteTool.drawing = true
		return
	end

	local celFFI = ffi.cast("uint8_t*", cel.data:getFFIPointer())
	local operation = BaseSelectionTool:getOperation()
	local mode = MagicMarquee.mode:getValue()
	SpriteTool.applyFromSelection()
	sprite.spriteState.includeMimic = true

	if mode == "4-way" then
		-- 4-way connected colors
		local inside, set = createInsideCheck(bitmask, imageX, imageY, celFFI, command)
		if not inside or not set then bitmask:reset(false) goto continue end

		if operation == "subtract" then
			-- command:markRegion(sx, sy, w, h)
			-- bitmask:markRegion(sx, sy, w, h, false)
		elseif operation == "add" then
			spanfill(imageX, imageY, inside, set)
		elseif operation == "set" then
			do
				local bx, by, _, _, bw, bh = bitmask:getBounds()
				command:markRegion(bx, by, bw, bh)
			end
			bitmask:reset()
			spanfill(imageX, imageY, inside, set)
		end
	elseif mode == "Same color" then
		-- Check the bounds first
		if imageX < 0 or imageY < 0 or imageX >= sprite.width or imageY >= sprite.height then goto continue end

		local i = (imageX + imageY * sprite.width) * 4
		local r, g, b, a =
			celFFI[i    ],
			celFFI[i + 1],
			celFFI[i + 2],
			celFFI[i + 3]

		if operation == "set" then
			local bx, by, _, _, bw, bh = bitmask:getBounds()
			command:markRegion(bx, by, bw, bh)
			bitmask:reset()
		end

		for x = 0, sprite.width - 1 do
			for y = 0, sprite.height - 1 do
				local j = (x + y * sprite.width) * 4
				if
					celFFI[j    ] == r and
					celFFI[j + 1] == g and
					celFFI[j + 2] == b and
					celFFI[j + 3] == a
				then
					bitmask:set(x, y, true)
				end
			end
		end

		bitmask._dirty = true

		do
			local bx, by, _, _, bw, bh = bitmask:getBounds()
			command:markRegion(bx, by, bw, bh)
		end
	end
	::continue::

	bitmask:setActive(true)
	do
		-- Check if it's empty now
		local _, _, _, _, bw, bh = bitmask:getBounds()
		if bw == 0 or bh == 0 then
			-- It is empty
			bitmask:setActive(false)
		end
	end

	command:completeMark()
	SpriteTool.liftIntoSelection()
	sprite.spriteState.bitmaskRenderer:update()
	sprite.undoStack:commit(command)
	sprite.undoStack:popGroup()

	SpriteTool.drawing = true
end

function MagicMarquee:stopPress(imageX, imageY)
	if BaseSelectionTool.stopPress(MagicMarquee, imageX, imageY) then return end
	if SpriteTool.drawing then
		SpriteTool.drawing = false
	end
end

---@type LabelProperty
MagicMarquee.name = LabelProperty(MagicMarquee, "Name", "Magic Marquee")
---@type EnumProperty
MagicMarquee.mode = EnumProperty(MagicMarquee, "Fill Mode", false)
MagicMarquee.mode:setOptions({
	{
		name = "4-way",
		value = "4-way"
	},
	{
		name = "Same color",
		value = "Same color"
	},
})

---@type BoolProperty
-- MagicMarquee.sameLayer = BoolProperty(MagicMarquee, "Same layer", false)

local properties = {
	MagicMarquee.name,
	MagicMarquee.mode,
	-- MagicMarquee.sameLayer,
}

function MagicMarquee:getProperties()
	return properties
end

return MagicMarquee
