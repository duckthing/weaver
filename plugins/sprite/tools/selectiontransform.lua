local ffi = require "ffi"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local LabelProperty = require "src.properties.label"
local DrawCommand = require "plugins.sprite.commands.drawcommand"
local EnumProperty = require "src.properties.enum"

---@class SelectionTransformTool: SpriteTool
local Transform = SpriteTool:extend()

---@alias SelectionTransformTool.Mode
---| "scale"
---| "rotate"

---@type DrawCommand
local command = nil

---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function Transform:draw(imageX, imageY, currLayerIndex)
end

local startX, startY = 0, 0

---@param imageX integer
---@param imageY integer
function Transform:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	startX, startY = imageX, imageY
	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
	SpriteTool.drawing = true
end

---@param imageX integer
---@param imageY integer
function Transform:pressing(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end

	---@type SelectionTransformTool.Mode
	local mode = Transform.mode:getValue()
	local diffX, diffY = imageX - startX, imageY - startY

	if mode == "rotate" then
		local centerX, centerY
		do
			local bleft, btop, _, _, bw, bh = sprite.spriteState.bitmask:getBounds()
			centerX = math.floor(bleft + bw * 0.5)
			centerY = math.floor(btop + bh * 0.5)
		end

		local originalAngle = math.atan2((startY - centerY), (startX - centerX))
		local newAngle = math.atan2((imageY - centerY), (imageX - centerX))
		sprite.spriteState.selectionRotation = newAngle - originalAngle
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
		SpriteTool.applyFromSelection()
	end
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
