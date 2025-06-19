local Plan = require "lib.plan"
local Label = require "ui.components.text.label"

---@class SpriteStatus.CanvasPos: Label
local CanvasPos = Label:extend()

function CanvasPos:new(rules)
	CanvasPos.super.new(self, rules, "")
	---@type SpriteEditor
	self.editor = nil
	---@type SpriteCanvas?
	self.canvas = nil
	---@type integer, integer
	self.lastX, self.lastY = -1, -1
end

function CanvasPos:update()
	local canvas = self.canvas
	if canvas and canvas.hovering then
		local newX, newY = canvas:getImagePoint(canvas.lastMouseX, canvas.lastMouseY)
		newX, newY = newX, newY
		if newX ~= self.lastX or newY ~= self.lastY then
			self.lastX, self.lastY = newX, newY
			self:setText(("(%d, %d)"):format(newX, newY))
		end
		self:enable()
	else
		self:disable()
	end
end

---Sets the SpriteEditor
---@param spriteEditor SpriteEditor
function CanvasPos:setEditor(spriteEditor)
	self.editor = spriteEditor
	self.canvas = spriteEditor.container.canvasUI
end

return CanvasPos
