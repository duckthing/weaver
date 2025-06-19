local Plan = require "lib.plan"
local Sorter = require "ui.components.containers.sorter"

---@class GenBox: SorterContainer
local GenBox = Sorter:extend()
GenBox.CLASS_NAME = "GenBox"
GenBox._position = "x"
GenBox._size = "w"

---@alias GenBox.Direction
---| "first"
---| "last"

function GenBox:new(rules)
	GenBox.super.new(self, rules)
	self._clipMode = "clip"
	---@type GenBox.Direction
	self.direction = "first"
	self.padding = 0
	self.margin = 0
	---@type integer # The scroll position of this GenBox
	self.offset = 0
	---@type integer # How much space the child elements take up
	self._containerSize = 0
end

---Sets the sort direction
---@param newDirection GenBox.Direction
function GenBox:setDirection(newDirection)
	if newDirection ~= self.direction then
		self.direction = newDirection
		self:sort()
	end
end

function GenBox:_sortFunction()
	local pos, size = self._position, self._size
	-- The 'visible' parts of the container
	---@type integer, integer
	local startPos, endPos = self[pos], self[pos] + self[size]
	local direction = self.direction
	---@type integer
	local factor
	if direction == "first" then
		factor = 1
	else
		factor = -1
	end

	local padding, margin = self.padding, self.margin
	self.offset = math.max(0, math.min(self.offset, self._containerSize - self[size]))

	-- How big the container actually is
	local containerSize = padding * 2
	-- Where the current element should be
	local currPos
	if direction == "first" then
		-- Left to right
		currPos = startPos - self.offset + padding
	else
		-- Right to left
		currPos = endPos + self.offset - padding
	end

	local lowerDepth = self._depth + 1
	local lowerBounds = self._bounds
	self._lowerCull = 1
	self._upperCull = #self.children
	for i = 1, #self.children do
		local child = self.children[i]

		if child:isActive() then
			-- Standard refreshing
			child._depth = lowerDepth
			child._bounds = lowerBounds

			-- "Realise" includes the position of the parent
			child[pos] = currPos - startPos
			child.x, child.y, child.w, child.h = child.rules:realise(child)
			currPos = currPos + (child[size] + margin) * factor
			if direction == "last" then
				child[pos] = child[pos] - child[size]
			end

			-- Check if the element is within bounds so that it can be culled
			if child[pos] + child[size] < startPos then
				-- On the left side
				if direction == "first" then
					self._lowerCull = i + 1
				elseif self._upperCull == #self.children then
					self._upperCull = i - 1
				end
				child:callAndEmit("_treeRemove")
			elseif child[pos] > endPos then
				-- On the right side
				if direction == "last" then
					self._lowerCull = i + 1
				elseif self._upperCull == #self.children then
					self._upperCull = i - 1
				end
				child:callAndEmit("_treeRemove")
			else
				-- Visible in the container
				child[pos] = child[pos] - startPos
				local oldSize = child[size]
				child:refresh()
				-- In case the size changed mid-refresh
				currPos = currPos + child[size] - oldSize
			end

			containerSize = containerSize + child[size] + margin
		end
	end
	local gotBubble = self._gotBubbleWhileSorting
	self._gotBubbleWhileSorting = false
	if containerSize ~= self._containerSize then
		self._containerSize = containerSize
		return true
	end
	return gotBubble
end

function GenBox:updateScroll()
	self:sort()
end

function GenBox:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)
	GenBox.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

return GenBox
