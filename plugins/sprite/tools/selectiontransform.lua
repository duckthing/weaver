local ffi = require "ffi"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local LabelProperty = require "src.properties.label"
local DrawCommand = require "plugins.sprite.commands.drawcommand"
local EnumProperty = require "src.properties.enum"
local SelectionTransformCommand = require "plugins.sprite.commands.selectiontransformcommand"

---@class SelectionTransformTool: SpriteTool
local Transform = SpriteTool:extend()

---@alias SelectionTransformTool.Mode
---| "scale"
---| "rotate"

---@type SelectionTransformCommand
local command = nil

---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function Transform:draw(imageX, imageY, currLayerIndex)
end

local startX, startY = 0, 0
local startRot = 0

---@param imageX integer
---@param imageY integer
function Transform:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	startX, startY = imageX, imageY
	startRot = sprite.spriteState.selectionRotation
	command = SelectionTransformCommand(sprite)

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
	SpriteTool.drawing = true
	sprite.spriteState.includeBitmask = false
	sprite.spriteState.includeMimicOutline = true
end

---@param imageX integer
---@param imageY integer
function Transform:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	local spriteState = sprite.spriteState

	---@type SelectionTransformTool.Mode
	local mode = Transform.mode:getValue()
	-- local diffX, diffY = imageX - startX, imageY - startY
	local selectionX, selectionY = spriteState.selectionX, spriteState.selectionY

	if mode == "rotate" then
		local centerX, centerY = sprite.spriteState.selectionOriginX, sprite.spriteState.selectionOriginY

		local originalAngle = math.atan2((startY - centerY - selectionY), (startX - centerX - selectionX))
		local newAngle = math.atan2((imageY - centerY - selectionY), (imageX - centerX - selectionX))
		local angleDiff = newAngle - originalAngle
		local startRotation = startRot

		if love.keyboard.isDown("lctrl") then
			local stepAmount = math.rad(45)
			if love.keyboard.isDown("lshift") then
				stepAmount = math.rad(15)
			end
			if angleDiff < 0 then
				angleDiff = angleDiff + math.rad(360)
			end

			angleDiff = angleDiff - math.fmod(
				angleDiff + stepAmount * 0.5,
				stepAmount
			) + stepAmount * 0.5
		end

		sprite.spriteState.selectionRotation = angleDiff + startRotation
		SpriteTool.updateCanvas()
	end

	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
end

---@param imageX integer
---@param imageY integer
function Transform:stopPress(imageX, imageY)
	if not SpriteTool.drawing then return end
	local sprite = SpriteTool.sprite
	SpriteTool.drawing = false
	if not sprite then return end

	---@type SelectionTransformTool.Mode
	local mode = Transform.mode:getValue()

	if mode == "rotate" then
		-- SpriteTool.applyFromSelection()
	end

	command:completeTransform()
	sprite.undoStack:commitWithoutPerforming(command)
	command = nil
end

---@type LabelProperty
Transform.name = LabelProperty(Transform, "Name", "Selection Transform")
---@type EnumProperty
Transform.mode = EnumProperty(Transform, "Mode", nil)
Transform.mode:setOptions(
	{
		{
			name = "Scale",
			value = "scale",
		},
		{
			name = "Rotate",
			value = "rotate",
		},
		{
			name = "Move",
			value = "move",
		},
	}
)
local properties = {
	Transform.name,
	Transform.mode,
}

function Transform:getProperties()
	return properties
end

return Transform
