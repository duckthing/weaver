-- local Command = require "src.data.command"
local DrawCommand = require "plugins.sprite.commands.drawcommand"
local Blend = require "plugins.sprite.common.blend"
local ffi = require "ffi"

-- Same as DrawCommand, except new regions are copied first
-- instead of after finishing drawing.
-- This makes it a good way to store before/after type operations.

---@class BucketFillCommand: DrawCommand
local BucketFillCommand = DrawCommand:extend()
BucketFillCommand.CLASS_NAME = "BucketFillCommand"

---Marks a pixel only
---@param x integer
---@param y integer
function BucketFillCommand:markPixel(x, y)
	local celData = self.cel.data
	local format = celData:getFormat()
	local regions = self.markedRegions
	local newFragments = self.newFragments
	local oldFragments = self.oldFragments

	local i, j = math.floor(x / DrawCommand.GRID_SIZE), math.floor(y / DrawCommand.GRID_SIZE)
	if regions[i] == nil then
		regions[i] = {}
		newFragments[i] = {}
		oldFragments[i] = {}
	end

	if regions[i][j] ~= true then
		regions[i][j] = true

		local oldFragment = DrawCommand:_getFragment()
		oldFragment:paste(celData, 0, 0, i * DrawCommand.GRID_SIZE, j * DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE)
		oldFragments[i][j] = oldFragment
	end
end

---@param x integer
---@param y integer
---@param w integer
---@param h integer
function BucketFillCommand:markRegion(x, y, w, h)
	local celData = self.cel.data
	local format = celData:getFormat()
	local regions = self.markedRegions
	local newFragments = self.newFragments
	local oldFragments = self.oldFragments
	local sw, sh = self.sprite.width, self.sprite.height

	-- Don't mark out of bounds
	if x >= sw or x + w <= 0 or y >= sh or y + h <= 0 then return end

	local maxI, maxJ =
		math.ceil(sw / DrawCommand.GRID_SIZE) - 1,
		math.ceil(sh / DrawCommand.GRID_SIZE) - 1

	for i = math.max(0, math.min(maxI, math.floor(x / DrawCommand.GRID_SIZE))), math.min(maxI, math.floor((x + w - 1) / DrawCommand.GRID_SIZE)) do
		if regions[i] == nil then
			regions[i] = {}
			newFragments[i] = {}
			oldFragments[i] = {}
		end

		for j = math.max(0, math.min(maxJ, math.floor(y / DrawCommand.GRID_SIZE))), math.min(maxJ, math.floor((y + h - 1) / DrawCommand.GRID_SIZE)) do
			if regions[i][j] ~= true then
				regions[i][j] = true

				local oldFragment = DrawCommand:_getFragment()
				oldFragment:paste(celData, 0, 0, i * DrawCommand.GRID_SIZE, j * DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE)
				oldFragments[i][j] = oldFragment
			end
		end
	end
end

---Completes the DrawCommand so that it can be performed
function BucketFillCommand:completeMark()
	local sprite, cel = self.sprite, self.cel

	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % DrawCommand.GRID_SIZE, h % DrawCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / DrawCommand.GRID_SIZE),
		math.floor(h / DrawCommand.GRID_SIZE)
	local celID = cel.data

	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local newFragmentID = DrawCommand:_getFragment()
			self.newFragments[x][y] = newFragmentID

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			local offsetX, offsetY =
				x * DrawCommand.GRID_SIZE,
				y * DrawCommand.GRID_SIZE

			-- Blending and copy has already occurred

			-- Copy the new data
			newFragmentID:paste(celID, 0, 0, offsetX, offsetY, wCount, hCount)
		end
	end
end

return BucketFillCommand
