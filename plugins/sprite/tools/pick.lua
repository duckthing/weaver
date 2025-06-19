local SpriteTool = require "plugins.sprite.tools.spritetool"
local PencilTool = require "plugins.sprite.tools.pencil"
local Luvent = require "lib.luvent"
local LabelProperty = require "src.properties.label"
local BoolProperty = require "src.properties.bool"

---@class SpritePick: SpriteTool
local Pick = SpriteTool:extend()

Pick.primaryColorSelected = Luvent.newEvent()

Pick.sameLayer = BoolProperty(Pick, "Same Layer", false)

function Pick:canDraw()
	return SpriteTool.cel
end

---@param imageX integer
---@param imageY integer
---@param currLayerIndex integer
function Pick:draw(imageX, imageY, currLayerIndex)
	if currLayerIndex == SpriteTool.layer.index then
		local color = SpriteTool.primaryColor
		love.graphics.setColor(color)
		love.graphics.rectangle("fill", imageX, imageY, 1, 1)
	end
end

---@param imageX integer
---@param imageY integer
function Pick:startPress(imageX, imageY)
	local sprite = SpriteTool.sprite
	if not sprite then return end
	if imageX < 0 or imageX >= sprite.width or imageY < 0 or imageY >= sprite.height then return end

	local sameLayer = Pick.sameLayer:get()

	if sameLayer then
		-- Pick the color on this layer only
		local currentCel = SpriteTool.cel
		if not currentCel then return end

		local r, g, b, a = currentCel.data:getPixel(imageX, imageY)

		if a ~= 0 then
			-- Color is visible
			Pick.primaryColorSelected:trigger(r, g, b, a)
		end
	else
		-- Start from the top, and go down the visible layers
		local currentFrameObj = SpriteTool.frame
		local currentFrame = 0

		if currentFrameObj then
			currentFrame = currentFrameObj.index
		else
			-- No frame selected
			return
		end

		for i = 1, #sprite.layers do
			local layer = sprite.layers[i]

			if layer.visible then
				-- Layer is visible
				local celIndex = layer.celIndices[currentFrame]
				if celIndex ~= 0 then
					-- Not an empty cel
					local cel = sprite.cels[celIndex]
					local r, g, b, a = cel.data:getPixel(imageX, imageY)
					if a ~= 0 then
						-- Color is visible
						Pick.primaryColorSelected:trigger(r, g, b, a)
					end
				end
			end
		end
	end

	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask

	if bitmask._active then
		-- Check the selection
		local selectionCel = spriteState.selectionCel

		local r, g, b, a = selectionCel.data:getPixel(imageX, imageY)
		if a ~= 0 then
			-- Color is visible
			Pick.primaryColorSelected:trigger(r, g, b, a)
		end
	end

	PencilTool:selectTool()
end

---@type LabelProperty
Pick.name = LabelProperty(Pick, "name", "Pick")
local properties = {
	Pick.name,
	Pick.sameLayer,
}

function Pick:getProperties()
	return properties
end

return Pick
