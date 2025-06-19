local Plan = require "lib.plan"
local Label = require "ui.components.text.label"

---@class SpriteStatus.CanvasZoom: Label
local CanvasZoom = Label:extend()

function CanvasZoom:new(rules)
	CanvasZoom.super.new(self, rules, "")
	---@type SpriteEditor
	self.editor = nil
	---@type SpriteCanvas?
	self.canvas = nil
	---@type integer
	self.lastZoom = 1
end

function CanvasZoom:update()
	local canvas = self.canvas
	if canvas then
		local currentZoom = canvas.scale
		currentZoom = math.floor(currentZoom * 100)
		if currentZoom ~= self.lastZoom then
			self.lastZoom = currentZoom
			self:setText(("%d%%"):format(currentZoom))
		end
		self:enable()
	else
		self:disable()
	end
end

---Sets the SpriteEditor
---@param spriteEditor SpriteEditor
function CanvasZoom:setEditor(spriteEditor)
	self.editor = spriteEditor
	self.canvas = spriteEditor.container.canvasUI
end

return CanvasZoom
