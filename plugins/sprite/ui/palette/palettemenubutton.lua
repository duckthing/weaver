local Plan = require "lib.plan"
local IconButton = require "ui.components.button.iconbutton"
local SpriteSheet = require "src.spritesheet"
local PaletteMenu = require "plugins.sprite.ui.palette.palettemenu"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

---@class PaletteMenuButton: IconButton
local PaletteMenuButton = IconButton:extend()

---@param self PaletteMenuButton
local function openPaletteMenu(self)
	self.paletteMenu:popup()
end

function PaletteMenuButton:new(rules)
	PaletteMenuButton.super.new(self, rules, openPaletteMenu, iconSpriteSheet, 18, 2)
	self.paletteMenu = PaletteMenu(Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.pixel(20))
		:addWidth(Plan.pixel(370))
		:addHeight(Plan.pixel(240))
	)
	self:addChild(self.paletteMenu)
end

return PaletteMenuButton
