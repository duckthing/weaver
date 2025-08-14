local Plugin = require "src.data.plugin"
local Editor = require "src.data.editor"
local Plan = require "lib.plan"
local GlobalContext = require "src.objects.globalcontext"
local Contexts = require "src.global.contexts"
local Modal = require "src.global.modal"
local ConfigGlobals = require "plugins.home.configglobals"
local Meta = require "src.meta"

local LabelProperty = require "src.properties.label"
local ButtonProperty = require "src.properties.button"
local BoolProperty = require "src.properties.bool"
local NumberProperty = require "src.properties.number"
local IntegerProperty = require "src.properties.integer"
local StringProperty = require "src.properties.string"

local HomeEditor = require "plugins.home.homeeditor"
local SettingsEditor = require "plugins.settings.settingseditor"
local KeysEditor = require "plugins.keys.keyeditor"

local CreateProject = require "src.objects.createproject"
local ImportProject = require "src.objects.importproject"

---@class GlobalConfig: Plugin
local GlobalConfig = Plugin:extend()
GlobalConfig.TYPE = "global"

---@type LabelProperty
GlobalConfig.disclaimer = LabelProperty(GlobalConfig, "Disclaimer", "Weaver is alpha software; settings may be reset between versions\nYou may need to restart for changes to take effect")
---@type NumberProperty
GlobalConfig.appScale = NumberProperty(GlobalConfig, "App Scale", 1)
	:setKey("appScale")
GlobalConfig.appScale:getRange()
	:setMin(0.25)
	:setMax(4)
	:setStep(0.05)
---@type IntegerProperty
GlobalConfig.maxRecentItems = IntegerProperty(GlobalConfig, "Max Recent Items", 30)
	:setKey("maxRecentItems")
---@type BoolProperty
GlobalConfig.pixelFont = BoolProperty(GlobalConfig, "Use Pixel Font", false)
	:setKey("pixelFont")
---@type BoolProperty
GlobalConfig.restoreWindowSize = BoolProperty(GlobalConfig, "Restore Window Size on Launch", true)
	:setKey("restoreWindowSize")
---@type StringProperty
GlobalConfig.defaultResource = StringProperty(GlobalConfig, "Default Resource to Create", "Sprite")
	:setKey("defaultResource")
--[[GlobalConfig.editKeybinds = ButtonProperty(GlobalConfig, "Edit Keybinds",
	function(button)
		Resources.selectResourceId(Resources.addResource(KeyResource()))
	end
)]]
GlobalConfig.viewAppLicense = ButtonProperty(GlobalConfig, "View App License",
	function(button)
		Contexts.raiseAction("show_app_license")
	end
)
GlobalConfig.viewThirdPartyLicenses = ButtonProperty(GlobalConfig, "View Third-Party Licenses",
	function(button)
		Contexts.raiseAction("show_third_party_licenses")
	end
)
GlobalConfig.resetKeybindsToDefault = ButtonProperty(GlobalConfig, "Reset Keybinds (if broken/missing)",
	function(button)
		for _, plugin in ipairs(Plugin.plugins) do
			for _, context in ipairs(plugin:getContexts()) do
				context:addChangedKeybinds(nil)
			end
		end
		button:setLabel("Done!")
	end
)
GlobalConfig.firstLaunch = true

---@type string[]
GlobalConfig.recentItems = {}
---@type string[]
GlobalConfig.recentProjects = {}

local DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT =
	800, 600

---@param arr any[]
---@param item any
---@param maxItems integer
local function bumpRecents(arr, item, maxItems)
	for i = 1, #arr do
		if arr[i] == item then
			-- Bump this to be more recent
			arr[i], arr[1] = arr[1], arr[i]
			return
		end
	end

	-- Add this to the front
	table.insert(arr, 1, item)

	-- Remove from the end of the array
	for _ = 1, #arr - maxItems do
		arr[#arr] = nil
	end
end

---Adds a file to the recent history
---@param path string
function GlobalConfig.addFileToRecents(path)
	local arr = GlobalConfig.recentItems
	local maxItems = GlobalConfig.maxRecentItems:get()
	bumpRecents(arr, path, maxItems)
end

---Adds a project to the recent history
---@param path string
function GlobalConfig.addProjectToRecents(path)
	local arr = GlobalConfig.recentProjects
	local maxItems = GlobalConfig.maxRecentItems:get()
	bumpRecents(arr, path, maxItems)
end

function GlobalConfig:new()
	GlobalConfig.super.new(self)
	---@type GlobalContext
	self.context = GlobalContext()

	self.contexts = {
		self.context
	}
end

function GlobalConfig:getSessionData()
	local windowW, windowH = DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT
	if Modal.uiRoot then
		local root = Modal.uiRoot.root
		windowW, windowH = root.w, root.h
	end
	return {
		recentItems = GlobalConfig.recentItems,
		recentProjects = GlobalConfig.recentProjects,
		maximized = love.window.isMaximized(),
		windowW = windowW,
		windowH = windowH,
		fromVersion = Meta.VERSION_NUMBER,
	}
end

function GlobalConfig:setSessionData(data)
	if data then
		GlobalConfig.firstLaunch = false
		GlobalConfig.recentItems = data.recentItems
		GlobalConfig.recentProjects = data.recentProjects

		if GlobalConfig.restoreWindowSize:get() then
			if data.maximized then
				love.window.maximize()
			else
				local desktopW, desktopH = love.window.getDesktopDimensions()
				love.window.setMode(
					math.min(data.windowW or DEFAULT_WINDOW_WIDTH, desktopW),
					math.min(data.windowH or DEFAULT_WINDOW_HEIGHT, desktopH),
					{resizable = true}
				)
			end
		end
	end

	Editor.defaultEditors.home:setSessionData(data)
end

function GlobalConfig:getSettings()
	return {
		GlobalConfig.disclaimer,
		GlobalConfig.appScale,
		GlobalConfig.maxRecentItems,
		GlobalConfig.pixelFont,
		GlobalConfig.restoreWindowSize,
		GlobalConfig.defaultResource,
		-- GlobalConfig.editKeybinds,
		GlobalConfig.viewThirdPartyLicenses,
		GlobalConfig.viewAppLicense,
		GlobalConfig.resetKeybindsToDefault,
	}
end

function GlobalConfig:getCreateInspectables()
	return {CreateProject()}
end

function GlobalConfig:getImportInspectables()
	return {ImportProject()}
end

function GlobalConfig:getContexts()
	return self.contexts
end

local g = GlobalConfig()
ConfigGlobals.GlobalConfig = g

local rules = Plan.RuleFactory.full()

local he = HomeEditor:assignAsDefault(rules)
local se = SettingsEditor:assignAsDefault(rules)

he:setSourcePlugin(g)
se:setSourcePlugin(g)

g:initialize()
return g
