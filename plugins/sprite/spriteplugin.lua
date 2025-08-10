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

local HomeEditor = require "plugins.home.homeeditor"
local SettingsEditor = require "plugins.settings.settingseditor"
local KeysEditor = require "plugins.keys.keyeditor"

local CreateProject = require "src.objects.createproject"

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

local p = SpritePlugin()
local rules = Plan.RuleFactory.full()
SpriteEditor:setSourcePlugin(p)
SpriteEditor:assignAsDefault(rules)

print(#Plugin.plugins)

return p
