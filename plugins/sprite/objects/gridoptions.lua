local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"

local NumberProperty = require "src.properties.number"
local IntegerProperty = require "src.properties.integer"
local BoolProperty = require "src.properties.bool"
local ColorSelectionProperty = require "src.properties.colorselection"

---@class GridOptions: Inspectable
local GridOptions = Inspectable:extend()

function GridOptions:new()
	GridOptions.super.new(self)

	-- The grid
	---@type BoolProperty
	self.showGrid = BoolProperty(self, "Show Grid", true)

	---@type IntegerProperty
	self.gridW = IntegerProperty(self, "Grid Width", 8)
	self.gridW:getRange():setMin(1)

	---@type IntegerProperty
	self.gridH = IntegerProperty(self, "Grid Height", 8)
	self.gridH:getRange():setMin(1)

	---@type IntegerProperty
	self.gridOffsetX = IntegerProperty(self, "Grid Offset X", 0)

	---@type IntegerProperty
	self.gridOffsetY = IntegerProperty(self, "Grid Offset Y", 0)

	---@type ColorSelectionProperty
	self.gridColor = ColorSelectionProperty(self, "Grid Color", {1, 1, 1})

	---@type NumberProperty
	self.lineOpacity = NumberProperty(self, "Line Opacity", 0.6)
	self.lineOpacity:getRange()
		:setMin(0)
		:setMax(1)
end

function GridOptions:getProperties()
	return {
		self.showGrid,
		self.gridW,
		self.gridH,
		self.gridOffsetX,
		self.gridOffsetY,
		self.gridColor,
		self.lineOpacity,
	}
end

return GridOptions
