local Resources = require "src.global.resources"
local KeyResource = require "plugins.keys.keybuffer"
local Plugin = require "src.data.plugin"
local GlobalContext = require "src.objects.globalcontext"
local Contexts = require "src.global.contexts"

local LabelProperty = require "src.properties.label"
local ButtonProperty = require "src.properties.button"
local BoolProperty = require "src.properties.bool"
local NumberProperty = require "src.properties.number"
local IntegerProperty = require "src.properties.integer"
local StringProperty = require "src.properties.string"

local CreateProject = require "src.objects.createproject"

---@class GlobalConfig: Plugin
local GlobalConfig = Plugin:extend()
GlobalConfig.TYPE = "global"

GlobalConfig.disclaimer = LabelProperty(GlobalConfig, "Disclaimer", "Weaver is alpha software; settings may be reset between versions\nYou may need to restart for changes to take effect")
---@type NumberProperty
GlobalConfig.appScale = NumberProperty(GlobalConfig, "App Scale", 1)
GlobalConfig.appScale:getRange()
	:setMin(0.25)
	:setMax(4)
	:setStep(0.05)
---@type IntegerProperty
GlobalConfig.maxRecentItems = IntegerProperty(GlobalConfig, "Max Recent Items", 30)
---@type BoolProperty
GlobalConfig.pixelFont = BoolProperty(GlobalConfig, "Use Pixel Font", true)
---@type StringProperty
GlobalConfig.defaultResource = StringProperty(GlobalConfig, "Default Resource to Create", "Sprite")
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
GlobalConfig.firstLaunch = true

---@type string[]
GlobalConfig.recentItems = {}
---@type string[]
GlobalConfig.recentProjects = {}

---Adds a file to the recent history
---@param path string
function GlobalConfig.addFileToRecents(path)
	local arr = GlobalConfig.recentItems

	for i = 1, #arr do
		if arr[i] == path then
			-- Bump this to be more recent
			arr[i], arr[1] = arr[1], arr[i]
			return
		end
	end

	-- Add this to the front
	table.insert(arr, 1, path)

	-- Remove from the end of the array
	for i = 1, #arr - GlobalConfig.maxRecentItems:get() do
		arr[#arr] = nil
	end
end

function GlobalConfig:new()
	GlobalConfig.super.new(self)
	---@type GlobalContext
	self.context = GlobalContext()
end

function GlobalConfig:getContext()
	return self.context
end

function GlobalConfig:getSessionData()
	return {
		recentItems = GlobalConfig.recentItems,
		recentProjects = GlobalConfig.recentProjects,
	}
end

function GlobalConfig:setSessionData(data)
	if data then
		GlobalConfig.firstLaunch = false
		GlobalConfig.recentItems = data.recentItems
		GlobalConfig.recentProjects = data.recentProjects
	end
end

function GlobalConfig:getSettings()
	return {
		GlobalConfig.disclaimer,
		GlobalConfig.appScale,
		GlobalConfig.maxRecentItems,
		GlobalConfig.pixelFont,
		GlobalConfig.defaultResource,
		-- GlobalConfig.editKeybinds,
		GlobalConfig.viewThirdPartyLicenses,
		GlobalConfig.viewAppLicense,
	}
end

function GlobalConfig:getCreateInspectable()
	return CreateProject()
end

GlobalConfig:assignAsDefault()
return GlobalConfig
