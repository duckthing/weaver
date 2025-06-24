local Plan = require "lib.plan"
local SplitHandle = require "ui.components.containers.split.splithandle"

---@class HSplit: Plan.Container
local HSplit = Plan.Container:extend()
HSplit.CLASS_NAME = "HSplit"

---@alias ResizeMode
---| "keepfirst"
---| "keepsecond"
---| "factor"

---Creates an HSplit container, which has two elements
---that are above/below each other.
---@param rules Plan.Rules
function HSplit:new(rules, firstChild, secondChild)
	HSplit.super.new(self, rules)
	self.minPosition = 0
	self.maxPosition = 100
	self.splitPosition = 50
	self._lastH = 100
	---@type ResizeMode
	self.resizeMode = "factor"

	self:addChild(SplitHandle(self, true))

	if firstChild then
		self:addChild(firstChild)
		if secondChild then
			self:addChild(secondChild)
		end
	elseif secondChild then
		error("Received second child while first child is nil")
	end
end

function HSplit:draw()
	for i = math.min(#self.children, 3), 1, -1 do
		self.children[i]:draw()
	end
end

---Handles parent container/window resizing
---@param self HSplit
local function handleResize(self, newH)
	-- Make the split stay relatively the same
	local hDiff = newH - self._lastH
	self._lastH = newH
	local resizeMode = self.resizeMode
	if hDiff ~= 0 then
		if resizeMode == "keepfirst" then
			-- The first one stays the same (do nothing)
		elseif resizeMode == "keepsecond" then
			-- The second one stays the same
			self.splitPosition = self.splitPosition + hDiff
		else
			-- Both are scaled equally (factor)
			self.splitPosition = self.splitPosition + hDiff * 0.5
		end
	end
end

function HSplit:updateSplit()
	local x, y, w, h = self.x, self.y, self.w, self.h
	handleResize(self, h)

	local splitHandle = self.children[1]
	local firstChild = self.children[2]
	local secondChild = self.children[3]

	-- Make sure the split is within bounds
	-- TODO: Make this not rely on if the first child exists
	self.minPosition = firstChild.minH or 0
	self.maxPosition = (secondChild.minH ~= nil and h - secondChild.minH) or h
	self.splitPosition = math.max(self.minPosition, math.min(self.splitPosition, self.maxPosition))

	self.x = x
	self.y = y
	self.w = w

	if firstChild then
		firstChild.rules:addHeight(Plan.pixel(self.splitPosition))
		firstChild:refresh()
	end
	if secondChild then
		secondChild.rules:addY(Plan.pixel(self.splitPosition))
		secondChild.rules:addHeight(Plan.pixel(h - self.splitPosition))
		secondChild:refresh()
	end

	self.y = y + self.splitPosition
	splitHandle:refresh()
	self.x, self.y, self.w, self.h = x, y, w, h
end

function HSplit:refresh()
	-- TODO: Prevent double refresh
	HSplit.super.refresh(self)
	self:updateSplit()
end

return HSplit
