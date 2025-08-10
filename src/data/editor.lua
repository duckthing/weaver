local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Action = require "src.data.action"

---@class Editor: Object
local Editor = Object:extend()
Editor.TYPE = "none"
---@type Plugin
Editor.plugin = nil

---@type {[string]: Editor}
Editor.defaultEditors = {}

---@type Toolbar.Item[]
Editor.toolbarActions = {
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
Editor.lastToolbarActions = {}

Editor.globalToolbarChanged = Luvent.newEvent()

---@param rules Plan.Rules
function Editor:new(rules)
	Editor.super.new(self)

	---@type Plan.Container
	self.container = nil

	self.toolbarActions = {}
	self:mergeToolbarActions({Editor.toolbarActions, Editor.lastToolbarActions})

	self.toolbarActionsChanged = Luvent.newEvent()


	self._globalToolbarChangedAction = Editor.globalToolbarChanged:addAction(function()
		if self.toolbarActions then
			self:setToolbarActions(self.toolbarActions, self.toolbarContext)
		else
			self:mergeToolbarActions({Editor.toolbarActions, Editor.lastToolbarActions})
			self.toolbarActionsChanged:trigger(self, self:getToolbarActions(), nil)
		end
	end)
end

function Editor:onEnter()
end

function Editor:onExit()
end

---Returns the toolbar actions
---@return Toolbar.Item[]
function Editor:getToolbarActions()
	return self.mergedActions
end

---Sets the toolbar actions.
---This method is expensive. Don't call it frequently.
---@param items Toolbar.Item[]
---@param context Action.Context?
function Editor:setToolbarActions(items, context)
	self.toolbarActions = items
	self.toolbarContext = context
	self:mergeToolbarActions({Editor.toolbarActions, items, Editor.lastToolbarActions})
	self.toolbarActionsChanged:trigger(self, self:getToolbarActions(), context)
end

---Merges all toolbar actions
---@param allItems Toolbar.Item[][]
function Editor:mergeToolbarActions(allItems)
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
function Editor:getContext()
	return nil
end

---Sets the GlobalContext for all Editors. Necessary for global shortcuts.
---@param globalContext GlobalContext
function Editor.setGlobalContext(globalContext)
	local actions = globalContext:getActions()
	Editor.toolbarActions = {
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

	Editor.lastToolbarActions = {
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

	Editor.globalToolbarChanged:trigger()
end

---Assigns this Editor as the default for its types
---@param rules Plan.Rules
---@return Editor
function Editor:assignAsDefault(rules)
	---@type Editor
	local editor = self(rules)
	Editor.defaultEditors[editor.TYPE] = editor
	return editor
end

---Returns the best Editor for editing the Resource
---@param resource Resource?
---@return Editor?
function Editor.getDefaultEditor(resource)
	if resource then
		return Editor.defaultEditors[resource.TYPE]
	end
	return nil
end

---Sets the Plugin where this Editor came from
---@param plugin Plugin
function Editor:setSourcePlugin(plugin)
	self.plugin = plugin
end

return Editor
