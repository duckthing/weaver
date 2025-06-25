local Plugin = require "src.data.plugin"
local Resources = require "src.global.resources"
local Modal = require "src.global.modal"
local Context = require "src.data.context"
local Keybinds = require "src.data.keybinds"
local Action = require "src.data.action"
local SettingsResource = require "plugins.settings.settingsbuffer"
local HomeBuffer = require "plugins.home.homebuffer"
local OpenFileObject = require "src.objects.openfileobject"
local LicenseWindow = require "ui.main.licensewindow"
local CreateResource = require "src.objects.createresource"

---@class GlobalContext: Context
local GlobalContext = Context:extend()
GlobalContext.CONTEXT_NAME = "Global"

---@type Keybinds.ActionsMap
local actions = {
	cycle_resource_forward = Action(
		"Cycle Resource Forward",
		function()
			local index = 0
			local size = #Resources.activeResources
			for i = 1, size do
				if Resources.activeResources[i] == Resources.currentResource then
					index = i
					break
				end
			end
			local nextResource = Resources.activeResources[index % size + 1]
			Resources.selectResourceId(nextResource.id)
		end
	),
	cycle_resource_backward = Action(
		"Cycle Resource Backward",
		function()
			local index = 0
			local size = #Resources.activeResources
			for i = 1, size do
				if Resources.activeResources[i] == Resources.currentResource then
					index = i
					break
				end
			end
			index = index - 1
			if index == 0 then
				index = size
			end
			local prevResource = Resources.activeResources[index]
			Resources.selectResourceId(prevResource.id)
		end
	),
	new_resource = Action(
		"New...",
		function()
			local createResource = CreateResource()
			Modal.pushInspector(createResource)
		end
	),
	open_resource = Action(
		"Open...",
		function()
			local openFileObj = OpenFileObject()
			openFileObj:present()
		end
	),
	save_resource = Action(
		"Save",
		function()
			local resource = Resources.getCurrentResource()
			if resource then
				---@type SaveTemplate?
				local saveTemplate = resource:getSaveTemplate()
				if saveTemplate then
					saveTemplate:saveOrPresent()
				end
			end
		end
	),
	save_resource_as = Action(
		"Save as...",
		function()
			local resource = Resources.getCurrentResource()
			if resource then
				---@type SaveTemplate?
				local saveTemplate = resource:getSaveTemplate()
				if saveTemplate then
					saveTemplate:present()
				end
			end
		end
	),
	export_as = Action(
		"Export...",
		function()
			local resource = Resources.getCurrentResource()
			if resource then
				---@type Inspectable?
				local exporter = resource:getExporter()
				if exporter then
					Modal.pushInspector(exporter)
				end
			end
		end
	),
	redo_export = Action(
		"Redo Last Export",
		function()
			local resource = Resources.getCurrentResource()
			if resource then
				local exporter = resource:getExporter()
				if exporter then
					if exporter.alreadyExported then
						exporter:export()
					else
						Modal.pushInspector(exporter)
					end
				end
			end
		end
	),
	reload_resource = Action("Reload Resource"),
	close_resource = Action(
		"Close File",
		function()
			Resources.removeResource(Resources.currentResource.id)
		end
	),
	open_settings = Action(
		"Settings",
		function()
			for _, resource in ipairs(Resources.activeResources) do
				if resource.TYPE == SettingsResource.TYPE then
					-- It exists already, don't create a new one
					Resources.selectResourceId(resource.id)
					return
				end
			end

			Resources.selectResourceId(Resources.addResource(SettingsResource()))
		end
	),
	open_home = Action(
		"Home",
		function()
			for _, resource in ipairs(Resources.activeResources) do
				if resource.TYPE == HomeBuffer.TYPE then
					-- It exists already, don't create a new one
					Resources.selectResourceId(resource.id)
					return
				end
			end

			Resources.selectResourceId(Resources.addResource(HomeBuffer()))
		end
	),
	quit = Action(
		"Quit",
		function()
			love.event.quit()
		end
	),
	show_third_party_licenses = Action(
		"Show Third-Party Licenses",
		function()
			Modal.pushNewWindow(LicenseWindow, 650, 400)
		end
	),
	show_app_license = Action(
		"Show App License",
		function()
			local window = LicenseWindow(nil, {{
				library = "Weaver",
				authors = "duckthing",
				licenseName = "MIT",
				body =
[[MIT License

Copyright (c) 2025, duckthing

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]
			}}, "App License")
			Modal.pushExistingWindow(window, 650, 400)
		end
	),
	toggle_full_screen = Action(
		"Toggle Full Screen",
		function()
			local bool, mode = love.window.getFullscreen()
			if bool then
				love.window.setFullscreen(false)
			else
				love.window.setFullscreen(true)
			end
		end
	)
}

---@type Keybinds.KeyCombinations
local defaultKeybinds = {
	normal = {
		f11 = "toggle_full_screen",
	},
	ctrl = {
		tab = "cycle_resource_forward",
		n = "new_resource",
		o = "open_resource",
		s = "save_resource",
		e = "export_as",
		w = "close_resource",
	},
	altctrl = {
		s = "save_resource_as",
	},
	ctrlshift = {
		tab = "cycle_resource_backward",
		e = "redo_export",
		s = "save_resource_as",
		x = "redo_export",
	}
}

function GlobalContext:new()
	GlobalContext.super.new(self)
	---@type Plan.Root
	self.uiRoot = nil
	self.keybinds = Keybinds(defaultKeybinds, actions)
end

function GlobalContext:getActions()
	return actions
end

function GlobalContext:getDefaultKeybinds()
	return defaultKeybinds
end

function GlobalContext:getKeybinds()
	return self.keybinds
end

return GlobalContext
