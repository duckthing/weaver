local SpriteCommand = require "plugins.sprite.commands.spritecommand"
local DrawCommand = require "plugins.sprite.commands.drawcommand"
local BitMask = require "plugins.sprite.data.bitmask"

---@class SelectionCommand: SpriteCommand
local SelectionCommand = SpriteCommand:extend()
SelectionCommand.CLASS_NAME = "SelectionCommand"
SelectionCommand.GRID_SIZE = 32
---@type SpriteTool
SelectionCommand.SpriteTool = nil

---@type Bitmask[]
local fragments = {}

---Returns the new fragment
---@return Bitmask
function SelectionCommand._getFragment()
	return table.remove(fragments, #fragments)
		or BitMask.new(SelectionCommand.GRID_SIZE, SelectionCommand.GRID_SIZE)
end

---Returns the fragment for reuse in the future
---@param frag Bitmask
function SelectionCommand._returnFragment(frag)
	fragments[#fragments+1] = frag
end

---@param sprite Sprite
---@param bitmask Bitmask
function SelectionCommand:new(sprite, bitmask)
	SelectionCommand.super.new(self, sprite)
	self.bitmask = bitmask
	self.width, self.height = sprite.width, sprite.height
	---@type boolean[][]
	self.markedRegions = {}
	---@type Bitmask[][]
	self.newFragments = {}
	---@type Bitmask[][]
	self.oldFragments = {}
	---@type boolean
	self.newActive = false
	---@type boolean
	self.oldActive = bitmask._active
	---@type boolean
	self.newIncludeMimic = false
	---@type boolean
	self.oldIncludeMimic = sprite.spriteState.includeMimic
	---@type boolean
	self.newIncludeBitmask = false
	---@type boolean
	self.oldIncludeBitmask = sprite.spriteState.includeBitmask

	self.relevantLayer = sprite.spriteState.layer:get()
	self.relevantFrame = sprite.spriteState.frame:get()
end

function SelectionCommand:markRegion(x, y, w, h)
	local regions = self.markedRegions
	local newFragments = self.newFragments
	local oldFragments = self.oldFragments
	local sw, sh = self.bitmask.width, self.bitmask.height

	-- Don't mark out of bounds
	if x >= sw or x + w <= 0 or y >= sh or y + h <= 0 then return end

	local maxI, maxJ =
		math.ceil(sw / SelectionCommand.GRID_SIZE) - 1,
		math.ceil(sh / SelectionCommand.GRID_SIZE) - 1


	for i = math.max(0, math.min(maxI, math.floor(x / SelectionCommand.GRID_SIZE))), math.min(maxI, math.floor((x + w - 1) / SelectionCommand.GRID_SIZE)) do
		if regions[i] == nil then
			regions[i] = {}
			newFragments[i] = {}
			oldFragments[i] = {}
		end

		for j = math.max(0, math.min(maxJ, math.floor(y / SelectionCommand.GRID_SIZE))), math.min(maxJ, math.floor((y + h - 1) / SelectionCommand.GRID_SIZE)) do
			if regions[i][j] ~= true then
				regions[i][j] = true

				-- Also copy this into a fragment
				local oldFragment = SelectionCommand._getFragment()
				oldFragments[i][j] = oldFragment

				oldFragment:paste(self.bitmask, 0, 0, i * SelectionCommand.GRID_SIZE, j * SelectionCommand.GRID_SIZE, SelectionCommand.GRID_SIZE, SelectionCommand.GRID_SIZE)
			end
		end
	end
end

---Completes the DrawCommand so that it can be performed
function SelectionCommand:completeMark()
	local sprite, sourceBitmask = self.sprite, self.bitmask

	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % SelectionCommand.GRID_SIZE, h % SelectionCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / SelectionCommand.GRID_SIZE),
		math.floor(h / SelectionCommand.GRID_SIZE)

	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local newBitmaskFrag = SelectionCommand:_getFragment()
			self.newFragments[x][y] = newBitmaskFrag

			local wCount, hCount =
				(x == outerX and outerW) or SelectionCommand.GRID_SIZE,
				(y == outerY and outerH) or SelectionCommand.GRID_SIZE

			local offsetX, offsetY =
				x * SelectionCommand.GRID_SIZE,
				y * SelectionCommand.GRID_SIZE

			-- Copy the new data
			newBitmaskFrag:paste(sourceBitmask, 0, 0, offsetX, offsetY, wCount, hCount)
		end
	end

	self.newActive = sourceBitmask._active
	self.newIncludeMimic = sprite.spriteState.includeMimic
	self.newIncludeBitmask = sprite.spriteState.includeBitmask
	sprite.spriteState.bitmaskRenderer:update()
end

function SelectionCommand:undo()
	-- Copy the old data into the cel
	local sprite, sourceBitmask = self.sprite, self.bitmask
	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % SelectionCommand.GRID_SIZE, h % SelectionCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / SelectionCommand.GRID_SIZE),
		math.floor(h / SelectionCommand.GRID_SIZE)


	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local oldBitmaskFrag = self.oldFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or SelectionCommand.GRID_SIZE,
				(y == outerY and outerH) or SelectionCommand.GRID_SIZE

			sourceBitmask:paste(oldBitmaskFrag, x * SelectionCommand.GRID_SIZE, y * SelectionCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	sourceBitmask:setActive(self.oldActive)
	sprite.spriteState.includeMimic = self.oldIncludeMimic
	if self.oldIncludeMimic then
		SelectionCommand.SpriteTool.updateCanvas()
	end
	sprite.spriteState.includeBitmask = self.oldIncludeBitmask
	sprite.spriteState.bitmaskRenderer:update()
end

function SelectionCommand:perform()
	-- Copy the new data into the cel
	local sprite, sourceBitmask = self.sprite, self.bitmask
	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % SelectionCommand.GRID_SIZE, h % SelectionCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / SelectionCommand.GRID_SIZE),
		math.floor(h / SelectionCommand.GRID_SIZE)


	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local newBitmaskFrag = self.newFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or SelectionCommand.GRID_SIZE,
				(y == outerY and outerH) or SelectionCommand.GRID_SIZE

			sourceBitmask:paste(newBitmaskFrag, x * SelectionCommand.GRID_SIZE, y * SelectionCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	sourceBitmask:setActive(self.newActive)
	sprite.spriteState.includeMimic = self.newIncludeMimic
	if self.newIncludeMimic then
		SelectionCommand.SpriteTool.updateCanvas()
	end
	sprite.spriteState.includeBitmask = self.newIncludeBitmask
	sprite.spriteState.bitmaskRenderer:update()
end

function SelectionCommand:hasChanges()
	for _, arr in pairs(self.markedRegions) do
		-- Return true if there's any changes
		for _, _ in pairs(arr) do return true end
	end
	return false
end

function DrawCommand:getPosition()
	return self.relevantLayer, self.relevantFrame
end

function SelectionCommand:release()
	-- Might error due to commands not being completed
	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			SelectionCommand._returnFragment(self.oldFragments[x][y])
			SelectionCommand._returnFragment(self.newFragments[x][y])
		end
		self.oldFragments[x] = nil
		self.newFragments[x] = nil
	end
	self.markedRegions = nil
	self.oldFragments = nil
	self.newFragments = nil
end

return SelectionCommand
