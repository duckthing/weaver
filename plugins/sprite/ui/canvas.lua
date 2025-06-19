local Viewport = require "ui.components.viewport"
local SpriteTool = require "plugins.sprite.tools.spritetool"

---@class SpriteCanvas: Viewport
local Canvas = Viewport:extend()

local pointerCursor = love.mouse.getSystemCursor("crosshair")

local minScale = 0.25
local maxScale = 96

local scales = {
	0.25, 0.5,
	1,
	2, 3, 4, 5, 6,
	9, 12, 18, 24, 36, 54, 81,
}

---Chooses the new scale of the canvas
---@param oldScale number
---@param y number
---@return number
local function chooseNewScale(oldScale, y)
	local index = 0
	for i = 1, #scales do
		local currScale = scales[i]
		if currScale <= oldScale then
			index = i
		end
	end

	-- No index found, must be max
	if index == 0 then return scales[#scales] end

	if y > 0 then
		-- Zoom in
		if index == #scales then return scales[index] end
		return scales[index + 1]
	else
		-- Zoom out
		if index == 1 then return scales[1] end
		return scales[index - 1]
	end

	-- TODO: Replace canvas zoom algorithm with something smarter

	--[[ local newScale = oldScale
	if y > 0 then
		-- Zoom in
		if oldScale >= 1 and oldScale < 6 then
			newScale = oldScale + 1
		else
			newScale = oldScale * 1.5
		end
	elseif y < 0 then
		-- Zoom out
		if oldScale > 1 and oldScale <= 6 then
			newScale = oldScale - 1
		else
			newScale = oldScale / 1.5
		end
	else
		-- No change
		return oldScale
	end
	return math.min(maxScale, math.max(minScale, newScale)) --]]
end

local checkerboardFlipSize = 16

---Draws the checkerboard pattern
---@param x integer
---@param y integer
---@param w integer
---@param h integer
local function drawCheckerboard(x, y, w, h)
	local endI = math.ceil(h / checkerboardFlipSize) - 1
	local endJ = math.ceil(w / checkerboardFlipSize) - 1

	local maxW = w
	local maxH = h
	for i = 0, endI do
		for j = 0, endJ do
			if (i + j) % 2 == 1 then
				love.graphics.setColor(0.65, 0.65, 0.65)
			else
				love.graphics.setColor(0.45, 0.45, 0.5)
			end

			local offsetX = j * checkerboardFlipSize
			local offsetY = i * checkerboardFlipSize
			love.graphics.rectangle("fill",
				x + offsetX,
				y + offsetY,
				math.min(checkerboardFlipSize, maxW - offsetX),
				math.min(checkerboardFlipSize, maxH - offsetY)
			)
		end
	end

	love.graphics.setColor(1, 1, 1)
end

---@param canvas SpriteCanvas
local function keepWithinBounds(canvas)
	local camX, camY = canvas.cameraX, canvas.cameraY
	local scale = canvas.scale
	local factor = 1 / scale
	local trueW, trueH = canvas.imageW * 0.5, canvas.imageH * 0.5
	local viewW, viewH = canvas.w * factor * 0.5, canvas.h * factor * 0.5

	local finalX = math.max(-trueW - viewW, math.min(camX, trueW + viewW))
	local finalY = math.max(-trueH - viewH, math.min(camY, trueH + viewH))

	canvas.cameraX = finalX
	canvas.cameraY = finalY
end

function Canvas:new(rules)
	Canvas.super.new(self, rules)

	---@type number
	self.minH = 20
	---@type number, number
	self.imageW, self.imageH = 0, 0
	---@type number, number
	self.imageX, self.imageY = 0, 0
	---@type number, number
	self.lastMouseX, self.lastMouseY = 0, 0
	---@type boolean
	self.panning = false
	---@type boolean
	self.hovering = false
	---@type Sprite?
	self.sprite = nil

	---@type boolean
	self.isAnimating = false
	---@type number
	self.timePassed = 0

	-- For fitting the sprite to the canvas
	---@type boolean
	self._didRefreshBefore = false
end

function Canvas:toggleAnimation()
	if #self.sprite.frames <= 1 then
		self.isAnimating = false
	else
		self.isAnimating = not self.isAnimating
	end
	self.timePassed = 0
end

function Canvas:getImagePoint(mouseX, mouseY)
	local wx, wy = self:screenToViewportPoint(mouseX, mouseY)
	wx = wx - self.imageX
	wy = wy - self.imageY
	return math.floor(wx), math.floor(wy)
end

function Canvas:wheelmoved(_, y)
	if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
		-- Grow/shrink brush
		local brush = SpriteTool.brush:get()
		if y < 0 then
			-- Shrink
			brush:shrink()
		else
			-- Grow
			brush:grow()
		end
	else
		-- Zoom
		local oldScale = self.scale
		local newScale = chooseNewScale(oldScale, y)
		local factor = newScale / oldScale

		-- If the new scale is different
		if oldScale ~= newScale then
			self:zoomToScreenPoint(self.lastMouseX, self.lastMouseY, factor)
			keepWithinBounds(self)
		end
	end
end

function Canvas:mousemoved(newX, newY, changeX, changeY)
	self.lastMouseX, self.lastMouseY = newX, newY
	if self.panning then
		self:translate(-changeX, -changeY)
		keepWithinBounds(self)
	elseif SpriteTool.drawing then
		local ix, iy = self:getImagePoint(newX, newY)
		SpriteTool.currentTool:pressing(ix, iy)
	end
end

function Canvas:mousepressed(_, _, button)
	if (button == 1 and love.keyboard.isDown("space")) or button == 3 then
		self:getFocus()
		self.panning = true
	elseif button == 1 and not self.panning and SpriteTool.currentTool then
		if SpriteTool.currentTool:canDraw() then
			self:getFocus()
			local ix, iy = self:getImagePoint(self.lastMouseX, self.lastMouseY)
			SpriteTool.currentTool:startPress(ix, iy)
		end
	end
end

function Canvas:mousereleased(_, _, button)
	if (button == 1 or button == 3) and self.panning then
		self:releaseFocus()
		self.panning = false
	elseif button == 1 and SpriteTool.drawing then
		self:releaseFocus()
		local ix, iy = self:getImagePoint(self.lastMouseX, self.lastMouseY)
		SpriteTool.currentTool:stopPress(ix, iy)
	end
end

function Canvas:pointerentered()
	self.hovering = true
	love.mouse.setCursor(pointerCursor)
end

function Canvas:pointerexited()
	self.hovering = false
	love.mouse.setCursor()
end

function Canvas:refresh()
	Canvas.super.refresh(self)
	keepWithinBounds(self)

	if not self._didRefreshBefore then
		-- TODO: Fix initial zoom
		self._didRefreshBefore = true
		self:fitSprite()
	end
end

function Canvas:update(dt)
	local sprite = self.sprite
	if self.isAnimating and sprite then
		local frameIndex = sprite.spriteState.frame:get()
		local frame = sprite.frames[frameIndex]
		local frameDuration = frame.duration:get()

		self.timePassed = self.timePassed + dt
		if self.timePassed > frameDuration then
			sprite.spriteState.frame:set(frameIndex % #sprite.frames + 1)
			self.timePassed = self.timePassed - frameDuration
		end
	end
end

function Canvas:draw()
	-- Don't render if canvas is too small
	if self.w < 1 or self.h < 1 then
		return
	end

	-- Draw the gray background
	love.graphics.setColor(0.12, 0.12, 0.12)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	-- Enter the viewport world
	local sx, sy, sw, sh = love.graphics.getScissor()
	self:pushTransform()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

	-- Draw the sprite
	local sprite = self.sprite
	if sprite then
		local spriteState = sprite.spriteState

		-- Inking the border
		love.graphics.setColor(0, 0, 0)
		local ix, iy, iw, ih = self.imageX, self.imageY, self.imageW, self.imageH
		local borderSize = 4 / self.scale
		love.graphics.rectangle("fill", ix - borderSize, iy - borderSize,
						iw + 2 * borderSize, ih + 2 * borderSize)

		-- The checkerboard background
		drawCheckerboard(self.imageX, self.imageY, self.imageW, self.imageH)

		-- TODO: Use events
		local frameIndex = spriteState.frame:get()
		local layerIndex = spriteState.layer:get()
		local tool = SpriteTool.currentTool
		local pointX, pointY = self:getImagePoint(self.lastMouseX, self.lastMouseY)
		pointX, pointY = pointX + ix, pointY + iy
		local layers = sprite.layers
		local bx, by =
			ix + spriteState.selectionX,
			iy + spriteState.selectionY

		love.graphics.setColor(1, 1, 1)
		for i = #layers, 1, -1 do
			local layer = layers[i]
			if layer.visible:get() and layer.editorData.canvas.visible then
				local celIndex = layer.celIndices[frameIndex]
				if celIndex then
					local cel = sprite.cels[layer.celIndices[frameIndex]]
					if cel then
						love.graphics.draw(cel.image, ix, iy)
					end
				end
			end

			local sameIndex = i == layerIndex

			if sameIndex then
				if spriteState.includeSelection then
					love.graphics.draw(spriteState.selectionCel.image, bx, by)
				end

				if spriteState.includeMimic then
					love.graphics.draw(spriteState.mimicCanvas, ix, iy)
				end

				if spriteState.includeDrawBuffer then
					love.graphics.draw(spriteState.drawCel.image, ix, iy)
				end
			end

			if tool and self.hovering then
				tool:draw(pointX, pointY, i)
				love.graphics.setColor(1, 1, 1)
			end
		end
		spriteState.bitmaskRenderer:draw(bx, by, self.scale)
	end

	-- Exit viewport
	love.graphics.setScissor(sx, sy, sw, sh)
	self:popTransform()
end

---Fits the sprite to the canvas
function Canvas:fitSprite()
	---@type Sprite
	local sprite = self.sprite

	if sprite then
		local w, h = self.w, self.h
		local iw, ih = sprite.width, sprite.height
		self.cameraX, self.cameraY =
			0, 0
		self.scale = 1.
		---@type number
		local oldScale
		while true do
			oldScale = self.scale
			local newScale = chooseNewScale(oldScale, 1)
			if iw * newScale > w or ih * newScale > h or oldScale == newScale then
				break
			end
			self.scale = newScale
		end
	end
end

---@param sprite Sprite
function Canvas:onSpriteCreated(sprite)
	sprite.editorData.canvas = {
		justCreated = true,
	}

	---@param sprite Sprite
	---@param newLayer Sprite.Layer
	---@param index integer
	sprite.layerCreated:addAction(function(sprite, newLayer, index)
		newLayer.editorData.canvas = {
			visible = true
		}
	end)

	for _, layer in ipairs(sprite.layers) do
		layer.editorData.canvas = {
			visible = true
		}
	end
end

---@param sprite Sprite
function Canvas:onSpriteSelected(sprite)
	self.sprite = sprite
	self._spriteResizedAction = sprite.spriteResized:addAction(function(newW, newH)
		self.imageW, self.imageH =
			newW, newH
		self.imageX = sprite.spriteState.imageX
		self.imageY = sprite.spriteState.imageY
		self:fitSprite()
	end)

	local canvasData = sprite.editorData.canvas
	if canvasData and canvasData.justCreated then
		canvasData.justCreated = false
		self:fitSprite()
	end
end

function Canvas:onSpriteDeselected(sprite)
	self.sprite = nil
	sprite.spriteResized:removeAction(self._spriteResizedAction)
end

return Canvas
