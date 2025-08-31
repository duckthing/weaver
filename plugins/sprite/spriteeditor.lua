local Editor = require "src.data.editor"
local SpriteWindow = require "plugins.sprite.spritewindow"
local SpriteStatus = require "plugins.sprite.spritestatus"
local Status = require "src.global.status"
local Resources = require "src.global.resources"
local Sprite = require "plugins.sprite.spriteresource"
local Palettes = require "src.global.palettes"
local CreateSprite = require "plugins.sprite.objects.createsprite"
local ExportSprite = require "plugins.sprite.objects.exportsprite"
local SpriteEditorContext = require "plugins.sprite.context.spriteeditorcontext"
local Contexts = require "src.global.contexts"
local SpriteGlobals = require "plugins.sprite.spriteglobals"
local Info = require "src.meta"

---@type SpritePlugin
local SpritePlugin

---@class SpriteEditor: Editor
local SpriteEditor = Editor:extend()
SpriteEditor.TYPE = "sprite"

Sprite.setEditor(SpriteEditor)
CreateSprite.addSpriteEditor(SpriteEditor)
ExportSprite.addSpriteEditor(SpriteEditor)

---@type SpriteEditor.Context
local parentContext = SpriteEditorContext()

local actions = parentContext:getActions()

---@type Toolbar.Item[]
local spriteToolbarActions = {
	{
		name = "Edit",
		items = {
			actions.undo,
			actions.redo,
			actions.copy_selection,
			actions.cut_selection,
			actions.paste_selection,
		}
	},
	{
		name = "View",
		items = {
			actions.show_grid_options,
			actions.fit_sprite,
		}
	},
	{
		name = "Select",
		items = {
			actions.select_all,
			actions.invert_selection,
			actions.crop_to_selection,
			actions.set_brush_to_selection_mask,
			actions.set_brush_to_selection_color,
		}
	},
	{
		name = "Sprite",
		items = {
			actions.resize_canvas,
			actions.crop_to_content,
			actions.save_palette,
			actions.toggle_palette_lock,
			-- Action("Scale Canvas")
		}
	},
	{
		name = "Layer",
		items = {
			actions.new_layer,
			actions.clone_layer,
			actions.delete_layer,
			actions.merge_layer_down,
			actions.move_layer_up,
			actions.move_layer_down,
		}
	},
	{
		name = "Frame",
		items = {
			actions.new_frame,
			actions.clone_frame,
			actions.clone_linked_frame,
			actions.delete_frame,
			actions.move_frame_left,
			actions.move_frame_right,
		}
	},
	{
		name = "Animation",
		items = {
			actions.new_animation,
			actions.clone_animation,
			actions.delete_animation,
			actions.new_track,
			actions.clone_track,
			actions.delete_track,
		}
	},
}

function SpriteEditor:new(rules)
	SpriteEditor.super.new(self, rules)
	---@type SpriteEditor.Context
	self.context = parentContext:asReference()
	self.context["%editor"] = self
	---@type SpriteEditor.Window
	self.container = SpriteWindow(rules, SpritePlugin, self.context)
	---@type SpriteStatus
	self.statusContext = SpriteStatus()
	self.statusContext:setEditor(self)
	self:setToolbarActions(spriteToolbarActions, self:getContext())
end

---Returns the default palette from user preferences, or a random one
---@return Palette
function SpriteEditor.getDefaultPalette()
	---@type Palette
	local palette
	-- Find the default palette
	local paletteName = SpritePlugin.defaultPalette:get()

	---@type Palette
	if paletteName ~= "" then
		-- If there is a desired default...
		for _, p in ipairs(Palettes.globalPalettes) do
			if p.name == paletteName then
				palette = p:clone()
			end
		end
	end

	if not palette then
		-- Clone a random palette if we don't have a default/couldn't find one
		palette = Palettes.globalPalettes[love.math.random(1, #Palettes.globalPalettes)]:clone()
	end

	return palette
end

---@param sprite Sprite
local function updateTitle(sprite)
	local name = sprite.name:get()
	if sprite.modified:get() then
		love.window.setTitle(("*%s - Weaver %s"):format(name, Info.VERSION))
	else
		-- Not modified
		love.window.setTitle(("%s - Weaver %s"):format(name, Info.VERSION))
	end
end

function SpriteEditor:onEnter()
	Status.changeContext(self.statusContext)

	-- TODO: Clean
	-- This changes the title when a sprite is selected

	---@type Sprite?
	self.oldSprite = nil
	self._nameChangedAction = nil
	self._modifiedAction = nil
	---@param resource Resource
	self._resourceSelectedAction = Resources.onResourceSelected:addAction(function(resource)
		self:removeActionsFromResource()

		if resource.TYPE == "sprite" then
			---@cast resource Sprite
			updateTitle(resource)
			resource.undoStack.maxSize = SpriteGlobals.SpritePlugin.maxUndo:get()

			local oldResource = self.oldSprite
			if oldResource ~= resource then
				self.oldSprite = resource
			end

			self._nameChangedAction = resource.name.valueChanged:addAction(function()
				updateTitle(resource)
			end)

			self._modifiedAction = resource.modified.valueChanged:addAction(function()
				updateTitle(resource)
			end)
		end
	end)

	Contexts.pushContext(self.context)
end


function SpriteEditor:onExit()
	Status.changeContext()

	if self._resourceSelectedAction then
		Resources.onResourceSelected:removeAction(self._resourceSelectedAction)
		self._resourceSelectedAction = nil
	end

	self:removeActionsFromResource()

	Contexts.popContext(self.context)
end

function SpriteEditor:removeActionsFromResource()
	if not self.oldSprite then return end
	if self._nameChangedAction then
		self.oldSprite.name.valueChanged:removeAction(self._nameChangedAction)
		self._nameChangedAction = nil
	end

	if self._modifiedAction then
		self.oldSprite.modified.valueChanged:removeAction(self._modifiedAction)
		self._modifiedAction = nil
	end
end

function SpriteEditor:getContext()
	return self.context
end

---@param plugin SpritePlugin
function SpriteEditor:setSourcePlugin(plugin)
	SpriteEditor.super.setSourcePlugin(self, plugin)
	SpritePlugin = plugin
end

return SpriteEditor
