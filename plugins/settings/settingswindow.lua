local Plan = require "lib.plan"
local Resources = require "src.global.resources"
local VScroll = require "ui.components.containers.box.vscroll"
local Plugin = require "src.data.plugin"
local Label = require "ui.components.text.label"
local Fonts = require "src.global.fonts"

---@class SettingsEditor.Window: Plan.Container
local SettingsWindow = Plan.Container:extend()

local headerFont = Fonts.getDefaultFont(24)

---@param rules Plan.Rules
---@param plugin SettingsEditor
---@param context SpriteEditor.Context
function SettingsWindow:new(rules, plugin, context)
	SettingsWindow.super.new(self, rules)
	Resources.onNewResource:addAction(function (newBuffer)
		if newBuffer.type == "settings" then
		end
	end)

	---@param selectedResource Resource
	Resources.onResourceSelected:addAction(function (selectedResource)
		if selectedResource and selectedResource.TYPE == "settings" then
		end
	end)

	---@param deselectedResource Resource
	Resources.onResourceDeselected:addAction(function (deselectedResource)
		if deselectedResource.TYPE == "settings" then
		end
	end)

	---@type VScroll
	local vscroll = VScroll(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.pixel(0))
			:addWidth(Plan.pixel(500))
			:addHeight(Plan.parent())
	)
	vscroll.padding = 20
	vscroll.margin = 8
	self.vscroll = vscroll

	for _, plugin in ipairs(Plugin.plugins) do
		self:addEditorSettings(plugin)
	end

	self:addChild(vscroll)
end

---@param plugin Plugin
function SettingsWindow:addEditorSettings(plugin)
	local settings = plugin:getSettings()
	if #settings == 0 then return end
	local vscroll = self.vscroll
	---@type Label
	local label = Label(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.content(Plan.pixel(0)))
			:addHeight(Plan.content(Plan.pixel(0)))
	)
	label:setFont(headerFont)
	label:setText("\n"..plugin.TYPE)
	vscroll:addChild(label)

	for _, property in ipairs(settings) do
		vscroll:addChild(property:getVElement())
	end
end

function SettingsWindow:draw()
	love.graphics.setColor(0.08, 0.08, 0.18)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	SettingsWindow.super.draw(self)
end

function SettingsWindow:update(dt)
	-- Disable updating
end

return SettingsWindow
