local SpriteCommand = require "plugins.sprite.commands.spritecommand"
local DrawCommand = require "plugins.sprite.commands.drawcommand"

---@class LiftCommand: SpriteCommand
local LiftCommand = SpriteCommand:extend()
LiftCommand.CLASS_NAME = "LiftCommand"
LiftCommand.transientRedo = true
LiftCommand.transientUndo = true
---@type SpriteTool
LiftCommand.SpriteTool = nil

---@param sprite Sprite
---@param cel Sprite.Cel
function LiftCommand:new(sprite, cel)
	LiftCommand.super.new(self, sprite)
	self.cel = cel

	local state = sprite.spriteState

	---@type boolean[][]
	self.markedRegions = {}
	---@type love.ImageData[][]
	self.newSelectionFragments = {}
	---@type love.ImageData[][]
	self.oldSelectionFragments = {}
	---@type love.ImageData[][]
	self.newCelFragments = {}
	---@type love.ImageData[][]
	self.oldCelFragments = {}

	self.oldX, self.oldY = state.selectionX, state.selectionY
	self.oldIncludeMimic = state.includeMimic
	self.newIncludeMimic = false

	self.relevantLayer = state.layer:get()
	self.relevantFrame = state.frame:get()
end

function LiftCommand:markRegion(x, y, w, h)
	local celData = self.cel.data
	local selectionData = self.sprite.spriteState.selectionCel.data
	local format = celData:getFormat()
	local regions = self.markedRegions

	local newSelectionFragments = self.newSelectionFragments
	local oldSelectionFragments = self.oldSelectionFragments
	local newCelFragments = self.newCelFragments
	local oldCelFragments = self.oldCelFragments

	local sw, sh = self.sprite.width, self.sprite.height

	-- Don't mark out of bounds
	if x >= sw or x + w <= 0 or y >= sh or y + h <= 0 then return end

	local maxI, maxJ =
		math.ceil(sw / DrawCommand.GRID_SIZE) - 1,
		math.ceil(sh / DrawCommand.GRID_SIZE) - 1

	for i = math.max(0, math.min(maxI, math.floor(x / DrawCommand.GRID_SIZE))), math.min(maxI, math.floor((x + w - 1) / DrawCommand.GRID_SIZE)) do
		if regions[i] == nil then
			regions[i] = {}
			newSelectionFragments[i] = {}
			oldSelectionFragments[i] = {}
			newCelFragments[i] = {}
			oldCelFragments[i] = {}
		end

		for j = math.max(0, math.min(maxJ, math.floor(y / DrawCommand.GRID_SIZE))), math.min(maxJ, math.floor((y + h - 1) / DrawCommand.GRID_SIZE)) do
			if regions[i][j] ~= true then
				regions[i][j] = true

				local oldSelectionFragment = DrawCommand:_getFragment()
				oldSelectionFragment:paste(selectionData, 0, 0, i * DrawCommand.GRID_SIZE, j * DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE)
				oldSelectionFragments[i][j] = oldSelectionFragment

				local oldCelFragment = DrawCommand:_getFragment()
				oldCelFragment:paste(celData, 0, 0, i * DrawCommand.GRID_SIZE, j * DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE, DrawCommand.GRID_SIZE)
				oldCelFragments[i][j] = oldCelFragment
			end
		end
	end
end

---Completes the LiftCommand so that it can be performed
function LiftCommand:completeMark()
	local sprite, cel = self.sprite, self.cel

	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % DrawCommand.GRID_SIZE, h % DrawCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / DrawCommand.GRID_SIZE),
		math.floor(h / DrawCommand.GRID_SIZE)
	local celID = cel.data
	local selectionID = sprite.spriteState.selectionCel.data

	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local newCelFragmentID = DrawCommand:_getFragment()
			local newSelectionFragmentID = DrawCommand:_getFragment()
			self.newCelFragments[x][y] = newCelFragmentID
			self.newSelectionFragments[x][y] = newSelectionFragmentID

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			local offsetX, offsetY =
				x * DrawCommand.GRID_SIZE,
				y * DrawCommand.GRID_SIZE

			-- Blending and copy has already occurred

			-- Copy the new data
			newCelFragmentID:paste(celID, 0, 0, offsetX, offsetY, wCount, hCount)
			newSelectionFragmentID:paste(selectionID, 0, 0, offsetX, offsetY, wCount, hCount)
		end
	end

	self.newIncludeMimic = sprite.spriteState.includeMimic
end

function LiftCommand:undo()
	-- Copy the old data into the cel
	local sprite, cel = self.sprite, self.cel
	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % DrawCommand.GRID_SIZE, h % DrawCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / DrawCommand.GRID_SIZE) + 1,
		math.floor(h / DrawCommand.GRID_SIZE) + 1

	local celID = cel.data
	local selectionID = sprite.spriteState.selectionCel.data

	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local oSelectionFragmentID = self.oldSelectionFragments[x][y]
			local oCelFragmentID = self.oldCelFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			celID:paste(oCelFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
			selectionID:paste(oSelectionFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	cel:update()
	sprite.spriteState.selectionCel:update()

	sprite.spriteState.selectionX = self.oldX
	sprite.spriteState.selectionY = self.oldY
	sprite.spriteState.includeMimic = self.oldIncludeMimic
	if self.oldIncludeMimic then
		LiftCommand.SpriteTool.updateCanvas()
	end
end

function LiftCommand:perform()
	-- Copy the new data into the cel
	local sprite, cel = self.sprite, self.cel
	local w, h = sprite.width, sprite.height
	local outerW, outerH =
		w % DrawCommand.GRID_SIZE, h % DrawCommand.GRID_SIZE
	local outerX, outerY =
		math.floor(w / DrawCommand.GRID_SIZE),
		math.floor(h / DrawCommand.GRID_SIZE)

	local celID = cel.data
	local selectionID = sprite.spriteState.selectionCel.data

	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			-- Runs per marked region
			local nSelectionFragmentID = self.newSelectionFragments[x][y]
			local nCelFragmentID = self.newCelFragments[x][y]

			local wCount, hCount =
				(x == outerX and outerW) or DrawCommand.GRID_SIZE,
				(y == outerY and outerH) or DrawCommand.GRID_SIZE

			celID:paste(nCelFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
			selectionID:paste(nSelectionFragmentID, x * DrawCommand.GRID_SIZE, y * DrawCommand.GRID_SIZE, 0, 0, wCount, hCount)
		end
	end

	cel:update()
	sprite.spriteState.selectionCel:update()
	sprite.spriteState.selectionX = 0
	sprite.spriteState.selectionY = 0
	sprite.spriteState.includeMimic = self.newIncludeMimic
	if self.newIncludeMimic then
		LiftCommand.SpriteTool.updateCanvas()
	end
end

function LiftCommand:hasChanges()
	for _, arr in pairs(self.markedRegions) do
		-- Return true if there's any changes
		for _, _ in pairs(arr) do return true end
	end
	return false
end

function LiftCommand:release()
	-- Might error due to commands not being completed
	for x, arr in pairs(self.markedRegions) do
		for y, _ in pairs(arr) do
			DrawCommand._returnFragment(self.oldCelFragments[x][y])
			DrawCommand._returnFragment(self.newCelFragments[x][y])
			DrawCommand._returnFragment(self.oldSelectionFragments[x][y])
			DrawCommand._returnFragment(self.newSelectionFragments[x][y])
		end
		self.oldCelFragments[x] = nil
		self.newCelFragments[x] = nil
		self.oldSelectionFragments[x] = nil
		self.newSelectionFragments[x] = nil
	end
	self.markedRegions = nil
	self.oldCelFragments = nil
	self.newCelFragments = nil
	self.oldSelectionFragments = nil
	self.newSelectionFragments = nil
end

function LiftCommand:getPosition()
	return self.relevantLayer, self.relevantFrame
end

return LiftCommand
