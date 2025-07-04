local ffi = require "ffi"
local Context = require "src.data.context"
local Action = require "src.data.action"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Modal = require "src.global.modal"
local ResizeSprite = require "plugins.sprite.objects.resizesprite"
local ImageBrush = require "plugins.sprite.brush.imagebrush"
local BrushProperty = require "plugins.sprite.properties.brushp"
local Status = require "src.global.status"
local Palettes = require "src.global.palettes"
local Handler = require "src.global.handler"

local BucketFillCommand = require "plugins.sprite.commands.bucketfillcommand"
local SelectionCommand = require "plugins.sprite.commands.selectioncommand"
local RemapCelCommand = require "plugins.sprite.commands.remapcelcommand"
local InsertFrameCommand = require "plugins.sprite.commands.insertframecommand"
local InsertLayerCommand = require "plugins.sprite.commands.insertlayercommand"
local SwapLayersCommand = require "plugins.sprite.commands.swaplayerscommand"
local SwapFramesCommand = require "plugins.sprite.commands.swapframescommand"

local SpriteKeybinds = require "plugins.sprite.context.spritekeybinds"

---@class SpriteEditor.Context: Context
local SpriteEditorContext = Context:extend()
SpriteEditorContext.CONTEXT_NAME = "SpriteEditor"

---@type {[string]: Action}
local actions = {
	undo = Action(
		"Undo",
		function(_, _, _, context)
			---@type Sprite
			local sprite = context.sprite
			if sprite then
				-- print("===== START UNDO")
				local wasDrawing = SpriteTool.drawing
				if wasDrawing then
					SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
				end

				sprite.undoStack:undo()

				if wasDrawing then
					SpriteTool.currentTool:startPress(SpriteTool.lastX, SpriteTool.lastY)
				end
			end
		end
	),
	redo = Action(
		"Redo",
		function(_, _, _, context)
			---@type Sprite
			local sprite = context.sprite
			if sprite then
				-- print("===== START REDO")
				if not SpriteTool.drawing then
					sprite.undoStack:redo()
				end
			end
		end
	),

	select_tool_1 = Action(
		"Select Tool 1",
		function(_, _, _, _)
			SpriteTool.spriteTools[1]:selectTool()
		end
	),
	select_tool_2 = Action(
		"Select Tool 2",
		function(_, _, _, _)
			SpriteTool.spriteTools[2]:selectTool()
		end
	),
	select_tool_3 = Action(
		"Select Tool 3",
		function(_, _, _, _)
			SpriteTool.spriteTools[3]:selectTool()
		end
	),
	select_tool_4 = Action(
		"Select Tool 4",
		function(_, _, _, _)
			SpriteTool.spriteTools[4]:selectTool()
		end
	),
	select_tool_5 = Action(
		"Select Tool 5",
		function(_, _, _, _)
			SpriteTool.spriteTools[5]:selectTool()
		end
	),
	select_tool_6 = Action(
		"Select Tool 6",
		function(_, _, _, _)
			SpriteTool.spriteTools[6]:selectTool()
		end
	),
	grow_brush = Action(
		"Increase Brush Size",
		function(_, _, _, _)
			local brush = SpriteTool.brush:get()
			if brush then
				brush:grow(1)
			end
		end
	),
	shrink_brush = Action(
		"Shrink Brush Size",
		function(_, _, _, _)
			local brush = SpriteTool.brush:get()
			if brush then
				brush:shrink(1)
			end
		end
	),
	new_frame = Action(
		"Add Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local frameProperty = sprite.spriteState.frame
				local newFrameIndex = frameProperty:get() + 1
				local newFrame = sprite:createFrame(newFrameIndex)
				local insertCommand = InsertFrameCommand(sprite, true, newFrame)
				frameProperty:set(newFrameIndex)
				sprite.undoStack:commitWithoutPerforming(insertCommand)
			end
		end
	),
	clone_frame = Action(
		"Clone Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local wasDrawing = SpriteTool.drawing
				if wasDrawing then
					SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
				end

				local frameProperty = sprite.spriteState.frame
				local toCloneIndex = frameProperty:get()
				local newFrame = sprite:cloneFrame(toCloneIndex, toCloneIndex + 1)
				local insertCommand = InsertFrameCommand(sprite, true, newFrame)
				frameProperty:set(toCloneIndex + 1)
				sprite.undoStack:commitWithoutPerforming(insertCommand)

				if wasDrawing then
					SpriteTool.currentTool:startPress(SpriteTool.lastX, SpriteTool.lastY)
				end
			end
		end
	),
	clone_linked_frame = Action(
		"Clone Linked Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local wasDrawing = SpriteTool.drawing
				if wasDrawing then
					SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
				end

				local frameProperty = sprite.spriteState.frame
				local toCloneIndex = frameProperty:get()
				local newFrame = sprite:createFrame(toCloneIndex + 1)

				for i = 1, #sprite.layers do
					local layer = sprite.layers[i]
					layer.celIndices[toCloneIndex + 1] = layer.celIndices[toCloneIndex]
				end

				local insertCommand = InsertFrameCommand(sprite, true, newFrame)
				frameProperty:set(toCloneIndex + 1)
				sprite.undoStack:commitWithoutPerforming(insertCommand)

				if wasDrawing then
					SpriteTool.currentTool:startPress(SpriteTool.lastX, SpriteTool.lastY)
				end
			end
		end
	),
	delete_frame = Action(
		"Delete Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				if #sprite.frames <= 1 then return end
				local frameProperty = sprite.spriteState.frame
				local toDeleteIndex = frameProperty:get()
				local frame = sprite.frames[toDeleteIndex]
				local insertCommand = InsertFrameCommand(sprite, false, frame)
				sprite:removeFrame(toDeleteIndex)
				frameProperty:set(toDeleteIndex - 1)
				sprite.undoStack:commitWithoutPerforming(insertCommand)
			end
		end
	),
	inspect_frame = Action(
		"Inspect Frame",
		function (_, _, _, context)
			---@type Sprite
			local sprite = context.sprite
			if sprite then
				local frameIndex = sprite.spriteState.frame:get()
				local frame = sprite.frames[frameIndex]

				if frame then
					Modal.pushInspector(frame)
				end
			end
		end
	),
	new_layer = Action(
		"Add Layer",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				local newLayerIndex = layerProperty:get() + 1
				local layer = sprite:createLayer(newLayerIndex)
				local insertCommand = InsertLayerCommand(sprite, true, layer)
				sprite.undoStack:commitWithoutPerforming(insertCommand)
				layerProperty:set(newLayerIndex)
			end
		end
	),
	clone_layer = Action(
		"Clone Layer",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				local toCloneIndex = layerProperty:get()
				local clonedLayer = sprite:cloneLayer(toCloneIndex)
				local insertCommand = InsertLayerCommand(sprite, true, clonedLayer)
				sprite.undoStack:commitWithoutPerforming(insertCommand)
				layerProperty:set(toCloneIndex + 1)
			end
		end
	),
	delete_layer = Action(
		"Delete Layer",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				if #sprite.layers <= 1 then return end
				local _, removedLayer = sprite:removeLayer(sprite.spriteState.layer:get())
				local insertCommand = InsertLayerCommand(sprite, false, removedLayer)
				sprite.undoStack:commitWithoutPerforming(insertCommand)
			end
		end
	),
	inspect_layer = Action(
		"Inspect Layer",
		function (_, _, _, context)
			---@type Sprite
			local sprite = context.sprite
			if sprite then
				local layerIndex = sprite.spriteState.layer:get()
				local layer = sprite.layers[layerIndex]

				if layer then
					Modal.pushInspector(layer)
				end
			end
		end
	),
	merge_layer_down = Action(
		"Merge Layer Down",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local currLayerIndex = sprite.spriteState.layer:get()
				if currLayerIndex > 0 and currLayerIndex < #sprite.layers then
					local topLayer = sprite.layers[currLayerIndex]
					local bottomLayer = sprite.layers[currLayerIndex + 1]
					sprite.undoStack:pushGroup()
					local newLayer = sprite:mergeLayers(topLayer, bottomLayer)
					sprite.undoStack:commitWithoutPerforming(InsertLayerCommand(sprite, true, newLayer))
					sprite.undoStack:commitWithoutPerforming(InsertLayerCommand(sprite, false, topLayer))
					sprite.undoStack:commitWithoutPerforming(InsertLayerCommand(sprite, false, bottomLayer))
					sprite.undoStack:popGroup()
				end
			end
		end
	),
	select_next_frame = Action(
		"Select Next Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local frameProperty = sprite.spriteState.frame
				frameProperty:set(frameProperty:get() + 1)
			end
		end
	),
	select_previous_frame = Action(
		"Select Previous Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local frameProperty = sprite.spriteState.frame
				frameProperty:set(frameProperty:get() - 1)
			end
		end
	),
	select_first_frame = Action(
		"Select First Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				sprite.spriteState.frame:set(1)
			end
		end
	),
	select_last_frame = Action(
		"Select Last Frame",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				sprite.spriteState.frame:set(#sprite.frames)
			end
		end
	),
	move_frame_left = Action(
		"Move Frame Left",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local frameProperty = sprite.spriteState.frame
				local frameIndex = frameProperty:get()
				if frameIndex > 1 then
					---@type SwapFramesCommand
					local swapCommand = SwapFramesCommand(sprite, sprite.frames[frameIndex], sprite.frames[frameIndex - 1])
					sprite.undoStack:commit(swapCommand)
				end
			end
		end
	),
	move_frame_right = Action(
		"Move Frame Right",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local frameProperty = sprite.spriteState.frame
				local frameIndex = frameProperty:get()
				if frameIndex < #sprite.frames then
					---@type SwapFramesCommand
					local swapCommand = SwapFramesCommand(sprite, sprite.frames[frameIndex], sprite.frames[frameIndex + 1])
					sprite.undoStack:commit(swapCommand)
				end
			end
		end
	),
	select_higher_layer = Action(
		"Select Higher Layer",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				layerProperty:set(layerProperty:get() - 1)
			end
		end
	),
	select_lower_layer = Action(
		"Select Lower Layer",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				layerProperty:set(layerProperty:get() + 1)
			end
		end
	),
	move_layer_up = Action(
		"Move Layer Up",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				local layerIndex = layerProperty:get()
				if layerIndex > 1 then
					-- Can move upwards (down 1 index)
					sprite:swapLayers(layerIndex, layerIndex - 1)
					sprite.undoStack:commitWithoutPerforming(
						SwapLayersCommand(
							sprite,
							sprite.layers[layerIndex],
							sprite.layers[layerIndex - 1]
						)
					)
					layerProperty:set(layerIndex - 1)
				end
			end
		end
	),
	move_layer_down = Action(
		"Move Layer Down",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerProperty = sprite.spriteState.layer
				local layerIndex = layerProperty:get()
				if layerIndex < #sprite.layers and #sprite.layers > 1 then
					-- Can move downwards (up 1 index)
					sprite:swapLayers(layerIndex, layerIndex + 1)
					sprite.undoStack:commitWithoutPerforming(
						SwapLayersCommand(
							sprite,
							sprite.layers[layerIndex],
							sprite.layers[layerIndex + 1]
						)
					)
					layerProperty:set(layerIndex + 1)
				end
			end
		end
	),
	save_palette = Action(
		"Save Palette",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette then
					Handler.promptForSaving(
						palette,
						Palettes.paletteDirectories[1]..(("palette_%d"):format(#Palettes.globalPalettes + 1))..".gpl"
					)
				end
			end
		end
	),
	toggle_palette_lock = Action(
		"Toggle Palette Lock",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette then
					palette.locked = not palette.locked
				end
			end
		end
	),
	remove_primary_color_from_palette = Action(
		"Remove Primary Color from Palette",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette then
					if not palette.locked then
						local spriteState = sprite.spriteState

						local primaryColor = spriteState.primaryColorSelection
						local p = primaryColor.palette
						local index = primaryColor:getIndex()

						if p and index ~= 0 and #p.colors > 1 then
							p:removeColorAtIndex(index)
							primaryColor:setColorByIndex(math.min(#p.colors, index))
							spriteState.secondaryColorSelection:setColorByIndex(spriteState.secondaryColorSelection:getIndex())
						end
					else
						Status.pushTemporaryMessage("Unlock this palette first")
					end
				end
			end
		end
	),
	add_primary_color_to_palette = Action(
		"Add Primary Color to Palette",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette then
					if not palette.locked then
						local spriteState = sprite.spriteState

						local primaryColor = spriteState.primaryColorSelection
						local p = primaryColor.palette
						local color = primaryColor:getColor()

						if p and #p.colors <= 256 then
							local index = primaryColor:getIndex()
							if index == 0 then index = #p.colors end

							local newColor = {}

							for i = 1, #color do
								newColor[i] = color[i]
							end

							p:addColor(newColor, index + 1)
							primaryColor:setColorByIndex(index + 1)
							spriteState.secondaryColorSelection:setColorByIndex(spriteState.secondaryColorSelection:getIndex())
						end
					else
						Status.pushTemporaryMessage("Unlock this palette first")
					end
				end
			end
		end
	),
	swap_primary_with_secondary_color = Action(
		"Swap Primary With Secondary Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local primary, secondary =
					sprite.spriteState.primaryColorSelection, sprite.spriteState.secondaryColorSelection
				local pIndex, sIndex =
					primary:getIndex(),
					secondary:getIndex()
				local secondaryColor = secondary:getColor()

				-- Swap with the index, or by value if there is no index
				if pIndex and pIndex ~= 0 then
					secondary:setColorByIndex(pIndex)
				else
					secondary:setColorByValue(primary:getColor())
				end

				if sIndex and sIndex ~= 0 then
					primary:setColorByIndex(sIndex)
				else
					primary:setColorByValue(secondaryColor)
				end
			end
		end
	),
	select_previous_primary_color = Action(
		"Select Previous Primary Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette and #palette.colors > 0 then
					local spriteState = sprite.spriteState
					local primary = spriteState.primaryColorSelection
					local pIndex = primary:getIndex()

					if pIndex and pIndex > 1 then
						-- Index exists
						primary:setColorByIndex(pIndex - 1)
					else
						-- Start at the last index
						primary:setColorByIndex(#palette.colors)
					end
				end
			end
		end
	),
	select_next_primary_color = Action(
		"Select Next Primary Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette and #palette.colors > 0 then
					local spriteState = sprite.spriteState
					local primary = spriteState.primaryColorSelection
					local pIndex = primary:getIndex()

					if pIndex then
						-- Index exists
						primary:setColorByIndex((pIndex % #palette.colors) + 1)
					else
						-- Start at the first index
						primary:setColorByIndex(1)
					end
				end
			end
		end
	),
	select_previous_secondary_color = Action(
		"Select Previous Secondary Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette and #palette.colors > 0 then
					local spriteState = sprite.spriteState
					local secondary = spriteState.secondaryColorSelection
					local sIndex = secondary:getIndex()

					if sIndex and sIndex > 1 then
						-- Index exists
						secondary:setColorByIndex(sIndex - 1)
					else
						-- Start at the last index
						secondary:setColorByIndex(#palette.colors)
					end
				end
			end
		end
	),
	select_next_secondary_color = Action(
		"Select Next Secondary Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local palette = sprite.palette:get()
				if palette and #palette.colors > 0 then
					local spriteState = sprite.spriteState
					local secondary = spriteState.secondaryColorSelection
					local sIndex = secondary:getIndex()

					if sIndex then
						-- Index exists
						secondary:setColorByIndex((sIndex % #palette.colors) + 1)
					else
						-- Start at the first index
						secondary:setColorByIndex(1)
					end
				end
			end
		end
	),
	delete_cel = Action(
		"Delete Cel",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local spriteState = sprite.spriteState
				local layer, frameIndex =
					sprite.layers[spriteState.layer:get()],
					spriteState.frame:get()
				---@type RemapCelCommand
				local remapCommand = RemapCelCommand(sprite)
				remapCommand:storeOriginal(layer, frameIndex)
				layer.celIndices[frameIndex] = 0
				remapCommand:storeNew(layer, frameIndex)
				sprite.undoStack:commitWithoutPerforming(remapCommand)
				sprite.celIndexEdited:trigger()
			end
		end
	),
	unlink_cel = Action(
		"Unlink Cel",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local spriteState = sprite.spriteState
				local layer, frame =
					sprite.layers[spriteState.layer:get()],
					sprite.frames[spriteState.frame:get()]
				---@type RemapCelCommand
				local remapCommand = RemapCelCommand(sprite)
				remapCommand:storeOriginal(layer, frame.index)
				sprite:unlinkCel(layer, frame)
				remapCommand:storeNew(layer, frame.index)
				sprite.undoStack:commitWithoutPerforming(remapCommand)
				sprite.celIndexEdited:trigger()
			end
		end
	),
	resize_canvas = Action(
		"Resize Canvas",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				Modal.pushInspector(ResizeSprite(sprite))
			end
		end
	),
	crop_to_content = Action(
		"Crop to Content",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local w, h = sprite.width, sprite.height
				local left = w
				local top = h
				local right = -1
				local bottom = -1

				sprite.undoStack:pushGroup()
				SpriteTool.applyFromSelection()
				for _, cel in ipairs(sprite:getUsedCels()) do
					local cx, cy, cright, cbottom = cel:getContentBounds()
					if cx == -1 then goto continue end

					left = math.min(left, cx)
					top = math.min(top, cy)
					right = math.max(right, cright)
					bottom = math.max(bottom, cbottom)

					::continue::
				end

				local newW, newH =
					right - left + 1,
					bottom - top + 1
				if newW > 0 and newH > 0 then
					sprite:resize(newW, newH, -left, -top)
				end
				-- SpriteTool.liftIntoSelection()
				sprite.undoStack:popGroup()
			end
		end
	),
	crop_to_selection = Action(
		"Crop to Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local spriteState = sprite.spriteState
				local bitmask = spriteState.bitmask
				if not bitmask._active then return end

				local left, top, _, _, newW, newH = spriteState.bitmask:getBounds()
				if newW <= 0 or newH <= 0 then return end
				local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY

				sprite.undoStack:pushGroup()
				SpriteTool.applyFromSelection()
				if newW > 0 and newH > 0 then
					sprite:resize(newW, newH, -(left + selectionX), -(top + selectionY))
				end
				-- SpriteTool.liftIntoSelection()
				sprite.undoStack:popGroup()
			end
		end
	),
	fit_sprite= Action(
		"Fit Sprite",
		function(_, _, _, context)
			---@type SpriteEditor?
			local editor = context.editor
			if editor then
				local canvas = editor.container.canvasUI
				canvas:fitSprite()
			end
		end
	),
	toggle_layer_lock = Action(
		"Toggle Layer Lock",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerIndex = sprite.spriteState.layer:get()
				local layer = sprite.layers[layerIndex]
				if layer then
					layer.locked:toggle()
				end
			end
		end
	),
	toggle_layer_visible = Action(
		"Toggle Layer Visibility",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerIndex = sprite.spriteState.layer:get()
				local layer = sprite.layers[layerIndex]
				if layer then
					layer.visible:toggle()
				end
			end
		end
	),
	toggle_layer_link = Action(
		"Toggle Layer Link",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local layerIndex = sprite.spriteState.layer:get()
				local layer = sprite.layers[layerIndex]
				if layer then
					layer.preferLinkedCels:toggle()
				end
			end
		end
	),
	toggle_all_layer_lock = Action(
		"Toggle All Layer Lock",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local newLocked = not sprite.layers[1].locked:get()
				for i = 1, #sprite.layers do
					sprite.layers[i].locked:set(newLocked)
				end
			end
		end
	),
	toggle_all_layer_visible = Action(
		"Toggle All Layer Visibility",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local newVisible = not sprite.layers[1].visible:get()
				for i = 1, #sprite.layers do
					sprite.layers[i].visible:set(newVisible)
				end
			end
		end
	),
	toggle_all_layer_link = Action(
		"Toggle All Layer Link",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local newLinked = not sprite.layers[1].preferLinkedCels:get()
				for i = 1, #sprite.layers do
					sprite.layers[i].preferLinkedCels:set(newLinked)
				end
			end
		end
	),
	select_all = Action(
		"Select All",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local spriteState = sprite.spriteState
				sprite.undoStack:pushGroup()
				---@type SelectionCommand
				local command = SelectionCommand(sprite, spriteState.bitmask)
				command:markRegion(0, 0, sprite.width - 1, sprite.height - 1)
				spriteState.bitmask:reset(true)
				spriteState.bitmask:setActive(true)
				spriteState.includeBitmask = true
				command:completeMark()
				sprite.undoStack:commit(command)
				SpriteTool.onBitmaskChanged()
				SpriteTool.liftIntoSelection()
				sprite.undoStack:popGroup()
			end
		end
	),
	invert_selection = Action(
		"Invert Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				SpriteTool.applyFromSelection()
				local bitmask = sprite.spriteState.bitmask
				---@type SelectionCommand
				local command = SelectionCommand(sprite, bitmask)
				command:markRegion(0, 0, sprite.width - 1, sprite.height - 1)
				bitmask:setActive(true)
				bitmask:invert()
				command:completeMark()
				sprite.undoStack:commit(command)
				SpriteTool.liftIntoSelection()
			end
		end
	),
	delete_inside_selection = Action(
		"Delete Inside Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local spriteState = sprite.spriteState
				local bitmask = sprite.spriteState.bitmask
				local layer, frameIndex =
					sprite.layers[spriteState.layer:get()],
					spriteState.frame:get()
				local currentCelIndex = layer.celIndices[frameIndex]

				-- Do nothing if this cel doesn't exist
				if currentCelIndex == 0 then return end

				if bitmask._active then
					sprite.undoStack:pushGroup()
					local cel = spriteState.selectionCel
					local id = ffi.cast("uint8_t*", cel.data:getFFIPointer())
					local width, height = sprite.width, sprite.height
					local liftCommand = SpriteTool.liftIntoSelection()
					liftCommand.transientUndo = false
					liftCommand.transientRedo = true
					---@type BucketFillCommand
					local command = BucketFillCommand(sprite, cel)
					command.transientUndo = true
					-- ---@type SelectionCommand
					-- local selectionCommand = SelectionCommand(sprite, bitmask)

					-- Check every bit, and reset it if it's inside
					local bx, by, bright, bbottom, bw, bh = bitmask:getBounds()
					-- selectionCommand:markRegion(bx, by, bw, bh)

					for x = bx, bright do
						for y = by, bbottom do
							if bitmask:get(x, y) then
								command:markPixel(x, y)
								local index = (x + y * width) * 4
								id[index    ] = 0
								id[index + 1] = 0
								id[index + 2] = 0
								id[index + 3] = 0
							end
						end
					end

					-- bitmask:reset(false)
					-- bitmask:setActive(false)
					command:completeMark()
					-- selectionCommand:completeMark()
					sprite.undoStack:commitWithoutPerforming(command)
					-- sprite.undoStack:commitWithoutPerforming(selectionCommand)
					sprite.undoStack:popGroup()
					cel:update()
					SpriteTool.updateCanvas()
				else
					-- Delete cel
					---@type RemapCelCommand
					local remapCommand = RemapCelCommand(sprite)
					remapCommand:storeOriginal(layer, frameIndex)
					layer.celIndices[frameIndex] = 0
					remapCommand:storeNew(layer, frameIndex)
					sprite.undoStack:commitWithoutPerforming(remapCommand)
					sprite.celIndexEdited:trigger()
				end
			end
		end
	),
	clear_selection = Action(
		"Clear Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local bitmask = sprite.spriteState.bitmask
				if bitmask._active then
					sprite.undoStack:pushGroup()
					SpriteTool.applyFromSelection()
					---@type SelectionCommand
					local command = SelectionCommand(sprite, bitmask)
					command:markRegion(0, 0, sprite.width - 1, sprite.height - 1)
					bitmask:setActive(false)
					bitmask:reset()
					command:completeMark()
					sprite.undoStack:commit(command)
					sprite.undoStack:popGroup()
				end
			end
		end
	),
	set_brush_to_selection_mask = Action(
		"Set Brush to Selection Shape Mask",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local bitmask = sprite.spriteState.bitmask
				if bitmask._active then
					local newBrush = ImageBrush(sprite, "mask")
					BrushProperty.addBrush(newBrush, "Mask")
					SpriteTool.brush:set(newBrush)
					SpriteTool.spriteTools[1]:selectTool()
				end
			end
		end
	),
	set_brush_to_selection_color = Action(
		"Set Brush to Selection Image Color",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				local bitmask = sprite.spriteState.bitmask
				if bitmask._active then
					local newBrush = ImageBrush(sprite, "color")
					BrushProperty.addBrush(newBrush, "Color")
					SpriteTool.brush:set(newBrush)
					SpriteTool.spriteTools[1]:selectTool()
				end
			end
		end
	),
	copy_selection = Action(
		"Copy Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				SpriteTool.copySelection()
			end
		end
	),
	cut_selection = Action(
		"Cut Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				SpriteTool.cutSelection()
			end
		end
	),
	paste_selection = Action(
		"Paste Selection",
		function(_, _, _, context)
			---@type Sprite?
			local sprite = context.sprite
			if sprite then
				SpriteTool.pasteSelection()
			end
		end
	),
	toggle_animation = Action(
		"Toggle Animation",
		function(_, _, _, context)
			---@type SpriteEditor?
			local editor = context.editor
			if editor then
				local canvas = editor.container.canvasUI
				canvas:toggleAnimation()
			end
		end
	),
}

function SpriteEditorContext:new()
	SpriteEditorContext.super.new(self, actions, SpriteKeybinds)
	---@type SpriteEditor
	self.editor = nil -- set this in the reference
	---@type Sprite?
	self.sprite = nil
end

function SpriteEditorContext:getActions()
	return self.actions
end

function SpriteEditorContext:getKeybinds()
	return self.keybinds
end

return SpriteEditorContext
