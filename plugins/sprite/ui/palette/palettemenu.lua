local Plan = require "lib.plan"
local Fonts = require "src.global.fonts"
local Palette = require "src.data.palette"
local Palettes = require "src.global.palettes"
local PopupWindow = require "ui.components.containers.modals.popupwindow"
local BaseButton = require "ui.components.button.basebutton"
local VScroll = require "ui.components.containers.box.vscroll"
local Action = require "src.data.action"
local Contexts = require "src.global.contexts"
local SpriteEditorContext = require "plugins.sprite.context.spriteeditorcontext"
local Handler = require "src.global.handler"

local defaultFont = Fonts.getDefaultFont()

---@class PaletteSelection: BaseButton
local PaletteSelection = BaseButton:extend()

---@type Action[]
local paletteWindowActions = {
	Action(
		"Close",
		function (action, source, presenter, context)
			presenter:close()
		end
	),
	Action(
		"New",
		function (action, source, presenter, context)
			local context = Contexts.getContextOfType(SpriteEditorContext)
			---@cast context SpriteEditor.Context?
			if context then
				local sprite = context.sprite
				if sprite then
					local spriteState = sprite.spriteState
					---@type Palette
					local newPalette = Palette()
					newPalette:addColor(spriteState.primaryColorSelection:getColor())
					newPalette:addColor(spriteState.secondaryColorSelection:getColor())
					sprite.palette:set(newPalette)
				end
			end
		end
	),
	Action(
		"Save",
		function (action, source, presenter, context)
			Contexts.raiseAction("save_palette")
		end
	),
	Action(
		"Refresh",
		function (action, source, presenter, context)
			Palettes.reloadPalettes()
			presenter.pmc.arePalettesLoaded = false
			presenter.pmc:addButtons()
		end
	),
	Action(
		"Open Folder",
		function (action, source, presenter, context)
			love.system.openURL(Palettes.paletteDirectories[1])
		end
	),
}

---Chooses the palette
---@param self PaletteSelection
local function choosePalette(self)
	local context = Contexts.getContextOfType(SpriteEditorContext)
	---@cast context SpriteEditor.Context?
	if context then
		local sprite = context.sprite
		if sprite then
			local newPalette = self.palette:clone()
			local paletteProperty = sprite.palette
			paletteProperty:set(newPalette)
		end
	end
end

---@param rules Plan.Rules
---@param palette Palette
function PaletteSelection:new(rules, palette)
	PaletteSelection.super.new(self, rules, choosePalette)
	---@type Palette
	self.palette = palette
end

local colorSize = 6
function PaletteSelection:draw()
	-- Background of the button
	love.graphics.setColor(0.2, 0.2, 0.4)
	if self.pressing then
		love.graphics.setColor(0.15, 0.15, 0.3)
	elseif self.hovering then
		love.graphics.setColor(0.25, 0.25, 0.5)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	-- Palette name
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(self.palette.name, defaultFont, self.x + 5, self.y + 5)

	-- Colors
	local palette = self.palette
	local xOffset = self.x + 5
	local yOffset = self.y + self.h - colorSize - 5
	for i = 1, math.min(#palette.colors, math.floor(self.w / colorSize)) do
		love.graphics.setColor(palette.colors[i])
		love.graphics.rectangle("fill", xOffset + colorSize * (i - 1), yOffset, colorSize, colorSize)
	end
end

function PaletteSelection:refresh()
	PaletteSelection.super.refresh(self)
end

---@class PaletteMenuContent: Plan.Container
local PaletteMenuContent = Plan.Container:extend()

function PaletteMenuContent:new(rules)
	PaletteMenuContent.super.new(self, rules)
	local container = VScroll(Plan.RuleFactory.full())
	container.allowScrolling = true
	---@type VScroll
	self.container = container
	self.arePalettesLoaded = false

	self:addChild(container)
end

function PaletteMenuContent:addButtons()
	if not self.arePalettesLoaded then
		self.arePalettesLoaded = true
		self.container:clearChildren(true)
		for _, palette in ipairs(Palettes.globalPalettes) do
			local newButton = PaletteSelection(Plan.Rules.new()
				:addX(Plan.pixel(0))
				:addY(Plan.keep())
				:addWidth(Plan.parent())
				:addHeight(Plan.pixel(48)),
				palette
			)
			self.container:addChild(newButton)
		end
	end
end

function PaletteMenuContent:draw()
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	PaletteMenuContent.super.draw(self)
end

---@class PaletteMenu: PopupWindow
local PaletteMenu = PopupWindow:extend()

function PaletteMenu:new(rules)
	PaletteMenu.super.new(self, rules, nil, "Select Palette")
	---@type PaletteMenuContent
	self.pmc = PaletteMenuContent(
		Plan.RuleFactory.full()
	)
	self:addChild(self.pmc)
	self:setActions(paletteWindowActions)
end

function PaletteMenu:onPopup()
	-- self:emit("onPopup")
	self.pmc:addButtons()
end

return PaletteMenu
