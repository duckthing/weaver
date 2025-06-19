local Plan = require "lib.plan"
local Resources = require "src.global.resources"

---@class KeyEditor.Window: Plan.Container
local KeyWindow = Plan.Container:extend()

---@param rules Plan.Rules
---@param editor SettingsEditor
---@param context SpriteEditor.Context
function KeyWindow:new(rules, editor, context)
	KeyWindow.super.new(self, rules)
	---@param newResource Resource
	Resources.onNewResource:addAction(function (newResource)
		if newResource.type == "key" then
		end
	end)

	---@param selectedResource Resource
	Resources.onResourceSelected:addAction(function (selectedResource)
		if selectedResource and selectedResource.TYPE == "key" then
		end
	end)

	---@param deselectedResource Resource
	Resources.onResourceDeselected:addAction(function (deselectedResource)
		if deselectedResource.TYPE == "key" then
		end
	end)
end

function KeyWindow:draw()
	love.graphics.setColor(0.08, 0.08, 0.18)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	KeyWindow.super.draw(self)
end

function KeyWindow:update(dt)
	-- Disable updating
end

return KeyWindow
