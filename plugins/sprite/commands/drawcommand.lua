local SpriteCommand = require "plugins.sprite.commands.spritecommand"
local Blend = require "plugins.sprite.common.blend"
local ffi = require "ffi"

---@class DrawCommand: SpriteCommand
local DrawCommand = SpriteCommand:extend()
DrawCommand.CLASS_NAME = "DrawCommand"
DrawCommand.GRID_SIZE = 32

---@type love.ImageData[]
local fragments = {}

---Returns the new fragment
---@return love.ImageData
function DrawCommand._getFragment()
	return table.remove(fragments, #fragments)
		or love.image.newImageData(DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE, "rgba8")
end

---Returns the fragment for reuse in the future
---@param frag love.ImageData
function DrawCommand._returnFragment(frag)
	fragments[#fragments+1] = frag
end

---@param sprite Sprite
---@param cel Sprite.Cel
function DrawCommand:new(sprite, cel)
	DrawCommand.super.new(self, sprite)
	self.cel = cel
	---@type boolean[][]
	self.markedRegions = {}
	---@type love.ImageData[][]
	self.newFragments = {}
	---@type love.ImageData[][]
	self.oldFragments = {}

	self.relevantLayer = sprite.spriteState.layer:get()
	self.relevantFrame = sprite.spriteState.frame:get()
end

function DrawCommand:markRegion(x, y, w, h)
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
			end
		end
	end
end

---Completes the DrawCommand so that it can be performed
---@param sourceCel Sprite.Cel
---@param blendCommand string
function DrawCommand:completeMark(sourceCel, blendCommand)
	local sprite, cel = self.sprite, self.cel
	---@type BlendOperation
	local blendOperation = Blend[blendCommand]
	if blendOperation == nil then
		error(("Invalid blend command: %d"):format(blendCommand))
	end
	self.blendOperation = blendOperation

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
			local newFragmentID = DrawCommand._getFragment()
			local oldFragmentID = DrawCommand._getFragment()
			self.newFragments[x][y] = newFragmentID
			self.oldFragments[x][y] = oldFragmentID

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			local offsetX, offsetY =
				x * DrawCommand.GRID_SIZE,
				y * DrawCommand.GRID_SIZE

			-- Copy the old data
			oldFragmentID:paste(celID, 0, 0, offsetX, offsetY, wCount, hCount)

			-- Do the blending
			blendOperation(celID, sourceCel.data, offsetX, offsetY, offsetX, offsetY, wCount, hCount)

			-- Then copy the new data
			newFragmentID:paste(celID, 0, 0, offsetX, offsetY, wCount, hCount)

			-- Clear the draw buffer
			local dw = sourceCel.data:getWidth()
			local dbFFI = ffi.cast("uint32_t*", sourceCel.data:getFFIPointer())
			for j = 0, hCount - 1 do
				local dy = (offsetY * w) + j * dw
				for i = 0, wCount - 1 do
					local dx = offsetX + i
					local index = dy + dx
					dbFFI[index] = 0
				end
			end
		end
	end
end

function DrawCommand:undo()
	-- Copy the old data into the cel
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
			local oFragmentID = self.oldFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			celID:paste(oFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	cel:update()
end

function DrawCommand:perform()
	-- Copy the new data into the cel
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
			local nFragmentID = self.newFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			celID:paste(nFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	cel:update()
end

function DrawCommand:hasChanges()
	for _, arr in pairs(self.markedRegions) do
		-- Return true if there's any changes
		for _, _ in pairs(arr) do return true end
	end
	return false
end

function DrawCommand:getPosition()
	return self.relevantLayer, self.relevantFrame
end

function DrawCommand:release()
	-- Might error due to commands not being completed
	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			DrawCommand._returnFragment(self.oldFragments[x][y])
			DrawCommand._returnFragment(self.newFragments[x][y])
		end
		self.oldFragments[x] = nil
		self.newFragments[x] = nil
	end
	self.markedRegions = nil
	self.oldFragments = nil
	self.newFragments = nil
end

return DrawCommand
