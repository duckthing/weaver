local ffi = require "ffi"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local Blend = require "plugins.sprite.common.blend"
local SelectionTransformCommand = require "plugins.sprite.commands.selectiontransformcommand"
local SelectionCommand = require "plugins.sprite.commands.selectioncommand"
local LiftCommand = require "plugins.sprite.commands.liftcommand"
local cleanedge -- lazy loaded

---@class BaseSelectionTool: SpriteTool
local BaseSelectionTool = SpriteTool:extend()

SelectionTransformCommand.SpriteTool = SpriteTool
LiftCommand.SpriteTool = SpriteTool
SelectionCommand.SpriteTool = SpriteTool

---@alias BaseSelectionTool.Operation
---| "set"
---| "add"
---| "subtract"
---| "intersect"

---Returns the desired operation from key presses
---@return BaseSelectionTool.Operation
function BaseSelectionTool:getOperation()
	if love.keyboard.isDown("lctrl") then
		return "subtract"
	elseif love.keyboard.isDown("lshift") then
		return "add"
	else
		return "set"
	end
end

local mode = nil
local startX, startY = 0, 0

function BaseSelectionTool:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index then
		if cleanedge == nil then
			cleanedge = require "plugins.sprite.common.cleanedge"
		end

		local sprite = SpriteTool.sprite
		local canvas = SpriteTool.canvas
		if not sprite or not canvas then return end
		local spriteState = sprite.spriteState

		local bitmask = spriteState.bitmask
		if not bitmask._active then return end

		-- local buff = sprite.spriteState.mimicCanvas

		-- local bx, by, bright, bbottom = bitmask:getBounds()
		local offsetX, offsetY = canvas.imageX, canvas.imageY

		--[[ local bw, bh =
			bright - bx + 1,
			bbottom - by + 1 --]]

		-- local width, height = sprite.width, sprite.height
		local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY
		offsetX = offsetX + selectionX
		offsetY = offsetY + selectionY

		-- Disable the resize handles for now
		--[[ if not mode then
			-- Draw the resize handles
			local handleOffset = 16 / canvas.scale
			local handleSize = 12 / canvas.scale
			love.graphics.rectangle("fill", bx + offsetX + handleOffset + bw - handleSize, by + offsetY + handleOffset + bh - handleSize, handleSize, handleSize)
			love.graphics.rectangle("fill", bx + offsetX - handleOffset                  , by + offsetY + handleOffset + bh - handleSize, handleSize, handleSize)
			love.graphics.rectangle("fill", bx + offsetX + handleOffset + bw - handleSize, by + offsetY - handleOffset                  , handleSize, handleSize)
			love.graphics.rectangle("fill", bx + offsetX - handleOffset                  , by + offsetY - handleOffset                  , handleSize, handleSize)
		end --]]
	end
	return mode ~= nil
end

---@type SelectionTransformCommand
local tranformCommand

function BaseSelectionTool:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return false end

	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	if not bitmask._active then return false end

	if BaseSelectionTool:getOperation() ~= "set" then return end

	tranformCommand = SelectionTransformCommand(sprite)

	local bx, by, bright, bbottom = bitmask:getBounds()

	local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY
	do
		local ix, iy = imageX - selectionX, imageY - selectionY
		if not (ix >= bx and ix <= bright and iy >= by and iy <= bbottom) or not bitmask:get(ix, iy) then
			-- Not inside or on an area
			return false
		end
	end

	mode = "move"
	-- spriteState.selectionX, spriteState.selectionY = 0, 0
	-- rotation = 0

	-- BaseSelectionTool.liftIntoSelection()
	spriteState.includeMimic = true
	SpriteTool.drawing = true

	startX, startY = imageX - selectionX, imageY - selectionY
	return true
end

function BaseSelectionTool:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return false end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask

	if bitmask._active and mode then
		if mode == "move" then
			spriteState.selectionX = imageX - startX
			spriteState.selectionY = imageY - startY
		end
		SpriteTool.updateCanvas()
		return true
	end

	return false
end

function BaseSelectionTool:stopPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return false end
	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask

	if bitmask._active and mode then
		if mode == "move" then
			spriteState.selectionX = imageX - startX
			spriteState.selectionY = imageY - startY
			tranformCommand:completeTransform()
			sprite.undoStack:commit(tranformCommand)
			tranformCommand = nil
			SpriteTool.updateCanvas()

			-- BaseSelectionTool.applyFromSelection()

			-- spriteState.selectionX = 0
			-- spriteState.selectionY = 0
		end
		mode = nil
		SpriteTool.drawing = false
		return true
	end

	return false
end

return BaseSelectionTool
