local Plan = require "lib.plan"
local Label = require "ui.components.text.label"

---@class SpriteStatus.ColorSelect: Label
local ColorSelect = Label:extend()

function ColorSelect:new(rules)
	ColorSelect.super.new(self, rules, "")
	---@type SpriteEditor
	self.editor = nil
	---@type PaletteContainer.Colors?
	self.paletteColors = nil
	---@type integer
	self.lastHoveringIndex = 0
end

function ColorSelect:update()
	local pc = self.paletteColors
	if pc and pc.hovering and pc.hoveringIndex > 0 then
		local hoveringIndex = pc.hoveringIndex
		if hoveringIndex ~= self.lastHoveringIndex then
			---@type number
			self.lastHoveringIndex = hoveringIndex
			local color = pc.palette.colors[hoveringIndex]
			local r, g, b = love.math.colorToBytes(color[1], color[2], color[3])
			local hex = r * 0x010000 + g * 0x000100 + b * 0x000001
			self:setText(("idx. %d, #%06X"):format(hoveringIndex, hex))
		end
		self:enable()
	else
		self:disable()
	end
end

---Sets the SpriteEditor
---@param spriteEditor SpriteEditor
function ColorSelect:setEditor(spriteEditor)
	self.editor = spriteEditor
	self.paletteColors = spriteEditor.container.paletteUI.paletteColors
end

return ColorSelect
