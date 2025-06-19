local Plugin = require "src.data.plugin"
local Resources = require "src.global.resources"
local SettingsWindow = require "plugins.settings.settingswindow"

---@class SettingsEditor: Plugin
local SettingsEditor = Plugin:extend()
SettingsEditor.TYPE = "settings"

function SettingsEditor:new(rules)
	SettingsEditor.super.new(self, rules)
	---@type SettingsEditor.Window
	self.container = SettingsWindow(rules, self)
	---@type SettingsResource
	self.resource = nil
end

function SettingsEditor:onEnter()
	love.window.setTitle("Weaver")
	---@param resource Resource
	self._bufferSelectedAction = Resources.onResourceSelected:addAction(function(resource)
		if resource.TYPE == "settings" then
			---@cast resource SettingsResource
			self.resource = resource
		end
	end)
end

function SettingsEditor:onExit()
	if self._bufferSelectedAction then
		Resources.onResourceSelected:removeAction(self._bufferSelectedAction)
		self._bufferSelectedAction = nil
	end
end

SettingsEditor:assignAsDefault()
return SettingsEditor
