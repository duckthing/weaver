local Plan = require "lib.plan"
local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Action = require "src.data.action"

---@class Plugin: Object
---@field container Plan.Container
---@field TYPE string
local Plugin = Object:extend()
---@type string
Plugin.TYPE = "unassigned"

---@type Plugin[]
Plugin.plugins = {}
---@type {[string]: Plugin}
Plugin.defaultEditors = {}
Plugin.pluginInitialized = Luvent.newEvent()

---Returns the best Plugin for editing the Resource
---@param resource Resource?
---@return Plugin?
function Plugin.getDefaultEditor(resource)
	if resource then
		return Plugin.defaultEditors[resource.TYPE]
	end
	return nil
end

---@type Toolbar.Item[]
Plugin.toolbarActions = {
	{
		name = "File",
		items = {}
	},
	{
		name = "Project",
		items = {}
	},
	{
		name = "Edit",
		items = {}
	},
	{
		name = "View",
		items = {}
	},
	{
		name = "Select",
		items = {}
	},
}

---Added after everything else
---@type Toolbar.Item[]
Plugin.lastToolbarActions = {}

Plugin.globalToolbarChanged = Luvent.newEvent()

---Sets the GlobalContext for all Plugins. Necessary for global shortcuts.
---@param globalContext GlobalContext
function Plugin.setGlobalContext(globalContext)
	local actions = globalContext:getActions()
	Plugin.toolbarActions = {
		{
			name = "File",
			items = {
				actions.new_resource,
				actions.open_resource,
				actions.save_resource,
				actions.save_resource_as,
				actions.export_as,
				actions.redo_export,
				-- TODO: Add resource reloading
				-- actions.reload_resource,
				actions.close_resource,
			}
		},
		{
			name = "Project",
			items = {}
		},
		{
			name = "Edit",
			items = {}
		},
		{
			name = "View",
			items = {}
		},
		{
			name = "Select",
			items = {}
		}
	}

	Plugin.lastToolbarActions = {
		{
			name = "File",
			items = {
				Action(""),
				actions.open_settings,
				actions.open_home,
				actions.quit,
			}
		},
		{
			name = "View",
			items = {
				actions.toggle_full_screen,
			}
		}
	}

	Plugin.globalToolbarChanged:trigger()
end

---@param rules Plan.Rules
function Plugin:new(rules)
	---@type Plan.Container
	self.container = nil
	---@type Inspectable?
	self.createInspectable = nil

	self.toolbarActions = {}
	self:mergeToolbarActions({Plugin.toolbarActions, Plugin.lastToolbarActions})

	self.toolbarActionsChanged = Luvent.newEvent()

	Plugin.plugins[#Plugin.plugins+1] = self

	self._globalToolbarChangedAction = Plugin.globalToolbarChanged:addAction(function()
		if self.toolbarActions then
			self:setToolbarActions(self.toolbarActions, self.toolbarContext)
		else
			self:mergeToolbarActions({Plugin.toolbarActions, Plugin.lastToolbarActions})
			self.toolbarActionsChanged:trigger(self, self:getToolbarActions(), nil)
		end
	end)
end

function Plugin:initialize()
	Plugin.pluginInitialized:trigger(self)
end

local rules = Plan.RuleFactory.full()

function Plugin:assignAsDefault()
	---@type Plugin
	local plugin = self(rules)
	plugin:initialize()
	Plugin.defaultEditors[self.TYPE] = plugin
end

function Plugin:onExit()
end

function Plugin:onEnter()
end

---Returns the toolbar actions
---@return Toolbar.Item[]
function Plugin:getToolbarActions()
	return self.mergedActions
end

---Sets the toolbar actions.
---This method is expensive. Don't call it frequently.
---@param items Toolbar.Item[]
---@param context Action.Context?
function Plugin:setToolbarActions(items, context)
	self.toolbarActions = items
	self.toolbarContext = context
	self:mergeToolbarActions({Plugin.toolbarActions, items, Plugin.lastToolbarActions})
	self.toolbarActionsChanged:trigger(self, self:getToolbarActions(), context)
end

---Merges all toolbar actions
---@param allItems Toolbar.Item[][]
function Plugin:mergeToolbarActions(allItems)
	---@type Toolbar.Item[]
	local mergedItems = {}
	---@type {[string]: integer}
	local nameMap = {}

	for _, itemCollection in ipairs(allItems) do
		for _, items in ipairs(itemCollection) do
			local mergedIndex = nameMap[items.name]
			if not mergedIndex then
				mergedIndex = #mergedItems + 1
				nameMap[items.name] = mergedIndex
				mergedItems[mergedIndex] = {
					name = items.name,
					items = {}
				}
			end
			local nItems = mergedItems[mergedIndex].items

			for _, item in ipairs(items.items) do
				nItems[#nItems+1] = item
			end
		end
	end

	-- Remove unused items
	for i = #mergedItems, 1, -1 do
		local items = mergedItems[i]
		if #items.items == 0 then
			table.remove(mergedItems, i)
		end
	end

	self.mergedActions = mergedItems
	return mergedItems
end

---Returns the Context
---@return Context?
function Plugin:getContext()
	return nil
end

---@return Inspectable?
function Plugin:getCreateInspectable()
	return nil
end

---@return ImporterTemplate?
function Plugin:getImportInspectable()
	return nil
end

---@type Property[]
local EMPTY_ARR = {}

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

return Plugin
