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
	self.showGrid = BoolProperty(self, "Show Grid", false)

	---@type NumberProperty
	self.gridW = NumberProperty(self, "Grid Width", 8)
	self.gridW:getRange()
		:setMin(1)
		:setStep(0.5)

	---@type NumberProperty
	self.gridH = NumberProperty(self, "Grid Height", 8)
	self.gridH:getRange()
		:setMin(1)
		:setStep(0.5)

	---@type NumberProperty
	self.gridOffsetX = NumberProperty(self, "Grid Offset X", 0)
	self.gridOffsetX:getRange()
		:setStep(0.5)

	---@type NumberProperty
	self.gridOffsetY = NumberProperty(self, "Grid Offset Y", 0)
	self.gridOffsetY:getRange()
		:setStep(0.5)

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
