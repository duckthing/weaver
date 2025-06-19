local IconButton = require "ui.components.button.iconbutton"
local SpriteSheet = require "src.spritesheet"
local Contexts = require "src.global.contexts"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class PaletteContainer.LockButton: IconButton
local PaletteLockButton = IconButton:extend()

local LOCKED_ICON = 3
local UNLOCKED_ICON = 4

function PaletteLockButton:new(rules)
	PaletteLockButton.super.new(self, rules, function()
		Contexts.raiseAction("toggle_palette_lock")
	end, iconSpriteSheet, 3, 2)

	---@type Palette?
	self.palette = nil
end

function PaletteLockButton:draw()
	local palette = self.palette
	self.frame = ((palette and palette.locked) and LOCKED_ICON) or UNLOCKED_ICON
	-- TODO: Make palette.locked use properties instead
	PaletteLockButton.super.draw(self)
end

return PaletteLockButton
