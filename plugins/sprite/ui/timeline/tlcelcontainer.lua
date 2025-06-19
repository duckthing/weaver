local Plan = require "lib.plan"
local Modal = require "src.global.modal"
local SpriteSheet = require "src.spritesheet"
local NinePatch = require "src.ninepatch"
local Luvent = require "lib.luvent"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local celTexture = love.graphics.newImage("assets/cel_icons.png")
celTexture:setFilter("nearest", "nearest")
local celSpriteSheet = SpriteSheet.new(celTexture, 5, 1)
local backgroundTexture = love.graphics.newImage("assets/timeline_button.png")
backgroundTexture:setFilter("nearest", "nearest")
local backgroundNP = NinePatch.new(2, 1, 2, 2, 1, 2, backgroundTexture)

---@class Timeline.Cels: Plan.Container
local CelTimelines = Plan.Container:extend()
local celSize = 26

---@type Action[]
local celActions = {}

---@param rules Plan.Rules
function CelTimelines:new(rules)
	CelTimelines.super.new(self, rules)
	---@type Sprite?
	self.sprite = nil
	---@type integer
	self.scrollX = 0
	---@type integer
	self.scrollY = 0

	-- The draw limits
	---@type integer, integer
	self._lowerX, self._lowerY = 0, 0
	---@type integer, integer
	self._upperX, self._upperY = 0, 0

	---@type boolean
	self.panning = false
	---@type boolean
	self.hovering = false
	---@type boolean
	self.pressing = false
	---@type integer
	self.hoveringIndexX = 0
	---@type integer
	self.hoveringIndexY = 0
	---@type integer
	self.pressingIndexX = 0
	---@type integer
	self.pressingIndexY = 0

	---@type SpriteState
	self.spriteState = nil

	---@type boolean If the SpriteBatch should update
	self.shouldUpdateSB = true
	self.npsb = backgroundNP:newSpriteBatch(nil, "static")
	self.spriteSheetBatch = celSpriteSheet:newSpriteBatch(nil, "static")

	self.scrollChanged = Luvent.newEvent()
end

function CelTimelines:updateScroll()
	self.scrollX = math.max(0, math.min(self.scrollX, #self.sprite.frames * celSize - self.w))
	self.scrollY = math.max(0, math.min(self.scrollY, #self.sprite.layers * celSize - self.h))
	self.scrollChanged:trigger(self.scrollX, self.scrollY)
	self:recalculateBoundaries()
end

function CelTimelines:mousemoved(newX, newY, changeX, changeY)
	if self.panning and self.sprite then
		self.scrollX = self.scrollX - changeX
		self.scrollY = self.scrollY - changeY
		self:updateScroll()
	else
		local x, y =
			math.floor((newX - self.x + self.scrollX) / celSize) + 1,
			math.floor((newY - self.y + self.scrollY) / celSize) + 1
		self.shouldUpdateSB = self.shouldUpdateSB or (x ~= self.hoveringIndexX or y ~= self.hoveringIndexY)
		self.hoveringIndexX, self.hoveringIndexY = x, y
	end
end

function CelTimelines:mousepressed(_, _, button)
	if button == 3 or (button == 1 and love.keyboard.isDown("space")) then
		self.panning = true
		self:getFocus()
	elseif button == 1 or button == 2 then
		self.shouldUpdateSB = true
		self.pressing = true
		self.pressingIndexX = self.hoveringIndexX
		self.pressingIndexY = self.hoveringIndexY
		self:getFocus()
	end
end

function CelTimelines:mousereleased(mx, my, button)
	if self.pressing and self.pressingIndexX == self.hoveringIndexX and self.pressingIndexY == self.hoveringIndexY then
		if self.sprite.layers[self.hoveringIndexY] and self.sprite.frames[self.hoveringIndexX] then
			-- This index is valid
			self:bubble("_bSelectLayer", self.sprite.layers[self.hoveringIndexY])
			self:bubble("_bSelectFrame", self.sprite.frames[self.hoveringIndexX])

			if button == 2 then
				Modal.pushMenu(mx, my, celActions, self, self.spriteState.context)
			end
		end
	end

	self.panning = false
	self.pressing = false
	self.shouldUpdateSB = true
	self:releaseFocus()
end

function CelTimelines:pointerentered()
	self.hovering = true
	self.shouldUpdateSB = true
end

function CelTimelines:pointerexited()
	self.hovering = false
	self.shouldUpdateSB = true
	self.hoveringIndexX = 0
	self.hoveringIndexY = 0
end

function CelTimelines:wheelmoved(x, y)
	if love.keyboard.isDown("lshift") then
		self.scrollX = self.scrollX + y * celSize
		self.scrollY = self.scrollY - x * celSize
	else
		self.scrollX = self.scrollX + x * celSize
		self.scrollY = self.scrollY - y * celSize
	end
	self:updateScroll()
end

function CelTimelines:recalculateBoundaries()
	-- Prevent things from rendering out of bounds
	local oldLX, oldUX, oldLY, oldUY =
					self._lowerX, self._upperX, self._lowerY, self._upperY
	self._lowerX = math.floor(self.scrollX / celSize) + 1
	self._upperX = math.ceil((self.scrollX + self.w) / celSize)
	self._lowerY = math.floor(self.scrollY / celSize) + 1
	self._upperY = math.ceil((self.scrollY + self.h) / celSize)

	self.shouldUpdateSB = self.shouldUpdateSB or (
		self._lowerX ~= oldLX or
		self._upperX ~= oldUX or
		self._lowerY ~= oldLY or
		self._upperY ~= oldUY
	)
end

function CelTimelines:updateSpriteBatch()
	if self.shouldUpdateSB then
		self.shouldUpdateSB = false
		local npsb = self.npsb
		local spb = self.spriteSheetBatch
		npsb:clear()
		spb:clear()

		-- Where the drawing position starts for the panels
		-- local sx, sy = self.scrollX - celSize, self.scrollY - celSize
		local sx, sy = 0 - celSize, 0 - celSize
		-- The offset for the cel indicator inside of the panels
		local vx, vy = sx + 5, sy + 5
		local activeLayerIndex = self.spriteState.layer:get()
		local activeFrameIndex = self.spriteState.frame:get()
		local hoveringFrameIndex = self.hoveringIndexX
		local hoveringLayerIndex = self.hoveringIndexY
		local pressingFrameIndex = self.pressingIndexX
		local pressingLayerIndex = self.pressingIndexY
		local pressing = self.pressing

		if self.sprite ~= nil then
			for y = self._lowerY, math.min(#self.sprite.layers, self._upperY) do
				-- Per layer
				local layer = self.sprite.layers[y]
				local celIndices = layer.celIndices

				for x = self._lowerX, math.min(#self.sprite.frames, self._upperX) do
					-- Per frame

					--=== BACKGROUND
					-- Choose the background color
					spb:setColor(0.7, 0.7, 0.7)
					if y == activeLayerIndex or x == activeFrameIndex then
						if y == activeLayerIndex and x == activeFrameIndex then
							npsb:setColor(0.5, 0.5, 0.75)
							spb:setColor(1, 1, 1)
						else
							npsb:setColor(0.3, 0.3, 0.5)
						end
					else
						npsb:setColor(0.2, 0.2, 0.4)
					end

					if x == hoveringFrameIndex and y == hoveringLayerIndex then
						if pressing then
							if x == pressingFrameIndex and y == pressingLayerIndex then
								-- Is pressing the same thing originally
								npsb:setColor(0.1, 0.1, 0.2)
								spb:setColor(0.8, 0.8, 0.8)
							end
						else
							-- Just hovering, not pressing anything
							npsb:setColor(0.25, 0.25, 0.5)
							spb:setColor(1, 1, 1)
						end
					end

					-- Add it to the background sprite batch
					npsb:add(sx + x * celSize, sy + y * celSize, celSize, celSize, 2)

					--=== CELS
					local iconFrame = 1
					local currI = celIndices[x]
					if currI ~= 0 then
						local lastIsSame = x > 0 and currI == celIndices[x - 1]
						local nextIsSame = x <= #celIndices and currI == celIndices[x + 1]
						if lastIsSame then
							if nextIsSame then
								-- SAME X SAME
								iconFrame = 4
							else
								-- SAME X DIFF
								iconFrame = 5
							end
						elseif nextIsSame then
							-- DIFF X SAME
							iconFrame = 3
						else
							-- DIFF X DIFF
							iconFrame = 2
						end
						spb:add(iconFrame, sx + x * celSize, sy + y * celSize, 2, 2)
					end
				end
			end
		end
	end
end

function CelTimelines:refresh()
	CelTimelines.super.refresh(self)
	self:updateScroll()
end

---@param sprite Sprite
function CelTimelines:onSpriteSelected(sprite)
	self.sprite = sprite
	self.spriteState = sprite.spriteState

	local actions = self.spriteState.context:getActions()
	celActions[1] = actions.delete_cel
	celActions[2] = actions.unlink_cel

	self.shouldUpdateSB = true

	local function updateSB()
		self.shouldUpdateSB = true
	end

	self.layerCreatedAction = sprite.layerCreated:addAction(updateSB)
	self.layerMovedAction = sprite.layerMoved:addAction(updateSB)
	self.layerRemovedAction = sprite.layerRemoved:addAction(updateSB)
	self.frameCreatedAction = sprite.frameCreated:addAction(updateSB)
	self.frameMovedAction = sprite.frameMoved:addAction(updateSB)
	self.frameRemovedAction = sprite.frameRemoved:addAction(updateSB)
	self.celCreatedAction = sprite.celCreated:addAction(updateSB)
	self.celIndexEditedAction = sprite.celIndexEdited:addAction(updateSB)
end

function CelTimelines:onSpriteDeselected()
	local sprite = self.sprite
	self.sprite = nil
	self.spriteState = nil
	self.shouldUpdateSB = true

	if sprite then
		sprite.layerCreated:removeAction(self.layerCreatedAction)
		sprite.layerMoved:removeAction(self.layerMovedAction)
		sprite.layerRemoved:removeAction(self.layerRemovedAction)
		sprite.frameCreated:removeAction(self.frameCreatedAction)
		sprite.frameMoved:removeAction(self.frameMovedAction)
		sprite.frameRemoved:removeAction(self.frameRemovedAction)
		sprite.celCreated:removeAction(self.celCreatedAction)
		sprite.celIndexEdited:removeAction(self.celIndexEditedAction)
	end
end

---@param selectedLayer Sprite.Layer
function CelTimelines:onLayerSelected(selectedLayer)
	self.shouldUpdateSB = true

	local celTop =
		(selectedLayer.index - 1) * celSize
	local celBottom = celTop + celSize

	-- Move down if the cel is hidden on the bottom
	self.scrollY = math.max(celBottom - self.h, self.scrollY)
	-- Move up if the cel is hidden above
	self.scrollY = math.min(self.scrollY, celTop)
	self:updateScroll()
end

---@param selectedFrame Sprite.Frame
function CelTimelines:onFrameSelected(selectedFrame)
	self.shouldUpdateSB = true

	local celLeft =
		(selectedFrame.index - 1) * celSize
	local celRight = celLeft + celSize

	-- Move right if the cel is hidden on the right
	self.scrollX = math.max(celRight - self.w, self.scrollX)
	-- Move left if the cel is hidden on the left
	self.scrollX = math.min(self.scrollX, celLeft)
	self:updateScroll()
end

function CelTimelines:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

	-- Where the drawing position starts for the panels
	local sx, sy = self.x - self.scrollX - celSize, self.y - self.scrollY - celSize
	-- The offset for the cel indicator inside of the panels
	local vx, vy = sx + 5, sy + 5
	if self.sprite ~= nil then
		-- Draw the background
		love.graphics.setColor(1, 1, 1)
		self:updateSpriteBatch()
		self.npsb:draw(self.x - self.scrollX, self.y - self.scrollY)
		self.spriteSheetBatch:draw(self.x - self.scrollX, self.y - self.scrollY)
	end

	CelTimelines.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

return CelTimelines
