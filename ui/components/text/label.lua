local Plan = require "lib.plan"
local Fonts = require "src.global.fonts"

---@class Label: Plan.Container
local Label = Plan.Container:extend()
Label.CLASS_NAME = "Label"
---@type Palette.Color
Label.color = {1, 1, 1}

---@alias Label.JustifyMode
---| "top"
---| "center"
---| "bottom"

---Creates a new Label
---@param rules Plan.Rules
---@param text string?
function Label:new(rules, text)
	Label.super.new(self, rules)
	---@type string
	self._text = text or ""
	self._font = Fonts.getDefaultFont()

	---@type integer The padding from the edges that the text is aligned/justified to
	self._paddingX, self._paddingY = 0, 0
	---@type integer, integer
	self._textX, self._textY = 0, 0

	---@type love.AlignMode
	self._align = "left"
	---@type Label.JustifyMode
	self._justify = "center"
	---@type integer
	self._wrapLimit = math.huge

	---@type love.Text The text that is drawn
	self._textObj = love.graphics.newText(self._font)
	self._textObj:setf(self._text, self._wrapLimit, self._align)
end

---Sets the text of the Label
---@param newText string?
function Label:setText(newText)
	self._text = newText or ""
	self:_updateTextOffset()
end

---Sets the font of the Label
---@param newFont love.Font?
function Label:setFont(newFont)
	self._font = newFont or Fonts.getDefaultFont()
	self._textObj = love.graphics.newText(self._font)
	self:_updateTextOffset()
end

---Sets the align mode of the Label
---@param align love.AlignMode
function Label:setAlign(align)
	self._align = align
	self:_updateTextOffset()
end

---Sets the justify mode of the Label
---@param justify Label.JustifyMode
function Label:setJustify(justify)
	self._justify = justify
	self:_updateTextOffset()
end

---Sets the padding of the Label
---@param paddingX integer?
---@param paddingY integer?
function Label:setPadding(paddingX, paddingY)
	self._paddingX = paddingX or self._paddingX
	self._paddingY = paddingY or self._paddingY
	self:_updateTextOffset()
end

---Sets the wrap limit of the Label
---@param wrapLimit integer?
function Label:setWrapLimit(wrapLimit)
	self._wrapLimit = wrapLimit or math.huge
	self:_updateTextOffset()
end

function Label:getTextBounds()
	return self._textObj:getDimensions()
end

function Label:getDesiredDimensions()
	return self._textObj:getDimensions()
end

function Label:_updateTextOffset()
	local align, justify = self._align, self._justify
	local textObj = self._textObj
	local wrapLimit = self._wrapLimit

	local oldTW, oldTH = textObj:getDimensions()
	if wrapLimit == math.huge and align ~= "center" or self.w == 0 then
		-- There are issues when adding wrapping to something
		-- that doesn't need it.
		textObj:set(self._text)
	else
		textObj:setf(self._text, math.min(self.w, wrapLimit), align)
	end
	local newTW, newTH = textObj:getDimensions()
	local dimensionsChanged = oldTW ~= newTW or oldTH ~= newTH

	local _, th = textObj:getDimensions()
	local paddingX, paddingY = self._paddingX, self._paddingY

	if align == "left" then
		-- Do nothing
		self._textX = paddingX
	else
		self._textX = 0
	end

	-- Do the Y axis
	if justify == "top" then
		-- Do nothing
		self._textY = paddingY
	elseif justify == "center" then
		-- Offset is the label height minus the text height and then halved
		self._textY = (self.h - th) * 0.5
	elseif justify == "bottom" then
		-- Offset is the label height minus the text height
		self._textY = self.h - th - paddingY
	end

	if dimensionsChanged then
		self:bubble("_bubbleSizeChanged")
	end
end

function Label:refresh()
	Label.super.refresh(self)
	self:_updateTextOffset()
end

function Label:draw()
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)

	love.graphics.setColor(self.color)
	love.graphics.draw(self._textObj, self.x + self._textX, self.y + self._textY)

	love.graphics.setScissor(ox, oy, ow, oh)
end

return Label
