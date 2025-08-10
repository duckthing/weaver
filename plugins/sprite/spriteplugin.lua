local Plugin = require "src.data.plugin"
local Plan = require "lib.plan"
local GlobalContext = require "src.objects.globalcontext"
local Contexts = require "src.global.contexts"
local Modal = require "src.global.modal"
local SpriteEditor = require "plugins.sprite.spriteeditor"

local BoolProperty = require "src.properties.bool"
local IntegerProperty = require "src.properties.integer"
local StringProperty = require "src.properties.string"
local EnumProperty = require "src.properties.enum"
local ColorSelectionProperty = require "src.properties.colorselection"

local CreateSprite = require "plugins.sprite.objects.createsprite"
local SaveSprite = require "plugins.sprite.objects.savesprite"
local ImportSprite = require "plugins.sprite.objects.importsprite"
local ExportSprite = require "plugins.sprite.objects.exportsprite"

---@class SpritePlugin: Plugin
local SpritePlugin = Plugin:extend()
SpritePlugin.TYPE = "sprite"

function SpritePlugin:new()
	SpritePlugin.super.new(self)
	print("created")
end

---@type IntegerProperty
SpritePlugin.maxUndo = IntegerProperty(SpritePlugin, "Undo History Limit", 50)
	:setKey("maxUndo")
SpritePlugin.maxUndo:getRange()
	:setMin(0)
---@type StringProperty
SpritePlugin.defaultPalette = StringProperty(SpritePlugin, "Default Palette Name", "")
	:setKey("defaultPalette")
---@type EnumProperty
SpritePlugin.defaultDataExtension = EnumProperty(SpritePlugin, "Default Data Extension", ".lua")
	:setKey("defaultDataExtension")
SpritePlugin.defaultDataExtension:setOptions({
	{
		name = "*.lua",
		value = "lua",
	},
	{
		name = "*.json",
		value = "json",
	}
})
---@type BoolProperty
SpritePlugin.useOldLayout = BoolProperty(SpritePlugin, "Use Old Layout", false)
	:setKey("useOldLayout")
---@type ColorSelectionProperty
SpritePlugin.checkerboardPrimary = ColorSelectionProperty(
	SpritePlugin, "Checkerboard Primary Color", {0.65, 0.65, 0.65}
)
	:setKey("checkerboardPrimary")
---@type ColorSelectionProperty
SpritePlugin.checkerboardSecondary = ColorSelectionProperty(
	SpritePlugin, "Checkerboard Secondary Color", {0.45, 0.45, 0.5}
)
	:setKey("checkerboardSecondary")

function SpritePlugin:getCreateInspectables()
	return {CreateSprite()}
end

function SpritePlugin:getSaveInspectables()
	return {SaveSprite()}
end

function SpritePlugin:getImportInspectables()
	return {ImportSprite()}
end

function SpritePlugin:getExportInspectables()
	return {ExportSprite()}
end

local settings = {
	SpritePlugin.maxUndo,
	SpritePlugin.defaultPalette,
	SpritePlugin.defaultDataExtension,
	SpritePlugin.useOldLayout,
	SpritePlugin.checkerboardPrimary,
	SpritePlugin.checkerboardSecondary,
}

function SpritePlugin:getSettings()
	return settings
end

---@type SpritePlugin
local p = SpritePlugin()
local rules = Plan.RuleFactory.full()
SpriteEditor:setSourcePlugin(p)
local se = SpriteEditor:assignAsDefault(rules)

print(#Plugin.plugins)

function SpritePlugin:getContext()
	print("omg")
	print(se:getContext())
	return se:getContext()
end

p:initialize()
return p
