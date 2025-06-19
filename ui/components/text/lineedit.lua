local Plan = require "lib.plan"
local InputField = require "lib.inputfield"
local Fonts = require "src.global.fonts"
local Luvent = require "lib.luvent"

local defaultFont = Fonts.getDefaultFont()
local ibeamCursor = love.mouse.getSystemCursor("ibeam")

---@class LineEdit: Plan.Container
local LineEdit = Plan.Container:extend()

---@enum LineEdit.HAlign
---| "left"
---| "center"
---| "right"

---@enum LineEdit.VAlign
---| "top"
---| "center"
---| "bottom"

---@param rules Plan.Rules
---@param text string
---@param hAlign LineEdit.HAlign?
---@param vAlign LineEdit.VAlign?
function LineEdit:new(rules, text, hAlign, vAlign)
	LineEdit.super.new(self, rules)
	---@type InputField
	local inputfield = InputField(text)
	inputfield:setFont(defaultFont)
	if hAlign then
		inputfield:setAlignment(hAlign)
	end
	self.inputfield = inputfield

	---@type LineEdit.HAlign
	self.hAlign = hAlign or "left" ---@diagnostic disable-line
	---@type LineEdit.VAlign
	self.vAlign = vAlign or "center" ---@diagnostic disable-line
	self.fieldX = 0
	self.fieldY = 0
	self.marginX = 4
	self.marginY = 0
	self.focused = false
	---@type integer
	self.maxLength = 0
	---@type boolean
	self.preferStart = true

	---@type string # If the user presses Escape, revert to this
	self.oldText = ""
	self.textSubmitted = Luvent.newEvent()
	self.textChanged = Luvent.newEvent()
	self.textCancelled = Luvent.newEvent()
end

-- TODO: Add setters functions to update field automatically

function LineEdit:updateFieldPosition()
	local offsetX = self.marginX
	local offsetY = self.marginY
	local realW = math.max(0, self.w - offsetX * 2)
	local realH = math.max(0, self.h - offsetY * 2)

	-- By default, use the first alignment
	local finalX, finalY = offsetX, offsetY
	local textHeight = self.inputfield:getTextHeight()

	local vAlign = self.vAlign
	if vAlign == "center" then
		finalY = (realH - textHeight) * 0.5
	elseif vAlign == "bottom" then
		finalY = realH - textHeight
	end

	self.fieldX, self.fieldY = finalX + self.x, finalY + self.y
	self.inputfield:setDimensions(realW, realH)

	if not self.focused then
		if self.preferStart then
			self.inputfield:setCursor(0)
		else
			self.inputfield:setCursor(#self.inputfield:getText())
		end
	end
end

---Cleans up the input before validating
function LineEdit:sanitizeInput()
end

---Returns true or false, depending on this function.
---Runs after sanitizeInput
---@return boolean
function LineEdit:validateInput()
	local maxLength = self.maxLength
	if maxLength == 0 then return true end

	return #self.inputfield:getText() <= maxLength
end

function LineEdit:releaseFocus()
	LineEdit.super.releaseFocus(self)
	self.focused = false
	if self.preferStart then
		self.inputfield:setCursor(0)
	else
		self.inputfield:setCursor(#self.inputfield:getText())
	end
	self.inputfield:releaseMouse()
	self:bubble("lineEditUnfocused", self.inputfield:getText())
end

function LineEdit:cancelSubmit()
	self:releaseFocus()

	local oldText = self.oldText
	self.inputfield:setText(oldText)
	self:updateFieldPosition()
	self.textChanged:trigger(oldText)
	self.textCancelled:trigger(oldText)
end

function LineEdit:submitText()
	self:sanitizeInput()
	if self:validateInput() then
		-- Valid
		self:releaseFocus()
		self.textSubmitted:trigger(self.inputfield:getText())
	else
		-- Invalid
		self:cancelSubmit()
	end
end

---Sets the text of the LineEdit
---@param text string
function LineEdit:setText(text)
	self.inputfield:setText(text)
	self:updateFieldPosition()
	self.textCancelled:trigger(text)
end

---Gets the text of the LineEdit
---@return string text
function LineEdit:getText()
	return self.inputfield:getText()
end

function LineEdit:refresh()
	LineEdit.super.refresh(self)
	self:updateFieldPosition()
end

function LineEdit:startEdit()
	self.focused = true
	self.oldText = self.inputfield:getText()
	self:getFocus()
end

function LineEdit:mousepressed(mx, my, button, isTouch, pressCount)
	if self.focused then
		if self:isOverlapping(mx, my) then
			-- Mouse events get sent when focused
			-- Check if not clicking outside the field
			self.inputfield:mousepressed(mx - self.fieldX, my - self.fieldY, button, pressCount)
		else
			self:submitText()
			-- Return true means send the mouse click to something else
			return true
		end
	else
		self.inputfield:mousepressed(mx - self.fieldX, my - self.fieldY, button, 1)
		self:startEdit()
	end
end

function LineEdit:mousereleased(mx, my, button)
	self.inputfield:mousereleased(mx - self.fieldX, my - self.fieldY, button)
end

function LineEdit:mousemoved(mx, my)
	self.inputfield:mousemoved(mx - self.fieldX, my - self.fieldY)
end

function LineEdit:pointerentered()
	love.mouse.setCursor(ibeamCursor)
end

function LineEdit:pointerexited()
	love.mouse.setCursor()
end

function LineEdit:keypressed(key, _, isRepeat)
	if key == "escape" then
		-- Unfocus
		self:cancelSubmit()
	elseif key == "return" then
		self:submitText()
	else
		self.inputfield:keypressed(key, isRepeat)
	end
end

function LineEdit:textinput(text)
	self.inputfield:textinput(text)
	self.textChanged:trigger(self.inputfield:getText())
end

function LineEdit:draw()
	if self.w < 1 or self.h < 1 then return end
	local field = self.inputfield
	local fieldX, fieldY = self.fieldX, self.fieldY
	local focused = self.focused
	local sx, sy, sw, sh = love.graphics.getScissor()

	local vx, vy, vw, vh = self.x, self.y, self.w, self.h
	love.graphics.intersectScissor(vx, vy, vw, vh)

	love.graphics.setFont(defaultFont)
	if focused then
		love.graphics.setColor(0.4, 0.4, 0.9, 0.8)
		for _, x, y, w, h in field:eachSelection() do
			love.graphics.rectangle("fill", fieldX+x, fieldY+y, w, h)
		end
	end

	love.graphics.setColor(1, 1, 1)
	for _, text, x, y in field:eachVisibleLine() do
		love.graphics.print(text, fieldX+x, fieldY+y)
	end

	if focused then
		local x, y, h = field:getCursorLayout()
		love.graphics.rectangle("fill", fieldX+x, fieldY+y, 1, h)
	end
	love.graphics.setScissor(sx, sy, sw, sh)
end

return LineEdit
