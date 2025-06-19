local Plan = require "lib.plan"

---@class SorterContainer: Plan.Container
local SorterContainer = Plan.Container:extend()
SorterContainer.CLASS_NAME = "SorterContainer"

---@alias SorterContainer.SortFunction fun(self: SorterContainer): nil

---@type Plan.Container[]
local EMPTY_ARR = {}

function SorterContainer:new(rules)
	SorterContainer.super.new(self, rules)

	---@type integer
	self._lowerCull = 0
	---@type integer
	self._upperCull = 0
	---@type boolean # Don't sort again while actively sorting
	self._sorting = false
	---@type boolean # Received size change bubble while sorting, return this value
	self._gotBubbleWhileSorting = false
end

---Sorts all children, usually during a refresh
function SorterContainer:sort()
	if not self._inUITree or self._sorting then return end
	self._sorting = true
	local shouldBubble = self:_sortFunction()
	self._sorting = false

	if shouldBubble or self._gotBubbleWhileSorting then
		-- The sort function can return true to tell the parent that it changed
		-- TODO: Find a better way than sorting twice
		self._sorting = true
		self:_sortFunction()
		self._sorting = false
		self._gotBubbleWhileSorting = false
		self:bubble("_bubbleSizeChanged")
	end
end

---Sets the sort function
---@param newFunction SorterContainer.SortFunction
function SorterContainer:setSortFunction(newFunction)
	if self._sortFunction ~= newFunction then
		self._sortFunction = newFunction
		self:sort()
	end
end

---@type SorterContainer.SortFunction
---@return boolean? shouldBubbleSizeChange
function SorterContainer:_sortFunction()
	self._lowerCull = 0
	self._upperCull = #self.children

	for i = 1, #self.children do
		local child = self.children[i]
		if child._active then
			child:refresh()
		end
	end
end

function SorterContainer:refresh()
	local children = self.children
	self.children = EMPTY_ARR
	SorterContainer.super.refresh(self)
	self.children = children
	self:sort()
	self:_treeUpdate()
end

function SorterContainer:_bubbleSizeChanged(source)
	-- Sort again when a child's size changes
	if not self._sorting then
		self:sort()
	else
		self._gotBubbleWhileSorting = true
	end
	-- Also don't continue bubbling
	return false
end

function SorterContainer:_bubbleStatusChanged(source)
	-- Sort again when a child is enabled/disabled
	self:sort()
	-- Also don't continue bubbling
	return false
end

function SorterContainer:removeChild(...)
	SorterContainer.super.removeChild(self, ...)
	self:sort()
end

function SorterContainer:clearChildren(...)
	SorterContainer.super.clearChildren(self, ...)
	self:sort()
end

function SorterContainer:draw()
	for i = math.max(1, self._lowerCull), math.min(#self.children, self._upperCull) do
		local child = self.children[i]
		if child:isActive() then
			child:draw()
		end
	end
end

return SorterContainer
