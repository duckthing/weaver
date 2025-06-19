local Resources = require "src.global.resources"
local Plan = require "lib.plan"
local Tabline = require "ui.main.tabline"
local Toolbar = require "ui.main.toolbar"
local StatusBar = require "ui.main.statusbar"

local Plugin = require "src.data.plugin"
local HomeEditor = require "plugins.home.homeeditor"
local SpriteEditor = require "plugins.sprite.spriteeditor"
local SettingsEditor = require "plugins.settings.settingseditor"
local KeyEditor = require "plugins.keys.keyeditor"

---@class Previewer: Plan.Container
local Previewer = Plan.Container:extend()

function Previewer:new(r)
	Previewer.super.new(self, r)
	---@type Plugin?
	self.currentEditor = nil

	---@type Toolbar
	local toolbar = Toolbar(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(26))
	)
	---@type Bufferline
	local bufferline = Tabline(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(26))
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(30))
	)
	---@type StatusBar
	local statusbar = StatusBar(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.max(30))
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(30))
	)
	---@type Plan.Container
	local container = Plan.Container(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(56))
			:addWidth(Plan.parent())
			:addHeight(Plan.max(86))
	)

	self:addChild(toolbar)
	self:addChild(bufferline)
	self:addChild(statusbar)
	self:addChild(container)

	self.toolbar = toolbar
	self.bufferline = bufferline
	self.statusbar = statusbar
	self.container = container

	---@type string?
	self._toolbarActionsChanged = nil

	---@param selectedResource Resource
	Resources.onResourceSelected:addAction(function (selectedResource)
		local bestEditor = Plugin.getDefaultEditor(selectedResource)
		local currentEditor = self.currentEditor
		-- If the editor plugin is different, switch
		if bestEditor ~= currentEditor then
			if currentEditor then
				-- Remove the current editor
				currentEditor.toolbarActionsChanged:removeAction(self._toolbarActionsChanged)
				self.container:removeChild(currentEditor.container)
				currentEditor:onExit()
				self.currentEditor = nil
			end
			self.currentEditor = bestEditor
			if bestEditor then
				-- Add the new editor
				self._toolbarActionsChanged = bestEditor.toolbarActionsChanged:addAction(function(editor, items, context)
					self.toolbar:setItems(items, context)
				end)
				self.toolbar:setItems(bestEditor:getToolbarActions(), bestEditor:getContext())

				self.container:addChild(bestEditor.container)
				bestEditor:onEnter()
			end
		end
	end)
end

function Previewer:update(dt)
	if self.container then
		self.container:update(dt)
	end
end

return Previewer
