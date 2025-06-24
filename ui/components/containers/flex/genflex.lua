local Sorter = require "ui.components.containers.sorter"

-- TODO: Implement GenFlex

---@alias GenFlex.Justify
---| "start"
---| "center"
---| "end"
---| "spacebetween" # This one is finished
---| "spacearound"
---| "spaceeven"

---@class GenFlex: SorterContainer
local GenFlex = Sorter:extend()
GenFlex.CLASS_NAME = "GenFlex"
GenFlex._position = "x"
GenFlex._size = "w"

function GenFlex:new(rules)
	GenFlex.super.new(self, rules)
	self.padding = 0
	self.margin = 0
	---@type GenFlex.Justify # Only start, center, end, and spacebetween is functional
	self.justify = "start"
	self._requestedSize = 0
end

---Sets Justify
---@param newJustify HFlex.Justify
function GenFlex:setJustify(newJustify)
	if self.justify ~= newJustify then
		self.justify = newJustify
		self:sort()
	end
end

function GenFlex:_sortFunction()
	local padding, margin = self.padding, self.margin
	local justify = self.justify
	local _pos, _size = self._position, self._size
	self._upperCull = #self.children

	-- How the space should be divided up, and how much space is requested in total
	local totalRatio = 0
	local requestedSpace = 0
	local activeChildren = 0
	for i = 1, #self.children do
		local child = self.children[i]
		if child:isActive() then
			totalRatio = totalRatio + child.sizeRatio
			activeChildren = activeChildren + 1

			local dw, dh = child:getDesiredDimensions()
			if _size == "w" then
				requestedSpace = requestedSpace + (dw or 0)
			else
				requestedSpace = requestedSpace + (dh or 0)
			end
		end
	end
	self._requestedSize = requestedSpace

	-- (childRatio * ratioFactor) is equal to (childRatio / totalRatio)
	local ratioFactor = 1
	if totalRatio ~= 0 then
		-- Children want to be resized according to available space
		ratioFactor = 1 / totalRatio
	end

	-- How much space there is
	local containerSize = self[_size] - (padding * 2 + margin * math.max(0, activeChildren - 1))
	containerSize = math.max(0, containerSize)

	-- How much space to give to the resizable children
	local freeSpace = containerSize - requestedSpace

	-- Now we resize and move everything
	local currPos = 0
	if justify == "start" or justify == "spacebetween" or justify == "spaceeven" then
		currPos = padding
	elseif justify == "center" then
		currPos = freeSpace * 0.5
		currPos = math.max(0, currPos)
	elseif justify == "end" then
		currPos = padding
	end

	local lowerDepth = self._depth + 1
	local lowerBounds = self._bounds

	for i = 1, #self.children do
		local child = self.children[i]
		child._depth = lowerDepth
		child._bounds = lowerBounds
		if not child:isActive() then goto continue end

		local childRatio = child.sizeRatio
		local dw, dh = child:getDesiredDimensions()
		local desiredSize = (_size == "w" and dw) or dh or 0

		if childRatio <= 0 and totalRatio > 0 and desiredSize <= 0 then
			-- Doesn't take up any space due to not requesting it, remove it
			child:callAndEmit("_treeRemove")
			goto continue
		end

		if childRatio > 0 then
			child[_size] = math.max(desiredSize, childRatio * ratioFactor * freeSpace)
		else
			child[_size] = desiredSize
		end

		if justify == "end" then
			child[_pos] = self[_size] - currPos - child[_size]
		else
			child[_pos] = currPos
		end

		child:refresh()
		if justify == "start" or justify == "center" or justify == "end" then
			-- TODO: Refactor to use functions instead of if statements
			currPos = currPos + child[_size] + margin
		elseif justify == "spacebetween" then
			currPos = currPos + child[_size] + margin
			if totalRatio == 0 then
				currPos = currPos + freeSpace / math.max(1, activeChildren - 1)
			end
		end

		::continue::
	end
end

return GenFlex
