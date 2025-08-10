local Object = require "lib.classic"
local Luvent = require "lib.luvent"

---@class Plugin: Object
---@field container Plan.Container
---@field TYPE string
local Plugin = Object:extend()
---@type string
Plugin.TYPE = "unassigned"

---@type Plugin[]
Plugin.plugins = {}
Plugin.pluginInitialized = Luvent.newEvent()

function Plugin:new()
	Plugin.super.new(self)

	Plugin.plugins[#Plugin.plugins+1] = self

	---@type Editor[]
	self.editors = {}

	self._initialized = false
end

function Plugin:initialize()
	self._initialized = true
	Plugin.pluginInitialized:trigger(self)
end

local EMPTY_ARR = {}

---Returns an array of Contexts that are used in this Plugin
---@return Context[]
function Plugin:getContexts()
	return EMPTY_ARR
end

---Returns an array of Inspectables responsible for creating resources
---@return Inspectable[]
function Plugin:getCreateInspectables()
	return EMPTY_ARR
end

---Returns an array of Inspectables responsible for saving
---@return SaveTemplate[]
function Plugin:getSaveInspectables()
	return EMPTY_ARR
end

---Returns an array of Inspectables responsible for creating resources
---@return ImporterTemplate[]
function Plugin:getImportInspectables()
	return EMPTY_ARR
end

---Returns an array of Inspectables responsible for creating resources
---@return ExporterTemplate[]
function Plugin:getExportInspectables()
	return EMPTY_ARR
end

function Plugin:onExit()
end

function Plugin:onEnter()
end


---Returns an array of Properties
---@return Property[]
function Plugin:getSettings()
	return EMPTY_ARR
end

---Called when the settings for this editor are loaded
function Plugin:onSettingsLoaded()
end

---Returns the session data, which is what you want to save outside of settings.
---@return any
function Plugin:getSessionData()
end

---Sets the session data, which is usually the result of Editor:getSessionData()
---@param data any
function Plugin:setSessionData(data)
end

---Disables the Plugin, which should ideally clean itself up
function Plugin:disable()
end

return Plugin
