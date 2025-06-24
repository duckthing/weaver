local Plan = require "lib.plan"
local SplitHandle = require "ui.components.containers.split.splithandle"

---@class VSplit: Plan.Container
local VSplit = Plan.Container:extend()
VSplit.CLASS_NAME = "VSplit"

---Creates an VSplit container, which has two elements
---that are above/below each other.
---@param rules Plan.Rules
function VSplit:new(rules, firstChild, secondChild)
	VSplit.super.new(self, rules)
	self.minPosition = 0
	self.maxPosition = 100
	self.splitPosition = 50
	self._lastW = 100
	---@type ResizeMode
	self.resizeMode = "factor"

	self:addChild(SplitHandle(self, false))

	if firstChild then
		self:addChild(firstChild)
		if secondChild then
			self:addChild(secondChild)
		end
	elseif secondChild then
		error("Received second child while first child is nil")
	end
end

function VSplit:draw()
	for i = math.min(#self.children, 3), 1, -1 do
		self.children[i]:draw()
	end
end

---Handles parent container/window resizing
---@param self VSplit
local function handleResize(self, newW)
	-- Make the split stay relatively the same
	local wDiff = newW - self._lastW
	self._lastW = newW
	local resizeMode = self.resizeMode
	if wDiff ~= 0 then
		if resizeMode == "keepfirst" then
			-- The first one stays the same (do nothing)
		elseif resizeMode == "keepsecond" then
			-- The second one stays the same
			self.splitPosition = self.splitPosition + wDiff
		else
			-- Both are scaled equally (factor)
			self.splitPosition = self.splitPosition + wDiff * 0.5
		end
	end
end

function VSplit:updateSplit()
	local x, y, w, h = self.x, self.y, self.w, self.h
	handleResize(self, w)

	local splitHandle = self.children[1]
	local firstChild = self.children[2]
	local secondChild = self.children[3]

	-- Make sure the split is within bounds
	self.minPosition = firstChild.minW or 0
	self.maxPosition = (secondChild.minW ~= nil and w - secondChild.minW) or w
	self.splitPosition = math.max(self.minPosition, math.min(self.splitPosition, self.maxPosition))

	self.x = x
	self.y = y
	self.h = h

	if firstChild then
		firstChild.rules:addWidth(Plan.pixel(self.splitPosition))
		firstChild:refresh()
	end
	if secondChild then
		secondChild.rules:addX(Plan.pixel(self.splitPosition))
		secondChild.rules:addWidth(Plan.pixel(w - self.splitPosition))
		secondChild:refresh()
	end

	self.x = x + self.splitPosition
	splitHandle:refresh()
	self.x, self.y, self.w, self.h = x, y, w, h
end

function VSplit:refresh()
	VSplit.super.refresh(self)
	self:updateSplit()
end

return VSplit
