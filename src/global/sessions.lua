local json = require "lib.json"
local Luvent = require "lib.luvent"
local Plugin = require "src.data.plugin"
local GlobalConfig = require "src.global.config"

local SessionsModule = {}
SessionsModule.pluginDataLoaded = Luvent.newEvent()

---@class SessionData
---@field keymap Keybinds.SerializedData?
---@field settings {[string]: any}?
---@field data any

---A map of Plugin types to their data
---@type {[string]: SessionData}
local data = {}

function SessionsModule.getCachedData()
	return data
end

---@param plugin Plugin
local function getPersistentDataFromPlugin(plugin)
	local name = plugin.TYPE

	-- Get the session
	local pluginSession = data[name]
	if not pluginSession then
		-- Make a new session
		pluginSession = {
			keymap = nil,
			data = nil,
			settings = nil,
		}
		data[name] = pluginSession
	end

	-- Save keymap
	local context = plugin:getContext()
	if context then
		pluginSession.keymap = context:serializeKeybinds()
	end

	-- Save settings
	local settings = plugin:getSettings()
	---@type {[string]: any}
	local saved = {}
	for _, property in ipairs(settings) do
		local serialized = property:serialize()
		if serialized ~= nil then
			saved[property.name] = serialized
		end
	end

	pluginSession.settings = saved

	-- Save any other data
	pluginSession.data = plugin:getSessionData()
end

function SessionsModule.save()
	for _, plugin in ipairs(Plugin.plugins) do
		if plugin.TYPE ~= "unassigned" then
			getPersistentDataFromPlugin(plugin)
		end
	end

	love.filesystem.write(
		"session.json",
		json.encode(data)
	)
end

---@type {[Plugin]: boolean}
local alreadyLoaded = {}

---@param plugin Plugin
---@param sessionData SessionData
local function loadWithSessionData(plugin, sessionData)
	if alreadyLoaded[plugin] then return end
	alreadyLoaded[plugin] = true

	if sessionData then
		-- Existing data loaded
		-- Call it, even if it's nil
		plugin:setSessionData(sessionData.data)

		if sessionData.keymap then
			plugin:getContext():addChangedKeybinds(sessionData.keymap)
		end

		if sessionData.settings then
			---@type {[string]: any}
			local settingsData = sessionData.settings
			local settingsProperties = plugin:getSettings()

			for _, property in ipairs(settingsProperties) do
				local serialized = settingsData[property.name]
				if serialized ~= nil then
					property:deserialize(serialized)
				end
			end

			plugin:onSettingsLoaded()
		end
	else
		-- No data, return whatever the plugin has
		plugin:setSessionData()
		local context = plugin:getContext()
		if context then
			context:addChangedKeybinds(nil)
		end
		data[plugin.TYPE] = {
			data = plugin:getSessionData()
		}
	end
	SessionsModule.pluginDataLoaded:trigger(plugin)
end

function SessionsModule.load()
	do
		local dataString = love.filesystem.read("session.json")

		if dataString then
			data = json.decode(dataString)
		end
	end

	alreadyLoaded = {}
	for _, plugin in ipairs(Plugin.plugins) do
		local sessionData = data[plugin.TYPE]
		loadWithSessionData(plugin, sessionData)
	end
end

---@param newPlugin Plugin
Plugin.pluginInitialized:addAction(function(newPlugin)
	if not alreadyLoaded[newPlugin] then
		loadWithSessionData(newPlugin, data[newPlugin.TYPE])
	end
end)

return SessionsModule
