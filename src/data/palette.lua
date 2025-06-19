local Object = require "lib.classic"
local nativefs = require "lib.nativefs"
local Luvent = require "lib.luvent"

---@alias Palette.Color number[]
---@alias Palette.Importer fun(palette: Palette, file: love.File): success: boolean, error: string?

---@alias Palette.Type
--- | "rgb"
--- | "rgba"

---@class Palette: Object
local Palette = Object:extend()
---@type {[string]: Palette.Importer} # Key is the file extension
Palette.importers = {}

function Palette:new()
	---@type Palette.Color[]
	self.colors = {}
	self.name = "Unnamed"
	self.locked = true
	self.colorsChanged = Luvent.newEvent()
end

function Palette:removeColorAtIndex(index)
	index = math.max(1, math.min(index, #self.colors))
	table.remove(self.colors, index)
	self.colorsChanged:trigger(self)
end

function Palette:addColor(color, index)
	if not index then index = #self.colors + 1 end
	table.insert(self.colors, index, color)
	self.colorsChanged:trigger(self)
end

---Creates a Palette from an array
---@param colors Palette.Color[]
---@return Palette
function Palette.createFromArray(colors)
	local palette = Palette()
	palette.colors = colors
	palette.name = ""
	return palette
end

---Duplicates a palette
---@return Palette clone
function Palette:clone()
	local cloned = Palette()
	cloned.name = self.name
	cloned.locked = self.locked

	-- Clone the colors
	local colors = {}
	for i = 1, #self.colors do
		local old = self.colors[i]
		local new = {old[1], old[2], old[3]}
		colors[i] = new
	end
	cloned.colors = colors

	return cloned
end

return Palette
