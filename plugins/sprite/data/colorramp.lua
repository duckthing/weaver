local bit = require "bit"
local Object = require "lib.classic"

---@class ColorRamp: Object
local ColorRamp = Object:extend()

function ColorRamp:new()
	ColorRamp.super.new(self)

	self.palette = nil

	---@type Palette.Color[]
	self._usedColors = {}
	---@type {[integer]: [integer]} # Bitwise, shift right/left for the color
	self._forwardRamp = {}
	---@type {[integer]: [integer]} # Bitwise, shift right/left for the color
	self._backwardRamp = {}

	self._shouldRecalculateRamps = false
end

function ColorRamp:addColor(r, g, b)
	-- If it already exists, move it to the front
	for i, color in ipairs(self._usedColors) do
		if color[1] == r and color[2] == g and color[3] == b then
			-- Found in the list
			if i ~= #self._usedColors then
				-- In the back, move it to the front
				table.insert(self._usedColors, table.remove(self._usedColors, i))
				self._usedColors[i], self._usedColors[#self._usedColors] =
					self._usedColors[#self._usedColors], self._usedColors[i]

				self._shouldRecalculateRamps = true
			end
			return
		end
	end

	-- Add it to the used colors
	self._usedColors[#self._usedColors+1] = {r, g, b}
	self._shouldRecalculateRamps = true
end

function ColorRamp:reset()
	self._shouldRecalculateRamps = #self._usedColors > 0
	for i = #self._usedColors, 1, -1 do
		self._usedColors[i] = nil
	end
end

local function addNext(arr, curr, next)
	local cr, cg, cb = love.math.colorToBytes(curr[1], curr[2], curr[3])
	local nr, ng, nb = love.math.colorToBytes(next[1], next[2], next[3])

	local cBit = bit.lshift(bit.lshift(cr, 8) + cg, 8) + cb
	local nBit = bit.lshift(bit.lshift(nr, 8) + ng, 8) + nb

	arr[cBit] = nBit
end

function ColorRamp:_calculateRamps()
	local forward = {}
	local backward = {}
	local colors = self._usedColors

	for i = 1, #colors - 1 do
		addNext(forward, colors[i], colors[i + 1])
	end

	for i = #colors, 2, -1 do
		addNext(backward, colors[i], colors[i - 1])
	end

	self._forwardRamp = forward
	self._backwardRamp = backward
end

function ColorRamp:getRamps()
	if self._shouldRecalculateRamps then
		self:_calculateRamps()
		self._shouldRecalculateRamps = false
	end

	return self._forwardRamp, self._backwardRamp
end

return ColorRamp
