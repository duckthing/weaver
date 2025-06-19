local Plan = require "lib.plan"

---@class PaletteContainer.Colors: Plan.Container
local PaletteColors = Plan.Container:extend()

PaletteColors.colorSize = 20
function PaletteColors:new(rules)
	PaletteColors.super.new(self, rules)

	---@type Palette?
	self.palette = nil
	---@type ColorSelectionProperty?, ColorSelectionProperty?
	self.primarySelection, self.secondarySelection = nil, nil
	self.colorSize = PaletteColors.colorSize
	self.lastPaletteSize = 0

	self.hovering = false
	self.hoveringIndex = 0
end

---@param palette Palette?
function PaletteColors:setPalette(palette)
	if palette ~= self.palette then
		self.palette = palette
		self:bubble("_bubbleSizeChanged")
	end
end

function PaletteColors:getIndexAndColorUnderMouse(mx, my)
	local palette = self.palette
	if not palette then return 0, nil end

	local colorSize = self.colorSize
	local columns = math.floor(self.w / colorSize)

	if mx - self.x >= columns * colorSize then
		-- In the gutter on the right
		return 0, nil
	end

	local rows = math.ceil(#palette.colors / columns)
	local cx, cy =
		math.floor((mx - self.x) / colorSize) + 1,
		math.floor((my - self.y) / colorSize)

	local index = cx + cy * columns
	if index > #palette.colors then return 0, nil end
	return index, palette.colors[index]
end

function PaletteColors:mousemoved(mx, my)
	self.hoveringIndex = self:getIndexAndColorUnderMouse(mx, my)
end

function PaletteColors:mousepressed(mx, my, button)
	local index, color = self:getIndexAndColorUnderMouse(mx, my)

	if index then
		if button == 1 then
			self.primarySelection:setColorByIndex(index)
		elseif button == 2 then
			self.secondarySelection:setColorByIndex(index)
		end
	end
end

function PaletteColors:pointerentered()
	self.hovering = true
end

function PaletteColors:pointerexited()
	self.hovering = false
	self.hoveringIndex = 0
end

local selectedColor = {1, 1, 1}
local backgroundOutline = {0, 0, 0}
function PaletteColors:draw()
	local palette = self.palette
	if not palette then return end

	if self.lastPaletteSize ~= #palette.colors then
		self:bubble("_bubbleSizeChanged")
	end

	love.graphics.push("all")

	-- This bit just makes it so the outlines extend backwards a little
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.setScissor(ox - 2, oy - 2, ow + 4, oh + 4)

	local x, y, w, h = self.x, self.y, self.w, self.h
	love.graphics.intersectScissor(x - 2, y - 2, w + 4, h + 4)

	local colorSize = self.colorSize
	local maxColumns = math.floor(self.w / colorSize)
	local cx, cy = 0, 0
	local primaryIndex, secondaryIndex =
		self.primarySelection.index or 0,
		self.secondarySelection.index or 0

	if maxColumns == 0 or maxColumns == math.huge then goto afterDraw end

	love.graphics.setColor(backgroundOutline)
	for i = 1, #palette.colors do
		-- Draw the selection outline
		love.graphics.rectangle("fill", x + cx - 1, y + cy - 1, colorSize + 2, colorSize + 2)

		-- Loop over
		if i % maxColumns == 0 then
			cx = 0
			cy = cy + colorSize
		else
			cx = cx + colorSize
		end
	end

	cx, cy = 0, 0
	for i = 1, #palette.colors do
		-- Draw the selection outline
		if i == primaryIndex or i == secondaryIndex then
			love.graphics.setColor(selectedColor)
			love.graphics.rectangle("fill", x + cx - 1, y + cy - 1, colorSize + 2, colorSize + 2)
		end

		-- Draw the color
		local color = palette.colors[i]
		love.graphics.setColor(color)
		love.graphics.rectangle("fill", x + cx + 1, y + cy + 1, colorSize - 2, colorSize - 2)

		-- Loop over
		if i % maxColumns == 0 then
			cx = 0
			cy = cy + colorSize
		else
			cx = cx + colorSize
		end
	end

	::afterDraw::

	love.graphics.pop()
end

function PaletteColors:getDesiredDimensions()
	local palette = self.palette
	if not palette then return end

	local columns = math.floor(self.w / self.colorSize)
	if columns == 0 then return nil, 0 end
	local rows = math.ceil(#palette.colors / columns)
	return nil, rows * self.colorSize
end

return PaletteColors
