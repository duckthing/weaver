local Plugin = require "src.data.plugin"
local Resources = require "src.global.resources"
local KeyWindow = require "plugins.keys.keywindow"

---@class KeyEditor: Plugin
local KeyEditor = Plugin:extend()
KeyEditor.TYPE = "key"

function KeyEditor:new(rules)
	KeyEditor.super.new(self, rules)
	---@type SettingsEditor.Window
	self.container = KeyWindow(rules, self)
	---@type KeyResource
	self.resource = nil
end

function KeyEditor:onEnter()
	love.window.setTitle("Weaver")
	---@param resource Resource
	self._resourceSelectedAction = Resources.onResourceSelected:addAction(function(resource)
		if resource.TYPE == "key" then
			---@cast resource KeyResource
			self.resource = resource
		end
	end)
end

function KeyEditor:onExit()
	if self._resourceSelectedAction then
		Resources.onResourceSelected:removeAction(self._resourceSelectedAction)
		self._resourceSelectedAction = nil
	end
end

KeyEditor:assignAsDefault()
return KeyEditor
