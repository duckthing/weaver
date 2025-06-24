local ffi = require "ffi"
local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Resource = require "src.data.resource"
local Palette = require "src.data.palette"
local ExportSprite = require "plugins.sprite.objects.exportsprite"
local SaveSprite = require "plugins.sprite.objects.savesprite"
local UndoStack = require "src.data.undostack"
local ResizeCommand = require "plugins.sprite.commands.resizecommand"
local Blend = require "plugins.sprite.common.blend"

local Palettes = require "src.global.palettes"
local WgfFormat = require "src.formats.wgf"

local Inspectable = require "src.properties.inspectable"
local NumberProperty = require "src.properties.number"
local BoolProperty = require "src.properties.bool"
local PaletteProperty = require "src.properties.palette"
local StringProperty = require "src.properties.string"
local LayerNameProperty = require "plugins.sprite.properties.layernamep"
local DurationProperty = require "plugins.sprite.properties.durationp"

local spritesCreated = 0

---@type SpriteEditor
local SpriteEditor = nil

---@class Sprite.Cel: Object
local SpriteCel = Object:extend()

---@class Sprite.Layer: Inspectable
local SpriteLayer = Inspectable:extend()

---@class Sprite.Frame: Inspectable
local SpriteFrame = Inspectable:extend()

---@class Sprite: Resource
local Sprite = Resource:extend()
Sprite.TYPE = "sprite"

---Creates a new Sprite.Cel for a Sprite
---@param sprite Sprite
---@param celIndex integer
function SpriteCel:new(sprite, celIndex)
	local imageData = love.image.newImageData(sprite.width, sprite.height)
	self.data = imageData
	self.image = love.graphics.newImage(imageData)
	self.index = celIndex
	---@type boolean # Whether this cel should be considered 'used'
	self.internal = false
end

---Gets the bounds of the visible content in this Sprite.Cel.
---@return integer left
---@return integer top
---@return integer right
---@return integer bottom
function SpriteCel:getContentBounds()
	-- In case you're wondering how to get the width and height from this:
	-- w, h =
	--    right - left + 1,
	--    bottom - top + 1

	local w, h = self.data:getDimensions()
	local data = ffi.cast("uint8_t*", self.data:getFFIPointer())
	local left = -1
	local top = 0
	local right = -1
	local bottom = 0

	-- Top boundary
	for y = 0, h - 1 do
		local yOffset = y * w
		for x = 0, w - 1 do
			local index = (x + yOffset) * 4
			if data[index + 3] ~= 0 then
				top = y
				goto checkTop
			end
		end
	end
	::checkTop::

	-- Bottom boundary
	for y = h - 1, 0, -1 do
		local yOffset = y * w
		for x = 0, w - 1 do
			local index = (x + yOffset) * 4
			if data[index + 3] ~= 0 then
				bottom = y
				goto checkBottom
			end
		end
	end
	::checkBottom::

	-- Left boundary
	for x = 0, w - 1 do
		for y = top, bottom do
			local index = (x + y * w) * 4
			if data[index + 3] ~= 0 then
				left = x
				goto checkLeft
			end
		end
	end
	::checkLeft::

	-- Right boundary
	for x = w - 1, 0, -1 do
		for y = top, bottom do
			local index = (x + y * w) * 4
			if data[index + 3] ~= 0 then
				right = x
				goto checkRight
			end
		end
	end
	::checkRight::

	return left, top, right, bottom
end

---Updates the image from the changed data
function SpriteCel:update()
	self.image:release()
	self.image = love.graphics.newImage(self.data)
end

---Creates a new Sprite.Cel based off itself. You should use Sprite:cloneCel() instead.
---Will not link data to itself.
---@param sprite Sprite
---@param celIndex integer
---@return Sprite.Cel clone
function SpriteCel:clone(sprite, celIndex)
	local clone = SpriteCel(sprite, celIndex)
	clone.data = self.data:clone()
	---@diagnostic disable-next-line
	clone.image = love.graphics.newImage(clone.data)
	clone.index = celIndex
	return clone
end

---Creates a new Sprite.Layer
---@param sprite Sprite
---@param layerIndex integer
function SpriteLayer:new(sprite, layerIndex)
	SpriteLayer.super.new(self)
	---@type LayerNameProperty
	self.name = LayerNameProperty(self, "Name", ("Layer %d"):format(#sprite.layers + 1))
	---@type BoolProperty
	self.visible = BoolProperty(self, "Visible", true)
	---@type BoolProperty
	self.locked = BoolProperty(self, "Locked", false)
	---@type BoolProperty
	self.preferLinkedCels = BoolProperty(self, "Prefer Linked Cels", false)
	---@type integer
	self.index = layerIndex
	---@type table
	self.editorData = {}

	-- Zero out all cels for this frame
	local celIndices = {}
	for i = 1, #sprite.frames do
		celIndices[i] = 0
	end

	---@type integer[]
	self.celIndices = celIndices
end

---Creates a new Sprite.Layer based off itself. You should use Sprite:cloneLayer() instead.
---Will not link data to itself.
---@param sprite Sprite
---@param layerIndex integer
---@return Sprite.Layer clone
function SpriteLayer:clone(sprite, layerIndex)
	---@type Sprite.Layer
	local clone = SpriteLayer(sprite, layerIndex)
	clone.name:set(self.name:get().." copy")
	clone.visible:set(self.visible:get())
	clone.locked:set(self.locked:get())
	clone.preferLinkedCels:set(self.preferLinkedCels:get())
	clone.index = layerIndex

	-- Clone all the cels
	-- TODO: Keep cels linked relatively
	local celIndices = {}
	for i = 1, #self.celIndices do
		if self.celIndices[i] == 0 then
			celIndices[i] = 0
		else
			local newCel, newCelIndex = sprite:cloneCel(i)
			celIndices[i] = newCelIndex
		end
	end
	clone.celIndices = celIndices

	return clone
end

function SpriteLayer:getProperties()
	return {
		self.name,
		self.visible,
		self.locked,
		self.preferLinkedCels,
	}
end

---Creates a new Sprite.Frame
---@param sprite Sprite
---@param frameIndex integer
function SpriteFrame:new(sprite, frameIndex)
	SpriteFrame.super.new(self)
	---@type DurationProperty
	self.duration = DurationProperty(self, "Duration", 0.2)
	self.duration:getRange():setMin(0)
	---@type table
	self.editorData = {}
	self.index = frameIndex
end

---Creates a new Sprite.Frame based off itself.
---@param sprite Sprite
---@param frameIndex integer
---@return Sprite.Frame clone
function SpriteFrame:clone(sprite, frameIndex)
	local clone = SpriteFrame(sprite, frameIndex)
	clone.duration = self.duration
	clone.index = frameIndex
	return clone
end

function SpriteFrame:getProperties()
	return {
		self.duration
	}
end

---@param width integer # The size of the image on the X axis
---@param height integer # The size of the image on the Y axis
---@param name string? # The name of the resource
---@param palette Palette? # The palette to use
function Sprite:new(width, height, name, palette)
	spritesCreated = spritesCreated + 1
	local spriteName = name or (("sprite-%03d"):format(spritesCreated))

	---@type Sprite
	Sprite.super.new(self)
	self.name:set(spriteName)
	self.width = width
	self.height = height
	---@type love.PixelFormat
	self.format = "rgba8"
	---@type SpriteState
	self.spriteState = nil
	---@type Sprite.Layer[]
	self.layers = {}
	---@type Sprite.Frame[]
	self.frames = {}
	---@type Sprite.Cel[]
	self.cels = {}
	---@type PaletteProperty
	self.palette = PaletteProperty(self, "Palette", palette)
	---@type ExportSprite
	self.exporter = ExportSprite(self)
	---@type SaveSprite
	self.saveTemplate = SaveSprite(self)
	---@type UndoStack
	self.undoStack = UndoStack()

	self.layerCreated = Luvent.newEvent()
	self.layerInserted = Luvent.newEvent()
	self.frameCreated = Luvent.newEvent()
	self.celCreated = Luvent.newEvent()
	self.celIndexEdited = Luvent.newEvent()
	self.layerMoved = Luvent.newEvent()
	self.frameMoved = Luvent.newEvent()
	self.layerInserted = Luvent.newEvent()
	self.frameInserted = Luvent.newEvent()
	self.layerRemoved = Luvent.newEvent()
	self.frameRemoved = Luvent.newEvent()
	self.spriteResized = Luvent.newEvent()

	self:createLayer()
	self:createFrame()

	-- Update the "modified" property
	self.lastSavedIndex = self.undoStack.index + self.undoStack.totalShifted
	self.undoStack.indexChanged:addAction(function(newIndex)
		local trueIndex = newIndex + self.undoStack.totalShifted
		if trueIndex ~= self.lastSavedIndex then
			self.currentIndex = trueIndex
			self.modified:set(true)
		else
			self.modified:set(false)
		end
	end)
end

---Creates a new layer and inserts it at the optional index (default last index)
---@param insertAt integer?
---@return Sprite.Layer: layer
---@return integer: layerIndex
function Sprite:createLayer(insertAt)
	local newLayerIndex = (insertAt and math.max(1, math.min(insertAt, #self.layers + 1)))
						or #self.layers + 1
	local newLayer = SpriteLayer(self, newLayerIndex)

	-- Trigger the events
	self.layerCreated:trigger(self, newLayer, newLayerIndex)

	self:insertLayer(newLayerIndex, newLayer)
	return newLayer, newLayerIndex
end

---Creates a new Sprite.Cel and inserts it into the Sprite
---@return Sprite.Cel: newCel
---@return integer: newCelIndex
function Sprite:createCel()
	local newCelIndex = #self.cels + 1
	local newCel = SpriteCel(self, newCelIndex)
	self.cels[newCelIndex] = newCel

	self.celCreated:trigger(self, newCel, newCelIndex)
	return newCel, newCelIndex
end

---Creates a new Sprite.Cel that is used by the spriteState and updated separately
---@return Sprite.Cel: newCel
---@return integer: newCelIndex
function Sprite:createInternalCel()
	local newCel, newCelIndex = self:createCel()
	newCel.internal = true
	return newCel, newCelIndex
end

---Creates a new frame
---@param insertAt integer?
---@return Sprite.Frame: newFrame
---@return integer: newFrameIndex
function Sprite:createFrame(insertAt)
	local newFrameIndex = (insertAt and math.max(1, math.min(insertAt, #self.frames + 1)))
						or #self.frames + 1
	local newFrame = SpriteFrame(self, newFrameIndex)

	-- Trigger the events
	self.frameCreated:trigger(self, newFrame, newFrameIndex)

	self:insertFrame(newFrameIndex, newFrame)
	return newFrame, newFrameIndex
end

---Clones a cel, and returns it. Returns nil if the index doesn't exist.
---@param i integer
---@return Sprite.Cel? clonedCel
---@return integer celIndex
function Sprite:cloneCel(i)
	local originalCel = self.cels[i]
	if originalCel then
		local newIndex = #self.cels + 1
		local clone = originalCel:clone(self, newIndex)
		self.cels[newIndex] = clone
		self.celCreated:trigger(self, clone, newIndex)
		return clone, newIndex
	end
	return nil, 0
end

---Clones a layer, and returns it. Returns nil if the index doesn't exist.
---
---Cels will not be linked. They are cloned instead.
---@param toCloneIndex integer
---@param insertAt integer?
---@return Sprite.Layer? clonedLayer
---@return integer layerIndex
function Sprite:cloneLayer(toCloneIndex, insertAt)
	local originalLayer = self.layers[toCloneIndex]
	if originalLayer then
		local newIndex = (insertAt and math.max(1, math.min(insertAt, #self.layers + 1)))
						or #self.layers + 1
		local clone = originalLayer:clone(self, newIndex)

		-- Insert the cloned layer
		table.insert(self.layers, newIndex, clone)

		-- Update the indices of the later layers
		for i = newIndex + 1, #self.layers do
			self.layers[i].index = i
		end

		-- Trigger the events
		self.layerCreated:trigger(self, clone, newIndex)
		return clone, newIndex
	end
	return nil, 0
end

---Clones a frame, and returns it. Returns nil if the index doesn't exist.
---@param toCloneIndex integer
---@param insertAt integer?
---@return Sprite.Frame? clonedFrame
---@return integer frameIndex
function Sprite:cloneFrame(toCloneIndex, insertAt)
	local originalFrame = self.frames[toCloneIndex]
	if originalFrame then
		local newIndex = (insertAt and math.max(1, math.min(insertAt, #self.frames + 1)))
								or #self.frames + 1
		local clone = originalFrame:clone(self, newIndex)

		-- Trigger the events
		self.frameCreated:trigger(self, clone, newIndex)

		self:insertFrame(newIndex, clone)

		-- Set the cel indices for the new frame in each layer
		for _, layer in ipairs(self.layers) do
			local curCelIndex = layer.celIndices[toCloneIndex]
			local preferLinked = layer.preferLinkedCels:get()
			if curCelIndex == 0 then
				-- Nothing at this place
				table.insert(layer.celIndices, newIndex, 0)
			else
				-- Current cel has something
				if preferLinked then
					table.insert(layer.celIndices, newIndex, curCelIndex)
				else
					local _, clonedCelIndex = self:cloneCel(curCelIndex)
					table.insert(layer.celIndices, newIndex, clonedCelIndex)
				end
			end
		end

		return clone, newIndex
	end
	return nil, 0
end

---Swaps two layers and fires the layer moved events
---@param i integer
---@param j integer
function Sprite:swapLayers(i, j)
	local iLayer = self.layers[i]
	local jLayer = self.layers[j]
	self.layers[i], self.layers[j] = jLayer, iLayer
	iLayer.index = j
	jLayer.index = i
	-- Trigger with old layer indices
	self.layerMoved:trigger(self, iLayer, i, jLayer, j)
end

---Swaps two frames and fires the frame moved events
---@param i integer
---@param j integer
function Sprite:swapFrames(i, j)
	local iFrame = self.frames[i]
	local jFrame = self.frames[j]
	self.frames[i], self.frames[j] = jFrame, iFrame
	iFrame.index = j
	jFrame.index = i

	-- Swap the cel indices
	for _, layer in ipairs(self.layers) do
		layer.celIndices[i], layer.celIndices[j] =
			layer.celIndices[j], layer.celIndices[i]
	end

	-- Trigger with old layer indices
	self.frameMoved:trigger(self, iFrame, i, jFrame, j)
	self.celIndexEdited:trigger()
end

---Removes a layer and fires the layer removed event
---@param layerI integer
---@return boolean success
---@return Sprite.Layer? removedLayer
function Sprite:removeLayer(layerI)
	-- Only do it if there's more than 1 layer
	if #self.layers <= 1 then return false end
	local layer = self.layers[layerI]
	if layer then
		-- Remove the layer
		table.remove(self.layers, layerI)

		-- Update the layer indices
		for i = layerI, #self.layers do
			self.layers[i].index = i
		end

		-- Trigger the events
		self.layerRemoved:trigger(self, layer, layerI)
		return true, layer
	end
	return false, nil
end

---Inserts an EXISTING frame. You may be looking for Sprite:createFrame().
---@param insertAt integer
---@param existingFrame Sprite.Frame
---@return integer newFrameIndex
function Sprite:insertFrame(insertAt, existingFrame)
	local newFrameIndex = (insertAt and math.max(1, math.min(insertAt, #self.frames + 1)))
						or #self.frames + 1

	-- Insert into the array
	table.insert(self.frames, newFrameIndex, existingFrame)

	-- Update the indices of the frames
	for i = newFrameIndex + 1, #self.frames do
		self.frames[i].index = i
	end

	-- Insert the new empty cels for all layers in this frame
	for _, layer in ipairs(self.layers) do
		table.insert(layer.celIndices, newFrameIndex, 0)
	end

	-- Trigger the events
	self.frameInserted:trigger(self, existingFrame, newFrameIndex)
	return newFrameIndex
end

function Sprite:insertLayer(insertAt, existingLayer)
	local newLayerIndex = (insertAt and math.max(1, math.min(insertAt, #self.layers + 1)))
						or #self.layers + 1
	-- Insert into the layers array
	table.insert(self.layers, newLayerIndex, existingLayer)

	-- Update the indices of the later layers
	for i = newLayerIndex + 1, #self.layers do
		self.layers[i].index = i
	end

	-- Trigger the events
	self.layerInserted:trigger(self, existingLayer, newLayerIndex)
	-- self.celIndexEdited:trigger()
end

---Removes a frame and fires the frame removed event
---@param frameI integer
---@return boolean success
function Sprite:removeFrame(frameI)
	-- Only do it if there's more than 1 frame
	if #self.frames <= 1 then return false end
	local frame = self.frames[frameI]
	if frame then
		-- Remove the frame
		table.remove(self.frames, frameI)

		-- Update the frame indices
		for i = frameI, #self.frames do
			self.frames[i].index = i
		end

		-- Change the cel indices
		for _, layer in ipairs(self.layers) do
			table.remove(layer.celIndices, frameI)
		end

		-- Trigger the frame events
		self.frameRemoved:trigger(self, frame, frameI)
		return true
	end
	return false
end

---Ensures that a layer has a cel at a specific frame.
---Will not create a new layer or frame.
---@param layer Sprite.Layer
---@param frame Sprite.Frame
---@return Sprite.Cel cel
---@return integer celIndex
function Sprite:ensureCel(layer, frame)
	if frame.index <= #self.frames and layer.index <= #self.layers then
		if layer.celIndices[frame.index] == 0 then
			-- Cel doesn't exist, create it
			local cel, celIndex = self:createCel()
			layer.celIndices[frame.index] = celIndex
			return cel, celIndex
		else
			-- Return existing cel
			local celIndex = layer.celIndices[frame.index]
			return self.cels[celIndex], celIndex
		end
	end
	error(("Layer/Frame (L: %d, F: %d) is out of bounds (L: %d, F: %d)"):format(layer.index, frame.index, #self.layers, #self.frames))
end

---Unlinks a Cel so that it can be edited independently.
---Will only do this if a Cel's index is used more than once.
---@param layer Sprite.Layer
---@param frame Sprite.Frame
---@return boolean success
---@return Sprite.Cel? cel
---@return integer celIndex
function Sprite:unlinkCel(layer, frame)
	if frame.index <= #self.frames and layer.index <= #self.layers then
		if layer.celIndices[frame.index] == 0 then
			-- Cel doesn't exist, do nothing
			return false, nil, 0
		else
			-- Cel exists, check if it's used multiple times
			local celIndex = layer.celIndices[frame.index]
			local useCount = 0

			for _, i in ipairs(layer.celIndices) do
				if i == celIndex then
					useCount = useCount + 1
					if useCount > 1 then
						-- Used more than once
						break
					end
				end
			end

			if useCount > 1 then
				-- Used multiple times
				-- Unlink the cel
				local newCel, newCelIndex = self:cloneCel(celIndex)
				layer.celIndices[frame.index] = newCelIndex
				return true, newCel, newCelIndex
			else
				-- Do nothing
				return false, self.cels[celIndex], celIndex
			end
		end
	end
	error(("Layer/Frame (L: %d, F: %d) is out of bounds (L: %d, F: %d)"):format(layer.index, frame.index, #self.layers, #self.frames))
end

---Gets all of the cels that are found in a layer's cel indices array
---@return Sprite.Cel[]
function Sprite:getUsedCels()
	-- First, make a map of all the cels
	---@type {[integer]: true}
	local celIndexMap = {}

	for _, layer in ipairs(self.layers) do
		for _, celIndex in ipairs(layer.celIndices) do
			if celIndex ~= 0 and not celIndexMap[celIndex] then
				celIndexMap[celIndex] = true
			end
		end
	end

	-- Now we make an array from that map
	---@type Sprite.Cel[]
	local cels = {}

	for celIndex, _ in pairs(celIndexMap) do
		cels[#cels+1] = self.cels[celIndex]
	end

	return cels
end

---Merges two layers, putting the data from the top layer onto the bottom layer and removing the bottom
---@param topLayer Sprite.Layer
---@param bottomLayer Sprite.Layer
---@return Sprite.Layer newLayer
function Sprite:mergeLayers(topLayer, bottomLayer)
	assert(topLayer ~= nil, "Top layer is nil")
	assert(bottomLayer ~= nil, "Bottom layer is nil")
	assert(topLayer ~= bottomLayer, "Top layer is equal to bottom layer")
	assert(topLayer.index < bottomLayer.index, "Top layer is lower than the bottom layer")

	---@type Sprite.Layer
	local newLayer = self:createLayer(topLayer.index)
	newLayer.name:set(topLayer.name:get())

	---@type integer[][]
	local topToBottomNewIndices = {}
	for i = 1, #self.frames do
		local topIndex = topLayer.celIndices[i]
		local bottomIndex = bottomLayer.celIndices[i]

		if not topToBottomNewIndices[topIndex] then
			-- Make sure there's an array there
			topToBottomNewIndices[topIndex] = {}
		end

		if topToBottomNewIndices[topIndex][bottomIndex] ~= nil then
			-- Already cached this
		elseif topIndex == 0 and bottomIndex == 0 then
			-- No cels on either layer here, return 0
			topToBottomNewIndices[topIndex][bottomIndex] = 0
		elseif topIndex == 0 or bottomIndex == 0 then
			-- No mixing required; return the relevant cel index
			topToBottomNewIndices[topIndex][bottomIndex] = (topIndex ~= 0 and topIndex) or bottomIndex
		else
			-- We need to mix these cels
			local newCel = self:cloneCel(bottomIndex)
			---@cast newCel Sprite.Cel
			local otherCel = self.cels[topIndex]
			Blend.alphaBlend(newCel.data, otherCel.data, 0, 0, 0, 0, self.width, self.height)
			newCel:update()

			topToBottomNewIndices[topIndex][bottomIndex] = newCel.index
		end

		newLayer.celIndices[i] = topToBottomNewIndices[topIndex][bottomIndex]
	end

	-- Remove the old layers
	self:removeLayer(topLayer.index)
	self:removeLayer(bottomLayer.index)

	-- Force an update to select this layer
	-- TODO: Find out whhy this requires a forced update
	self.spriteState.layer:getRange().value = -1
	self.spriteState.layer:set(newLayer.index)
	return newLayer
end

---Resizes the Sprite, if the new size is different.
---
---Doesn't resize unused cels.
---@param w integer # New width
---@param h integer # New height
---@param ox integer # X offset
---@param oy integer # Y offset
function Sprite:resize(w, h, ox, oy)
	-- Return if the size is the same
	if self.width == w and self.height == h then return end

	local usedCels = self:getUsedCels()
	---@type Sprite.Cel[]
	local resizedCels = {}
	---@type {[integer]: integer}
	local oldToNewIndexMap = {}

	local oldW, oldH = self.width, self.height
	self.width, self.height =
		w, h

	for _, usedCel in ipairs(usedCels) do
		-- Paste the new data
		local newCel, newCelIndex = self:createCel()
		newCel.data:paste(usedCel.data, ox, oy, 0, 0, oldW, oldH)
		newCel.image:release()
		newCel.image = love.graphics.newImage(newCel.data)

		-- Update the map
		resizedCels[#resizedCels+1] = newCel
		oldToNewIndexMap[usedCel.index] = newCelIndex
	end

	-- Create the new cel indices for each layer
	---@type {[Sprite.Layer]: integer[]}
	local oldLayerIndices = {}
	---@type {[Sprite.Layer]: integer[]}
	local newLayerIndices = {}

	for _, layer in ipairs(self.layers) do
		-- Save the old indices
		oldLayerIndices[layer] = layer.celIndices

		-- Make the new indices
		---@type integer[]
		local newIndices = {}
		for frameIndex, oldCelIndex in ipairs(layer.celIndices) do
			if oldCelIndex ~= 0 then
				newIndices[frameIndex] = oldToNewIndexMap[oldCelIndex]
			else
				newIndices[frameIndex] = 0
			end
		end

		newLayerIndices[layer] = newIndices
	end

	-- Map the old internal cels to the new internal cels
	---@type {[string]: Sprite.Cel}
	local oldInternalCels = {}
	---@type {[string]: Sprite.Cel}
	local newInternalCels = {}
	local state = self.spriteState
	for _, key in ipairs(state.internalCelNames) do
		oldInternalCels[key] = state[key]
		local newInternalCel = self:createInternalCel()
		newInternalCels[key] = newInternalCel
	end

	-- Push the ResizeCommand (which performs the swap)
	local resizeCommand = ResizeCommand(self, oldW, oldH, w, h, oldLayerIndices, newLayerIndices, oldInternalCels, newInternalCels)
	self.undoStack:commit(resizeCommand)
end

function Sprite:removeAllActions()
	---@diagnostic disable-next-line
	Sprite.super.removeAllActions(self)
	self.layerCreated:removeAllActions()
	self.celCreated:removeAllActions()
	self.celIndexEdited:removeAllActions()
	self.frameCreated:removeAllActions()
	self.layerMoved:removeAllActions()
	self.layerRemoved:removeAllActions()
	self.frameRemoved:removeAllActions()
end

function Sprite.getWGFType()
	return "Sprite"
end

function Sprite:prepareHeaderWGF(headerTable)
	headerTable.width = self.width
	headerTable.height = self.height
end

function Sprite.deserializeWGF(headerTable, strbuf, path)
	---@type integer, integer
	local width, height = headerTable.width, headerTable.height

	-- Decode the data table
	local spriteInfo = strbuf:decode()
	---@cast spriteInfo table

	---@type boolean
	local compressed = spriteInfo.compressed
	---@type love.ImageFormat
	local format = spriteInfo.format
	---@type Sprite
	local sprite = Sprite(width, height, path:match("^.+[/\\](.+)$"))
	sprite.saveTemplate.path:set(path)
	sprite.saveTemplate.alreadySaved = true

	-- Create the cels
	for _, cel in ipairs(spriteInfo.cels) do
		---@type integer # Data size, in bytes
		local length = cel.size
		---@type integer, integer, integer, integer
		local x, y, w, h = cel.x, cel.y, cel.width, cel.height

		local data = love.image.newImageData(w, h, format)
		local dataPointer = ffi.cast("uint8_t*", data:getFFIPointer())

		-- Read the data into the love.ImageData object
		local readSize = 0
		repeat
			local pointer, size = strbuf:ref()
			if size < 1 then
				print(("Buffer ended early (read total %d of required %d)"):format(readSize, length))
				return nil, "Buffer ended before expected"
			end
			local remainingBytes = length - readSize
			local lenToRead = math.min(remainingBytes, size)

			for j = 0, lenToRead - 1 do
				dataPointer[readSize + j] = pointer[j]
			end

			readSize = readSize + lenToRead
			strbuf:skip(lenToRead)
		until readSize == length

		-- Paste the data
		local createdCel = sprite:createCel()
		createdCel.data:paste(data, x, y, 0, 0, w, h)
		createdCel.image:release()
		createdCel.image = love.graphics.newImage(createdCel.data)

		-- Release the temporary buffer
		data:release()
	end

	-- Create the frames
	for _ = 2, #spriteInfo.frames do sprite:createFrame() end

	for i, frameInfo in ipairs(spriteInfo.frames) do
		local frame = sprite.frames[i]
		frame.duration:set(frameInfo.duration)
	end

	-- Create the layers
	for _ = 2, #spriteInfo.layers do sprite:createLayer() end

	for i, layerInfo in ipairs(spriteInfo.layers) do
		local layer = sprite.layers[i]
		layer.name:set(layerInfo.name)
		layer.celIndices = layerInfo.celIndices
		layer.visible:set(layerInfo.visible)
		layer.locked:set(layerInfo.locked)
		layer.preferLinkedCels:set(layerInfo.preferLinkedCels)
	end

	-- Create the palette
	local palette
	if spriteInfo.palette and spriteInfo.palette.type == "table" then
		---@type Palette
		palette = Palette.createFromArray(spriteInfo.palette.colors)
	end
	sprite.palette:set(palette)

	sprite.exporter.imagePath:set(path)

	return sprite
end

function Sprite:serializeWGF(headerTable, strbuf)
	-- Create the Lua table with all the necessary info
	-- (we make a duplicate table with no functions, just in case)
	local framesArr = {}
	local layersArr = {}
	local celsArr = {}
	---@type table?
	local palette

	do
		local p = self.palette:get()
		if p then
			palette = {
				type = "table",
				colors = p.colors,
			}
		end
	end

	local compressed = false
	local info = {
		type = "Sprite",
		format = self.format,
		version = 1,
		compressed = compressed,
		frames = framesArr,
		layers = layersArr,
		cels = celsArr,
		palette = palette,
	}

	-- Some cels are not used, but exist in the Sprite
	-- 1. Get the used cels
	-- 2. Map their indices to the new indices
	--    * Old indices still exist in layers, which is where we use this

	---@type {[integer]: integer}
	local oldCelIndexToNew = {}
	local originalUsedCels = self:getUsedCels()

	-- Crop, compress (?), and insert the cel info
	---@type love.ImageData[]
	local celDataID = {}
	for _, cel in ipairs(originalUsedCels) do
		local x, y, right, bottom = cel:getContentBounds()
		if x == -1 then
			-- This cel has nothing in it, skip
			goto continue
		end

		local w, h =
			right - x + 1,
			bottom - y + 1

		local newCelID = love.image.newImageData(w, h, self.format)
		newCelID:paste(cel.data, 0, 0, x, y, w, h)
		celDataID[#celDataID+1] = newCelID
		oldCelIndexToNew[cel.index] = #celDataID

		celsArr[#celsArr+1] = {
			x = x,
			y = y,
			width = w,
			height = h,
			size = newCelID:getSize()
		}

		::continue::
	end

	-- Insert the frame data
	for i, frame in ipairs(self.frames) do
		framesArr[i] = {
			duration = frame.duration:get(),
		}
	end

	-- Insert the layer data
	for i, layer in ipairs(self.layers) do
		local celIndices = {}
		layersArr[i] = {
			name = layer.name:get(),
			visible = layer.visible:get(),
			locked = layer.locked:get(),
			preferLinkedCels = layer.preferLinkedCels:get(),
			celIndices = celIndices,
		}

		-- Convert the old cel index to a new one
		for j, oldCelIndex in ipairs(layer.celIndices) do
			local newIndex = oldCelIndexToNew[oldCelIndex]
			-- If the index exists, it's not skipped
			if newIndex then
				celIndices[j] = newIndex
			else
				celIndices[j] = 0
			end
		end
	end

	strbuf:encode(info)

	for _, celID in ipairs(celDataID) do
		local size = celID:getSize()
		local pointer = ffi.cast("uint8_t*", celID:getFFIPointer())
		strbuf:putcdata(pointer, size)
	end

	return true
end

WgfFormat.registerWGFType(Sprite)

do
	local PngFormat = require "plugins.sprite.formats.spritepng"
	PngFormat.setSprite(Sprite)
end

return Sprite
