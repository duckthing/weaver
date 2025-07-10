local SpriteTool = require "plugins.sprite.tools.spritetool"
local BaseSelectionTool = require "plugins.sprite.tools.baseselectiontool"
local LabelProperty = require "src.properties.label"
local SelectionCommand = require "plugins.sprite.commands.selectioncommand"

---@class SpriteRectMarquee: BaseSelectionTool
local RectMarquee = BaseSelectionTool:extend()

local startX, startY = 0, 0

--[[ local invertShaderCode = [[
extern Image canvas;

vec4 effect(vec4 color, Image texture, vec2 texturePos, vec2 screenPos)
{
	return vec4(Texel(canvas, screenPos).rgb, 1.f);
}
]] --]]
-- local invertShader = love.graphics.newShader(invertShaderCode)

function RectMarquee:draw(imageX, imageY, currLayerIndex)
	if BaseSelectionTool.draw(RectMarquee, imageX, imageY, currLayerIndex) then return end
	if currLayerIndex == SpriteTool.layer.index then
		local sprite = SpriteTool.sprite
		local canvas = SpriteTool.canvas
		if not sprite or not canvas then return end

		if SpriteTool.drawing then
			local sx, sy, ex, ey = startX, startY, SpriteTool.lastX, SpriteTool.lastY
			if ex < sx then sx, ex = ex, sx end
			if ey < sy then sy, ey = ey, sy end
			local w, h =
				math.max(ex - sx, 0) + 1,
				math.max(ey - sy, 0) + 1
			--[[ local oldShader = love.graphics.getShader()
			love.graphics.setShader(invertShader)
			invertShader:send("canvas", love.graphics.getCanvas()) --]]
			love.graphics.push()
			love.graphics.translate(canvas.imageX, canvas.imageY)
			love.graphics.setColor(0, 0, 0, 0.6)
			-- love.graphics.setLineWidth(0.5)
			love.graphics.rectangle("fill", sx, sy, w, h)
			-- love.graphics.setLineWidth(0)
			love.graphics.pop()
			-- love.graphics.setShader(oldShader)
		end
	end
end

---@param imageX integer
---@param imageY integer
function RectMarquee:startPress(imageX, imageY)
	if BaseSelectionTool.startPress(RectMarquee, imageX, imageY) then return end

	startX, startY = imageX, imageY
	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
	SpriteTool.drawing = true
end

---@param imageX integer
---@param imageY integer
function RectMarquee:pressing(imageX, imageY)
	if BaseSelectionTool.pressing(RectMarquee, imageX, imageY) then return end

	local sprite = SpriteTool.sprite
	if not sprite then return end
	SpriteTool.lastX, SpriteTool.lastY = imageX, imageY
end

---@param imageX integer
---@param imageY integer
function RectMarquee:stopPress(imageX, imageY)
	if BaseSelectionTool.stopPress(RectMarquee, imageX, imageY) then return end
	if not SpriteTool.drawing then return end
	local sprite = SpriteTool.sprite
	if not sprite then return end

	sprite.undoStack:pushGroup()

	local spriteState = sprite.spriteState
	local bitmask = spriteState.bitmask
	local sx, sy, ex, ey = startX, startY, SpriteTool.lastX, SpriteTool.lastY
	if ex < sx then sx, ex = ex, sx end
	if ey < sy then sy, ey = ey, sy end
	local w, h =
		math.max(ex - sx + 1, 1),
		math.max(ey - sy + 1, 1)

	SpriteTool.applyFromSelection()

	---@type SelectionCommand
	local command = SelectionCommand(sprite, sprite.spriteState.bitmask)
	bitmask:setActive(true)
	-- -@type LiftCommand?
	local liftCommand
	local operation = BaseSelectionTool:getOperation()
	if operation == "subtract" then
		command:markRegion(sx, sy, w, h)
		bitmask:markRegion(sx, sy, w, h, false)
		liftCommand = SpriteTool.liftIntoSelection()
	elseif operation == "add" then
		command:markRegion(sx, sy, w, h)
		bitmask:markRegion(sx, sy, w, h, true)
		liftCommand = SpriteTool.liftIntoSelection()
	elseif operation == "set" then
		if w == 1 and h == 1 then
			-- Too small to be useful, disable selections
			command:markRegion(0, 0, sprite.width, sprite.height)
			bitmask:setActive(false)
			bitmask:reset()
		else
			command:markRegion(0, 0, sprite.width, sprite.height)
			bitmask:reset()
			bitmask:markRegion(sx, sy, w, h, true)
			liftCommand = SpriteTool.liftIntoSelection()
		end
	end

	if liftCommand then
		command.transientUndo = true
		command.transientRedo = false
		liftCommand.transientUndo = false
	end

	do
		-- Check if it's empty now
		local _, _, _, _, bw, bh = bitmask:getBounds()
		if bw == 0 or bh == 0 then
			-- It is empty
			bitmask:setActive(false)
			sprite.spriteState.includeBitmask = false
		else
			SpriteTool.onBitmaskChanged()
			sprite.spriteState.includeBitmask = true
		end
	end

	command:completeMark()
	sprite.undoStack:commit(command)
	sprite.undoStack:popGroup()

	SpriteTool.updateCanvas()
	SpriteTool.drawing = false
end

---@type LabelProperty
RectMarquee.name = LabelProperty(RectMarquee, "Name", "Rectangle Marquee")
local properties = {
	RectMarquee.name,
}

function RectMarquee:getProperties()
	return properties
end

return RectMarquee
