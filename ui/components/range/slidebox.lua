local Plan = require "lib.plan"
local Range = require "src.data.range"
local Luvent = require "lib.luvent"
local Label = require "ui.components.text.label"
local exp = function(n)
	return math.abs(n) * n
end

local hdragCursor = love.mouse.getSystemCursor("sizewe")

---@class Slidebox: Plan.Container
local Slidebox = Plan.Container:extend()

local FULL_RULES = Plan.RuleFactory.full()
---@type string
local FORMAT_STRING = "%s: %d"
---@type integer
local DEFAULT_WIDTH = 150

---@param rules Plan.Rules
---@param range Range?
function Slidebox:new(rules, range)
	Slidebox.super.new(self, rules)
	---@type Range
	self.range = range or Range()
	---@type boolean
	self.pressing = false
	---@type boolean # If the Slidebox updates the Range immediately instead of previewing it on the display
	self.updateLive = false
	---@type string
	self.name = "Range"
	---@type boolean # If the Slidebox dragging/display should be exponential
	self.exponential = false

	---@type number, number # For unbounded dragging
	self._startVal, self._startX = 0, 0

	---@type integer
	self.progressWidth = 0
	---@type number
	self.valueToUse = 0
	self._onParamsChanged = self.range.parametersChanged:addAction(function(r)
		self:updatePreview(r:getValue())
	end)
	self._onValueChanged = self.range.valueChanged:addAction(function(r, value)
		self:updatePreview(value)
	end)

	---@type Label
	self.label = Label(FULL_RULES, self.name)
	self.label:setAlign("center")
	self:addChild(self.label)
	self:updatePreview(self.range:getValue())
end

function Slidebox:refresh()
	Slidebox.super.refresh(self)
	self.progressWidth = self.range:getPercent() * self.w
end

function Slidebox:setName(newName)
	self.name = newName
	self:updatePreview(self.range:getValue())
end

---Updates the Slidebox preview
---@param value number
function Slidebox:updatePreview(value)
	self.valueToUse = value

	local range = self.range
	local w = self.w
	local percent = range:getPercentOfNumber(value)

	self.label:setText(FORMAT_STRING:format(self.name, value))
	local newW, _ = self.label:getTextBounds()
	newW = math.max(DEFAULT_WIDTH, newW)
	if newW ~= w then
		self.w = newW
		self:bubble("_bubbleSizeChanged")
	end
	self.progressWidth = math.max(0, math.min(percent * newW, newW))
end

function Slidebox:wheelmoved(_, y)
	self.range:increment(y)
end

function Slidebox:mousepressed(x, _, button)
	if button == 1 then
		local range = self.range
		self._startVal = range:getValue()
		self._startX = x
		self:updateFromMouse(x)
		self.pressing = true
		self:getFocus()
	end
end

function Slidebox:mousereleased(_, _, button)
	if button == 1 and self.pressing then
		self.pressing = false
		if not self.updateLive then
			self.range:setValue(self.valueToUse)
		end
		self:releaseFocus()
	end
end

function Slidebox:mousemoved(mx, _)
	if self.pressing then
		self:updateFromMouse(mx)
	end
end

function Slidebox:pointerentered()
	love.mouse.setCursor(hdragCursor)
end

function Slidebox:pointerexited()
	love.mouse.setCursor()
end

---Updates the Range value from the mouse position
---@param mx integer
function Slidebox:updateFromMouse(mx)
	local x, w = self.x, self.w
	local range = self.range
	-- Change the value on the Range as the mouse moves
	local updateLive = self.updateLive
	if range:hasBounds() then
		local percent = (mx - x) / w

		if updateLive then
			range:setValue(range:getValueFromPercent(percent))
		else
			if self.exponential then
				percent = exp(percent)
			end
			local sanitized = range:sanitizeNumber(range:getValueFromPercent(percent))
			self:updatePreview(sanitized)
		end
	else
		if updateLive then
			range:setValue(self._startVal + (mx - self._startX) * 0.2)
		else
			self:updatePreview(range:sanitizeNumber(self._startVal + (mx - self._startX) * 0.2))
		end
	end
end

function Slidebox:draw()
	love.graphics.setColor(0.1, 0.1, 0.15)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(0.5, 0.5, 0.8)
	love.graphics.rectangle("fill", self.x, self.y, self.progressWidth, self.h)
	Slidebox.super.draw(self)
end

function Slidebox:destroy(...)
	Slidebox.super.destroy(self, ...)
	self.range.parametersChanged:removeAction(self._onParamsChanged)
	self.range.valueChanged:removeAction(self._onValueChanged)
end

return Slidebox
