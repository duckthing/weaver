local Plugin = require "src.data.plugin"
local SpriteWindow = require "plugins.sprite.spritewindow"
local SpriteStatus = require "plugins.sprite.spritestatus"
local Status = require "src.global.status"
local Resources = require "src.global.resources"
local CreateSprite = require "plugins.sprite.objects.createsprite"
local ImportSprite = require "plugins.sprite.objects.importsprite"
local SpriteEditorContext = require "plugins.sprite.context.spriteeditorcontext"
local Contexts = require "src.global.contexts"
local Handler = require "src.global.handler"
local SpriteFormats = require "plugins.sprite.formats.spriteformats"

local IntegerProperty = require "src.properties.integer"
local StringProperty = require "src.properties.string"

Handler.addFormat(SpriteFormats)

---@class SpriteEditor: Plugin
local SpriteEditor = Plugin:extend()
SpriteEditor.TYPE = "sprite"

CreateSprite.addSpriteEditor(SpriteEditor)

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
		}
	},
	{
		name = "View",
		items = {
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
			actions.move_layer_down,
			actions.move_layer_up,
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
}

function SpriteEditor:new(rules)
	SpriteEditor.super.new(self, rules)
	---@type SpriteEditor.Context
	self.context = parentContext:asReference()
	self.context["%editor"] = self
	---@type SpriteEditor.Window
	self.container = SpriteWindow(rules, self, self.context)
	---@type SpriteStatus
	self.statusContext = SpriteStatus()
	self.statusContext:setEditor(self)
	self:setToolbarActions(spriteToolbarActions, self:getContext())
end

---@param sprite Sprite
local function updateTitle(sprite)
	local name = sprite.name:get()
	if sprite.modified:get() then
		love.window.setTitle(("*%s - Weaver"):format(name))
	else
		-- Not modified
		love.window.setTitle(("%s - Weaver"):format(name))
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
			resource.undoStack.maxSize = SpriteEditor.maxUndo:get()

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

function SpriteEditor:getCreateInspectable()
	return CreateSprite()
end

function SpriteEditor:getImportInspectable()
	return ImportSprite()
end

function SpriteEditor:getContext()
	return self.context
end

---@type IntegerProperty
SpriteEditor.maxUndo = IntegerProperty(SpriteEditor, "Undo History Limit", 30)
SpriteEditor.maxUndo:getRange()
	:setMin(0)
---@type StringProperty
SpriteEditor.defaultPalette = StringProperty(SpriteEditor, "Default Palette Name", "")

local settings = {
	SpriteEditor.maxUndo,
	SpriteEditor.defaultPalette,
}

function SpriteEditor:getSettings()
	return settings
end

SpriteEditor:assignAsDefault()
return SpriteEditor
