local ffi = require "ffi"
local Blend = require "plugins.sprite.common.blend"
local Inspectable = require "src.properties.inspectable"
local Luvent = require "lib.luvent"
local Status = require "src.global.status"
local Bitmask = require "plugins.sprite.data.bitmask"
local Context = require "src.global.contexts"
local cleanedge = require "plugins.sprite.common.cleanedge"

local LiftCommand = require "plugins.sprite.commands.liftcommand"
local SelectionCommand = require "plugins.sprite.commands.selectioncommand"
local RemapCelCommand = require "plugins.sprite.commands.remapcelcommand"
local BucketFillCommand = require "plugins.sprite.commands.bucketfillcommand"
local SelectionTransformCommand = require "plugins.sprite.commands.selectiontransformcommand"

local BrushProperty = require "plugins.sprite.properties.brushp"
local BoolProperty = require "src.properties.bool"

---@class SpriteTool: Inspectable
local SpriteTool = Inspectable:extend()

---@type SpriteTool?
SpriteTool.currentTool = nil
---@type Sprite?
SpriteTool.sprite = nil
---@type Sprite.Layer?
SpriteTool.layer = nil
---@type Sprite.Frame?
SpriteTool.frame = nil
---@type Sprite.Cel?
SpriteTool.cel = nil
---@type SpriteCanvas?
SpriteTool.canvas = nil
---@type Palette.Color
SpriteTool.primaryColor = {0., 0., 0.}
---@type Palette.Color
SpriteTool.secondaryColor = {1., 1., 1.}
---@type BrushProperty
SpriteTool.brush = BrushProperty(SpriteTool, "Brush", nil)
---@type boolean
SpriteTool.drawing = false
---@type integer, integer
SpriteTool.lastX, SpriteTool.lastY = 0, 0
---@type boolean # Whether the draw buffer should be drawn
SpriteTool.includeDrawBuffer = false

---@type BoolProperty
SpriteTool.mirrorX = BoolProperty(SpriteTool, "Mirror X", false)
---@type BoolProperty
SpriteTool.mirrorY = BoolProperty(SpriteTool, "Mirror Y", false)


SpriteTool.toolSelected = Luvent.newEvent()

---@type SpriteTool[]
SpriteTool.spriteTools = {}

function SpriteTool:register()
	SpriteTool.spriteTools[#SpriteTool.spriteTools+1] = self
end

function SpriteTool:selectTool()
	local oldTool = SpriteTool.currentTool
	local drawing = SpriteTool.drawing
	if oldTool == self then return end
	if oldTool then
		if drawing then
			oldTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
		end
		oldTool:onToolDeselected()
	end
	SpriteTool.currentTool = self
	self:onToolSelected()
	SpriteTool.toolSelected:trigger(self, oldTool)
	if drawing and self:canDraw() then
		self:startPress(SpriteTool.lastX, SpriteTool.lastY)
	end
end

function SpriteTool:onToolSelected()
end

function SpriteTool:onToolDeselected()
end

---Returns whether the tool can draw on the current cel
---@return boolean
function SpriteTool:canDraw()
	local layer = SpriteTool.layer
	local locked = (layer and layer.locked:get()) or false
	local visible = (layer and layer.visible:get()) or false

	if locked then
		Status.pushTemporaryMessage("Can't draw on locked layer", nil, 3)
	elseif not visible then
		Status.pushTemporaryMessage("Can't draw on hidden layer", nil, 3)
	end

	return SpriteTool.sprite ~= nil and layer ~= nil and not locked and visible
end

---Transforms two points to the desired points, such as mirroring a point
---@param ax integer
---@param ay integer
---@param bx integer
---@param by integer
---@param callback fun(ax: integer, ay: integer, bx: integer, by: integer, ...)
---@param ... unknown
function SpriteTool:transformToCanvas(ax, ay, bx, by, callback, ...)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	local mirrorX, mirrorY = SpriteTool.mirrorX:get(), SpriteTool.mirrorY:get()
	local width, height = sprite.width, sprite.height
	local halfW, halfH =
		math.floor(width * 0.5),
		math.floor(height * 0.5)

	local offsetX, offsetY =
		(width + 1) % 2,
		(height + 1) % 2

	local relAX, relAY, relBX, relBY =
		math.floor(ax - halfW + offsetX),
		math.floor(ay - halfH + offsetY),
		math.floor(bx - halfW + offsetX),
		math.floor(by - halfH + offsetY)

	-- TODO: Make mirroring smarter
	if mirrorX and mirrorY then
		for xMult = -1, 1, 2 do
			for yMult = -1, 1, 2 do
				callback(
					relAX * xMult + halfW + ((xMult == 1 and -offsetX) or 0),
					relAY * yMult + halfH + ((yMult == 1 and -offsetY) or 0),
					relBX * xMult + halfW + ((xMult == 1 and -offsetX) or 0),
					relBY * yMult + halfH + ((yMult == 1 and -offsetY) or 0),
					...
				)
			end
		end
	elseif mirrorX then
		for xMult = -1, 1, 2 do
			callback(
				relAX * xMult + halfW + ((xMult == 1 and -offsetX) or 0),
				ay,
				relBX * xMult + halfW + ((xMult == 1 and -offsetX) or 0),
				by,
				...
			)
		end
	elseif mirrorY then
		for yMult = -1, 1, 2 do
			callback(
				ax,
				relAY * yMult + halfH + ((yMult == 1 and -offsetY) or 0),
				bx,
				relBY * yMult + halfH + ((yMult == 1 and -offsetY) or 0),
				...
			)
		end
	else
		callback(ax, ay, bx, by, ...)
	end
end

---Draws the tool
---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function SpriteTool:draw(imageX, imageY, currLayerIndex)
end

---Called when the pointer is began to be pressed
---@param imageX integer
---@param imageY integer
function SpriteTool:startPress(imageX, imageY)
end

---Called when the pointer is still pressed
---@param imageX integer
---@param imageY integer
function SpriteTool:pressing(imageX, imageY)
end

---Called when the pointer is no longer pressing
---@param imageX integer
---@param imageY integer
function SpriteTool:stopPress(imageX, imageY)
end

---Selects a new layer
---@param i integer
function SpriteTool:selectLayer(i)
	local newLayerIndex = math.max(1, math.min(i, #SpriteTool.sprite.layers))
	local newLayer = SpriteTool.sprite.layers[newLayerIndex]

	local wasDrawing = SpriteTool.drawing
	if wasDrawing then
		-- Commit the current draw command
		wasDrawing = true
		SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
	end

	local midStep = SpriteTool.sprite.undoStack.midStep
	if not midStep then
		if SpriteTool.cel then
			-- The old cel
			SpriteTool.applyFromSelection()
		end
	end

	SpriteTool.layer = newLayer
	SpriteTool.cel = SpriteTool.sprite.cels[newLayer.celIndices[SpriteTool.frame.index]]

	if wasDrawing then
		-- Continue drawing again
		SpriteTool.currentTool:startPress(SpriteTool.lastX, SpriteTool.lastY)
	end
end

---Switches to a new frame
---@param i integer
function SpriteTool:selectFrame(i)
	local newFrameIndex = math.max(1, math.min(i, #SpriteTool.sprite.frames))
	local newFrame = SpriteTool.sprite.frames[newFrameIndex]

	local wasDrawing = SpriteTool.drawing
	if wasDrawing then
		-- Commit the current draw command
		wasDrawing = true
		SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
	end

	local midStep = SpriteTool.sprite.undoStack.midStep
	if not midStep then
		if SpriteTool.cel then
			-- The old cel
			SpriteTool.applyFromSelection()
		end
	end

	SpriteTool.frame = newFrame
	SpriteTool.cel = SpriteTool.sprite.cels[SpriteTool.layer.celIndices[newFrameIndex]]

	if wasDrawing then
		-- Continue drawing again
		SpriteTool.currentTool:startPress(SpriteTool.lastX, SpriteTool.lastY)
	end
end

---Ensures that a cel exists before editing it
function SpriteTool:ensureCel()
	local sprite = SpriteTool.sprite
	if sprite then
		---@type RemapCelCommand
		local remapCommand = RemapCelCommand(sprite)
		local layer, frame = SpriteTool.layer, SpriteTool.frame
		if not layer or not frame then return end

		remapCommand:storeOriginal(layer, frame.index)
		local cel, _ = sprite:ensureCel(layer, frame)
		remapCommand:storeNew(layer, frame.index)
		SpriteTool.cel = cel
		sprite.undoStack:commitWithoutPerforming(remapCommand)
	end
end

---@type ColorSelectionProperty?
SpriteTool.primaryProperty = nil
---@type ColorSelectionProperty?
SpriteTool.secondaryProperty = nil
---@type IntegerProperty?
SpriteTool.layerProperty = nil
---@type IntegerProperty?
SpriteTool.frameProperty = nil

---@type string?
SpriteTool._primaryCSChanged = nil
---@type string?
SpriteTool._secondaryCSChanged = nil
---@type string?
SpriteTool._layerChanged = nil
---@type string?
SpriteTool._frameChanged = nil

---Binds the SpriteTool to the specified properties
---@param sprite Sprite
---@param primaryProperty ColorSelectionProperty
---@param secondaryProperty ColorSelectionProperty
---@param layerProperty IntegerProperty
---@param frameProperty IntegerProperty
function SpriteTool:bindToProperties(
	sprite,
	primaryProperty, secondaryProperty,
	layerProperty, frameProperty
)
	SpriteTool.sprite = sprite
	if SpriteTool._primaryCSChanged then
		SpriteTool.primaryProperty.valueChanged:removeAction(SpriteTool._primaryCSChanged)
		SpriteTool._primaryCSChanged = nil

		SpriteTool.secondaryProperty.valueChanged:removeAction(SpriteTool._secondaryCSChanged)
		SpriteTool._secondaryCSChanged = nil

		SpriteTool.layerProperty.valueChanged:removeAction(SpriteTool._layerChanged)
		SpriteTool._layerChanged = nil

		SpriteTool.frameProperty.valueChanged:removeAction(SpriteTool._frameChanged)
		SpriteTool._frameChanged = nil
	end

	-- Primary color
	SpriteTool.primaryProperty = primaryProperty
	if primaryProperty then
		SpriteTool._primaryCSChanged = primaryProperty.valueChanged:addAction(function(property, value)
			SpriteTool.primaryColor = value
		end)
		SpriteTool.primaryColor = primaryProperty:getColor()
	end

	-- Secondary color
	SpriteTool.secondaryProperty = secondaryProperty
	if secondaryProperty then
		SpriteTool._secondaryCSChanged = secondaryProperty.valueChanged:addAction(function(property, value)
			SpriteTool.secondaryColor = value
		end)
		SpriteTool.secondaryColor = secondaryProperty:getColor()
	end

	-- Layer
	SpriteTool.layerProperty = layerProperty
	if layerProperty then
		SpriteTool._layerChanged = layerProperty.valueChanged:addAction(function(property, value)
			SpriteTool:selectLayer(value)
		end)
		SpriteTool.layer = sprite.layers[layerProperty:get()]
	end

	-- Frame
	SpriteTool.frameProperty = frameProperty
	if frameProperty then
		SpriteTool._frameChanged = frameProperty.valueChanged:addAction(function(property, value)
			SpriteTool:selectFrame(value)
		end)
		SpriteTool.frame = sprite.frames[frameProperty:get()]
	end

	if SpriteTool.layer then
		SpriteTool.cel = sprite.cels[SpriteTool.layer.celIndices[SpriteTool.frame.index]]
	end
end

local texPixelSize = {1, 1}
function SpriteTool.updateCanvas()
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local spriteState = sprite.spriteState

	local bitmask = spriteState.bitmask
	-- if not bitmask._active then return end

	local buff = sprite.spriteState.mimicCanvas

	local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY
	-- The selection origin
	local ox, oy = spriteState.selectionOriginX, spriteState.selectionOriginY
	local width, height = sprite.width, sprite.height
	-- spriteState.selectionCel:update()

	-- Draw the canvas
	love.graphics.push("all")
	love.graphics.setCanvas(buff)
	love.graphics.setScissor()
	love.graphics.origin()
	love.graphics.clear()
	love.graphics.setShader(cleanedge)
	-- In Godot, it's 1/dimension (1 / width, 1 / height)
	texPixelSize[1], texPixelSize[2] =
		1 / width,
		1 / height
	local scaleX, scaleY = spriteState.selectionScaleX, spriteState.selectionScaleY
	cleanedge:send("TEXTURE_PIXEL_SIZE", texPixelSize)
	if bitmask._active then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(
			spriteState.selectionCel.image,
			selectionX + ox, selectionY + oy,
			spriteState.selectionRotation,
			scaleX, scaleY,
			ox, oy
		)
	end
	love.graphics.pop()
end

---@return SelectionTransformCommand?
function SpriteTool.onBitmaskChanged()
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local spriteState = sprite.spriteState

	---@type SelectionTransformCommand
	local command = SelectionTransformCommand(sprite)

	do
		local bleft, btop, _, _, bw, bh = sprite.spriteState.bitmask:getBounds()
		local centerX = math.floor(bleft + bw * 0.5)
		local centerY = math.floor(btop + bh * 0.5)
		spriteState.selectionOriginX, spriteState.selectionOriginY =
			centerX, centerY

		spriteState.selectionX = 0
		spriteState.selectionY = 0
		spriteState.selectionScaleX = 1
		spriteState.selectionScaleY = 1
		spriteState.selectionRotation = 0
	end

	command:completeTransform()
	sprite.undoStack:commitWithoutPerforming(command)
	return command
end

---Returns true if there's a complex transformation (ex. scaled, but not moved)
---@return boolean transformed
function SpriteTool.isSelectionTransformed()
	local sprite = SpriteTool.sprite
	if not sprite then return false end
	local spriteState = sprite.spriteState

	return
		(spriteState.selectionScaleX ~= 1) or (spriteState.selectionScaleY ~= 1)
		or
		(spriteState.selectionRotation ~= 0)
end

---@return LiftCommand?
function SpriteTool.liftIntoSelection()
	local sprite = SpriteTool.sprite
	local cel = SpriteTool.cel
	if not sprite or not cel then return end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not bitmask._active then return end

	local bx, by, bright, bbottom = bitmask:getBounds()

	---@type LiftCommand
	local liftCommand = LiftCommand(sprite, cel)
	-- liftCommand.transientUndo = false
	liftCommand:markRegion(bx, by, bright, bbottom)

	-- Copy into the selection cel
	local selectCel = sprite.spriteState.selectionCel
	local celP = ffi.cast("uint8_t*", cel.data:getFFIPointer())
	local selectP = ffi.cast("uint8_t*", selectCel.data:getFFIPointer())
	local width = sprite.width

	for x = bx, bright do
		for y = by, bbottom do
			if bitmask:get(x, y) then
				local i = (x + y * width) * 4
				selectP[i    ] = celP[i    ]
				selectP[i + 1] = celP[i + 1]
				selectP[i + 2] = celP[i + 2]
				selectP[i + 3] = celP[i + 3]

				celP[i    ] = 0
				celP[i + 1] = 0
				celP[i + 2] = 0
				celP[i + 3] = 0
			end
		end
	end

	spriteState.includeMimic = true

	liftCommand:completeMark()
	sprite.undoStack:commit(liftCommand)

	spriteState.selectionX = 0
	spriteState.selectionY = 0

	cel:update()
	selectCel:update()
	SpriteTool.updateCanvas()

	return liftCommand
end

---Applies a selection if it exists
---@return LiftCommand?
---@return SelectionCommand?
function SpriteTool.applyFromSelection()
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not bitmask._active then return end
	SpriteTool:ensureCel()
	local cel = SpriteTool.cel
	if not cel then return end

	sprite.undoStack:pushGroup()

	-- Clear the region
	local bx, by, bright, bbottom, bw, bh = bitmask:getBounds()
	local selectCel = spriteState.selectionCel
	local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY

	---@type LiftCommand
	local liftCommand = LiftCommand(sprite, cel)
	liftCommand.transientUndo = true
	liftCommand.transientRedo = true

	-- If this transformation requires updating the selection image itself (ex. scaling and rotating, not moving)
	local isDestructive = SpriteTool.isSelectionTransformed()

	local data
	if isDestructive then
		data = spriteState.mimicCanvas:newImageData()
		liftCommand:markRegion(0, 0, data:getDimensions())
		Blend.alphaBlend(cel.data, data, 0, 0, 0, 0, data:getDimensions())
	else
		liftCommand:markRegion(selectionX + bx, selectionY + by, bw, bh)
		Blend.alphaBlend(cel.data, selectCel.data, selectionX + bx, selectionY + by, bx, by, bw, bh)
	end

	local width = sprite.width
	local selectP = ffi.cast("uint8_t*", selectCel.data:getFFIPointer())

	-- Clear selection image
	for x = bx, bright do
		for y = by, bbottom do
			if bitmask:get(x, y) then
				local i = (x + y * width) * 4
				selectP[i    ] = 0
				selectP[i + 1] = 0
				selectP[i + 2] = 0
				selectP[i + 3] = 0
			end
		end
	end

	---@type SelectionCommand
	local selectionCommand = SelectionCommand(sprite, bitmask)
	selectionCommand:markRegion(bx, by, bw, bh)

	-- Update the selection if destructive
	if isDestructive then
		bitmask:reset()
		local w, h = data:getDimensions()
		local dataP = ffi.cast("uint8_t*", data:getFFIPointer())

		-- Set the bitmask for each new pixel
		for x = 0, w - 1 do
			for y = 0, h - 1 do
				local imageIndex = (x + y * w) * 4

				if dataP[imageIndex + 3] ~= 0 then
					bitmask:set(x, y, true)
					selectionCommand:markRegion(x, y, 1, 1)
				end
			end
		end

		sprite.spriteState.includeBitmask = true
		data:release()

		local selTransCommand = SpriteTool.onBitmaskChanged()
		if selTransCommand then
			selTransCommand.allowRenderState = false
		end
	else
		-- Just shift it
		selectionCommand:markRegion(bx + selectionX, by + selectionY, bw + selectionX, bh + selectionY)
		bitmask:shift(selectionX, selectionY)
	end

	spriteState.includeMimic = false

	liftCommand:completeMark()
	sprite.undoStack:commit(liftCommand)

	cel:update()
	selectCel:update()
	SpriteTool.updateCanvas()

	selectionCommand.transientUndo = true
	selectionCommand.transientRedo = true

	selectionCommand:completeMark()
	sprite.undoStack:commit(selectionCommand)
	sprite.undoStack:popGroup()

	spriteState.bitmaskRenderer:update()

	return liftCommand, (selectionCommand:hasChanges() and selectionCommand) or nil
end

---@class SpriteTool.CopiedSelection
---@field data love.ImageData
---@field bitmask Bitmask

---@type SpriteTool.CopiedSelection?
local selection = nil
function SpriteTool.copySelection()
	local sprite = SpriteTool.sprite
	local cel = SpriteTool.cel
	if not sprite or not cel then return end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not bitmask._active then return end

	local sourceCel = spriteState.selectionCel
	local bx, by, _, _, bw, bh = bitmask:getBounds()
	local newBitmask = Bitmask.new(bw, bh)
	newBitmask:paste(bitmask, 0, 0, bx, by, bw, bh)

	local data = love.image.newImageData(bw, bh, sprite.format)
	data:paste(sourceCel.data, 0, 0, bx, by, bw, bh)

	if selection then
		selection.data:release()
		selection = nil
	end

	selection = {
		data = data,
		bitmask = newBitmask,
	}
end

function SpriteTool.cutSelection()
	local sprite = SpriteTool.sprite
	local cel = SpriteTool.cel
	if not sprite or not cel then return end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not bitmask._active then return end

	sprite.undoStack:pushGroup()
	SpriteTool.copySelection()
	Context.raiseAction("delete_inside_selection")
	Context.raiseAction("clear_selection")
	sprite.undoStack:popGroup()
end

function SpriteTool.pasteSelection()
	local sprite = SpriteTool.sprite
	SpriteTool:ensureCel()
	local cel = SpriteTool.cel
	if not sprite or not cel then return end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not selection then return end

	local selectionCel = spriteState.selectionCel
	sprite.undoStack:pushGroup()
	SpriteTool.applyFromSelection()
	---@type SelectionCommand
	local selectionCommand = SelectionCommand(sprite, bitmask)
	selectionCommand:markRegion(0, 0, bitmask.width, bitmask.height)
	bitmask:reset(false)
	bitmask:paste(selection.bitmask, 0, 0, 0, 0, selection.bitmask.width, selection.bitmask.height)
	bitmask._active = true
	-- spriteState.includeSelection = true
	selectionCommand:completeMark()

	---@type BucketFillCommand
	local bucketCommand = BucketFillCommand(sprite, selectionCel)
	bucketCommand:markRegion(0, 0, sprite.width, sprite.height)

	do
		-- Clear the cel
		local dataP = ffi.cast("uint8_t*", selectionCel.data:getFFIPointer())
		for i = 0, selectionCel.data:getSize() - 1 do
			dataP[i] = 0
		end
	end

	selectionCel.data:paste(selection.data, 0, 0, 0, 0, selectionCel.data:getDimensions())
	bucketCommand:completeMark()
	selectionCel:update()
	spriteState.bitmaskRenderer:update()

	sprite.undoStack:commitWithoutPerforming(selectionCommand)
	sprite.undoStack:commitWithoutPerforming(bucketCommand)
	sprite.undoStack:popGroup()
end

function SpriteTool:getProperties()
	return {
		SpriteTool.brush,
		SpriteTool.mirrorX,
		SpriteTool.mirrorY,
	}
end

return SpriteTool
