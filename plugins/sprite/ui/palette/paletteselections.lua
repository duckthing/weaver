local Plan = require "lib.plan"
local Contexts = require "src.global.contexts"
local SpriteSheet = require "src.spritesheet"
local Modal = require "src.global.modal"
local VFlex = require "ui.components.containers.flex.vflex"
local IconButton = require "ui.components.button.iconbutton"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class PaletteContainer.Selections: VFlex
local PaletteSelections = VFlex:extend()

function PaletteSelections:new(rules)
	PaletteSelections.super.new(self, rules)

	---@type Palette?
	self.palette = nil
	---@type ColorSelectionProperty?, ColorSelectionProperty?
	self.primarySelection, self.secondarySelection = nil, nil

	local addButton = IconButton(
		Plan.Rules.new()
			:addX(Plan.max(30))
			:addY(Plan.keep())
			:addWidth(Plan.pixel(30))
			:addHeight(Plan.keep()),
		function(s)
			if s:isActive() then
				Contexts.raiseAction("add_primary_color_to_palette")
			else
				self:mousepressed(s.x, s.y, 1)
			end
		end,
		iconSpriteSheet, 16, 2
	)
	local removeButton = IconButton(
		Plan.Rules.new()
			:addX(Plan.max(30))
			:addY(Plan.keep())
			:addWidth(Plan.pixel(30))
			:addHeight(Plan.keep()),
		function(s)
			if s:isActive() then
				Contexts.raiseAction("remove_primary_color_from_palette")
			else
				self:mousepressed(s.x, s.y, 1)
			end
		end,
		iconSpriteSheet, 17, 2
	)

	addButton.sizeRatio = 1
	removeButton.sizeRatio = 1
	addButton._active = false
	removeButton._active = false
	self:addChild(addButton)
	self:addChild(removeButton)
end

---@param palette Palette?
function PaletteSelections:setPalette(palette)
	if palette ~= self.palette then
		self.palette = palette
	end
end

function PaletteSelections:mousepressed(mx, my, button)
	if button == 1 then
		local popupX, popupY =
			self.x + self.w,
			self.y + self.h - Modal.DEFAULT_COLOR_HEIGHT
		if my - self.y < self.h * 0.5 then
			-- First half
			Modal.pushColorSelect(self.primarySelection, popupX, popupY)
		else
			-- Second half
			Modal.pushColorSelect(self.secondarySelection, popupX, popupY)
		end
	end
end

local lastShow = false
function PaletteSelections:draw()
	local width = self.w
	local palette = self.palette
	local showEditControls = (palette and not palette.locked) or false
	if showEditControls then
		width = width - 32
	end

	if lastShow ~= showEditControls then
		if showEditControls then
			self:emit("enable")
		else
			self:emit("disable")
		end
		self:sort()
		lastShow = showEditControls
	end

	love.graphics.setColor(self.primarySelection:getColor())
	love.graphics.rectangle("fill", self.x, self.y + 2, width, self.h * 0.5)
	love.graphics.setColor(self.secondarySelection:getColor())
	love.graphics.rectangle("fill", self.x, self.y + self.h * 0.5, width, self.h * 0.5)

	love.graphics.setLineWidth(2)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("line", self.x, self.y + 2, width - 1, self.h * 0.5 - 3)
	love.graphics.rectangle("line", self.x, self.y + self.h * 0.5 - 1, width - 1, self.h * 0.5 - 4)

	if showEditControls then
		PaletteSelections.super.draw(self)
	end
end

return PaletteSelections
