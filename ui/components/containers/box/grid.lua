local Sorter = require "ui.components.containers.sorter"

---@class GridBox: SorterContainer
local GridBox = Sorter:extend()
GridBox.CLASS_NAME = "GridBox"

function GridBox:new(rules)
	GridBox.super.new(self, rules)
	self._clipMode = "clip"
	self.margin = 0
	self.padding = 0
	---@type integer # The scroll position of this GenBox
	self.offset = 0
	---@type integer # How much space the child elements take up
	self._containerHeight = 0

	self.itemW = 20
	self.itemH = 20
end

function GridBox:_sortFunction()
	local x, y, w, h = self.x, self.y, self.w, self.h

	local padding = self.padding
	local totalSpaceAvailable = w - padding * 2
	local spaceAvailable = w
	local row = 0
	local column = 0
	local itemW, itemH = self.itemW, self.itemH

	if spaceAvailable < itemW + padding * 2 then
		-- No space, remove all children from tree
		for i = 1, #self.children do
			self.children[i]:_treeRemove()
		end
		self._upperCull = 0
		return
	end

	local lowerDepth = self._depth + 1
	local lowerBounds = self._bounds
	self._lowerCull = 1
	self._upperCull = #self.children
	for i = 1, #self.children do
		local child = self.children[i]
		child._depth = lowerDepth
		child._bounds = lowerBounds

		if itemW > spaceAvailable - padding * 2 then
			-- Reset to next row, first column
			spaceAvailable = totalSpaceAvailable
			row = row + 1
			column = 0
		end

		child.x, child.y, child.w, child.h =
			column * itemW + padding,
			row * itemH,
			itemW, itemH
		child:refresh()

		spaceAvailable = spaceAvailable - itemW
		column = column + 1
	end

	self._containerHeight = row * itemH
end

function GridBox:getDesiredDimensions()
	return nil, self._containerHeight
end

function GridBox:updateScroll()
	self:sort()
end

function GridBox:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)
	GridBox.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

return GridBox
