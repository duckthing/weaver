local Object = require "lib.classic"
local Luvent = require "lib.luvent"

---@class Range: Object
local Range = Object:extend()

local HUGE = math.huge
function Range:new()
	Range.super.new(self)

	---@type number, number
	self.min, self.max = -HUGE, HUGE
	---@type number
	self.step = 0
	---@type number
	self.value = 0
	---@type number
	self.defaultValue = 0

	self.valueChanged = Luvent.newEvent()
	self.parametersChanged = Luvent.newEvent()
end

---Sanitizes a number and returns it.
---This value will be "floored".
---@param num number
---@return number
function Range:sanitizeNumber(num)
	local min, max, step =
		self.min, self.max, self.step

	local final = math.max(min, math.min(num, max))
	if min ~= -HUGE and step > 0 then
		final = final - ((final - min) % step)
	elseif max ~= HUGE and step > 0 then
		final = final - ((final - max) % step)
	elseif step > 0 then
		final = num - num % step
	end
	return final
end

---Sanitizes a number and sets the value
---@param num number
---@return self
function Range:setValue(num)
	local finalVal = self:sanitizeNumber(num)

	if finalVal ~= self.value then
		self.value = finalVal
		self.valueChanged:trigger(self, finalVal)
	end
	return self
end

---Sanitizes a number and sets it as the default
---@param num number
---@return self
function Range:setDefaultValue(num)
	local finalDefault = self:sanitizeNumber(num)

	if finalDefault ~= self.defaultValue then
		self.defaultValue = finalDefault
	end
	return self
end

---Sets the minimum value of the Range
---@param min number
---@return self
function Range:setMin(min)
	if self.min ~= min then
		if min == nil or min == HUGE or min == -HUGE then
			self.min = -HUGE
		else
			self.min = min
		end
		self:setDefaultValue(self.defaultValue)
		self:setValue(self.value)
		self.parametersChanged:trigger(self)
	end
	return self
end

---Sets the maximum value of the Range
---@param max number
---@return self
function Range:setMax(max)
	if self.max ~= max then
		if max == nil or max == HUGE or max == -HUGE then
			self.max = HUGE
		else
			self.max = max
		end
		self:setDefaultValue(self.defaultValue)
		self:setValue(self.value)
		self.parametersChanged:trigger(self)
	end
	return self
end

---Sets the step value of the Range
---@param step number
---@return self
function Range:setStep(step)
	if self.step ~= step then
		if step == nil or step == HUGE or step == -HUGE then
			self.step = 0
		else
			self.step = math.abs(step)
		end
		self:setDefaultValue(self.defaultValue)
		self:setValue(self.value)
		self.parametersChanged:trigger(self)
	end
	return self
end

---Increments the Range by amount, or 1 if amount is nil. Uses steps.
---@param amount integer?
function Range:increment(amount)
	local step = self.step
	if step == 0 then step = 1 end
	if amount == nil then amount = 1 end
	self:setValue(self:getValue() + step * amount)
end

---Increments the Range by amount, or 1 if amount is nil. Uses steps.
---@param amount integer?
function Range:decrement(amount)
	local step = self.step
	if step == 0 then step = 1 end
	if amount == nil then amount = 1 end
	self:setValue(self:getValue() - step * amount)
end

---Gets the value
---@return number
function Range:resetToDefault()
	return self.defaultValue
end

---Gets the value
---@return number
function Range:getValue()
	return self.value
end

function Range:hasBounds()
	return self.min ~= -HUGE and self.max ~= HUGE
end

---Gets the number parameter in percent
---@param number number
---@return number
function Range:getPercentOfNumber(number)
	if self.min == -HUGE or self.max == HUGE then
		return 0
	else
		return (number - self.min) / (self.max - self.min)
	end
end

---Gets the expected value from the percent.
---This value will be "rounded".
---@param percent number
function Range:getValueFromPercent(percent)
	local min, max, step = self.min, self.max, self.step
	if step == 0 then
		return min + (max - min) * percent
	end

	local span = max - min
	local totalSteps = span / step

	return min +
		math.floor((percent + (0.5 / totalSteps)) * totalSteps) * step
end

---Gets the value in percent
---@return number
function Range:getPercent()
	return self:getPercentOfNumber(self.value)
end

return Range
