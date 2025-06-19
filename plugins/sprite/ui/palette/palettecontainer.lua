local Plan = require "lib.plan"
local Luvent = require "lib.luvent"
local Palettes = require "src.global.palettes"
local PaletteMenuButton = require "plugins.sprite.ui.palette.palettemenubutton"
local PaletteLockButton = require "plugins.sprite.ui.palette.palettelockbutton"
local PaletteColors = require "plugins.sprite.ui.palette.palettecolors"
local PaletteSelections = require "plugins.sprite.ui.palette.paletteselections"
local VBox = require "ui.components.containers.box.vbox"
local HBox = require "ui.components.containers.box.hbox"
local HFlex = require "ui.components.containers.flex.hflex"
local VScroll = require "ui.components.containers.box.vscroll"
local Modal = require "src.global.modal"

---@class PaletteContainer: VBox
local PaletteContainer = VBox:extend()

local yOffset = 26
function PaletteContainer:new(rules)
	PaletteContainer.super.new(self, rules)
	self.padding = 4
	self.margin = 4
	self.minW = 30
	---@type Sprite?
	self.activeSprite = nil
	---@type Palette
	self.palette = Palettes.globalPalettes[1]

	---@type boolean
	self.hovering = false
	---@type integer
	self.hoveringIndex = 0
	---@type number[]?
	self.hoveringColor = nil

	---@type ColorSelectionProperty
	self.primaryColorSelection = nil
	---@type ColorSelectionProperty
	self.secondaryColorSelection = nil
	---@type PaletteProperty?
	self.paletteProperty = nil

	self.colorColumns = 0
	self._lowerBound = 1
	self._upperBound = 1

	---@type string?
	self._paletteChangedAction = nil
	---@type string?
	self._paletteColorsChangedAction = nil

	---@type HFlex
	local buttonHBox = HFlex(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(26))
	)
	buttonHBox.padding = 4
	buttonHBox.justify = "spacebetween"

	---@type PaletteContainer.LockButton
	local paletteLockButton = PaletteLockButton(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(0))
			:addWidth(Plan.keep())
			:addHeight(Plan.parent())
	)
	paletteLockButton.sizeRatio = 1
	self.paletteLockButton = paletteLockButton

	---@type PaletteMenuButton
	local paletteMenuButton = PaletteMenuButton(
		paletteLockButton.rules
	)
	paletteMenuButton.sizeRatio = 1

	buttonHBox:addChild(paletteLockButton)
	buttonHBox:addChild(paletteMenuButton)

	self:addChild(buttonHBox)

	---@type PaletteContainer.Colors
	local paletteColors = PaletteColors(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.content(Plan.pixel(0)))
	)
	self.paletteColors = paletteColors

	---@type VScroll
	local vscroll = VScroll(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.keep())
			:addWidth(Plan.max(8))
			:addHeight(Plan.max(26 + 4 + 60 + 4))
	)
	self.paletteVScroll = vscroll

	vscroll.wheelmoved = function(s, _, my)
		if love.keyboard.isDown("lctrl") then
			paletteColors.colorSize = math.max(8, math.min(paletteColors.colorSize + my, 60))
			paletteColors:bubble("_bubbleSizeChanged")
		else
			VScroll.wheelmoved(s, _, my)
		end
	end

	vscroll:addChild(paletteColors)

	---@type PaletteContainer.Selections
	local paletteSelections = PaletteSelections(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(60))
	)
	self.paletteSelections = paletteSelections

	self:addChild(vscroll)
	self:addChild(paletteSelections)
end

function PaletteContainer:draw()
	love.graphics.setColor(0.25, 0.25, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	PaletteContainer.super.draw(self)
end

---Binds the events to the properties
---@param paletteProperty PaletteProperty
---@param primaryProperty ColorSelectionProperty
---@param secondaryProperty ColorSelectionProperty
function PaletteContainer:bindToProperties(paletteProperty, primaryProperty, secondaryProperty)
	-- If previously connected to a PaletteProperty, remove it
	if self.paletteProperty then
		self.paletteProperty.valueChanged:removeAction(self._paletteChangedAction)
		self._paletteChangedAction = nil
	end

	-- Connect to the new one, if it exists
	self.paletteProperty = paletteProperty
	if paletteProperty then
		local oldPalette = paletteProperty:get()
		---@cast oldPalette Palette

		self._paletteChangedAction = paletteProperty.valueChanged:addAction(function(property, value)
			---@cast value Palette
			self.palette = value
			self.paletteLockButton.palette = value
			self.paletteColors.palette = value
			self.paletteVScroll.offset = 0
			self.paletteSelections:setPalette(value)

			oldPalette = value

			self:refresh()
		end)

		self.palette = oldPalette
		self.paletteLockButton.palette = oldPalette
		self.paletteColors.palette = oldPalette
	end

	self.primaryColorSelection = primaryProperty
	self.secondaryColorSelection = secondaryProperty
	self.paletteColors.primarySelection = primaryProperty
	self.paletteColors.secondarySelection = secondaryProperty
	self.paletteSelections:setPalette(paletteProperty:get())
	self.paletteSelections.primarySelection = primaryProperty
	self.paletteSelections.secondarySelection = secondaryProperty
end

return PaletteContainer
