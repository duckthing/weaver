local Label = require "ui.components.text.label"
local Resources = require "src.global.resources"

---@class SpriteStatus.SpriteName: Label
local SpriteName = Label:extend()

function SpriteName:new(rules)
	SpriteName.super.new(self, rules, "")
	---@type SpriteEditor
	self.editor = nil
	---@type SpriteCanvas?
	self.canvas = nil
end

function SpriteName:update()
	local canvas = self.canvas
	if canvas then
		self:enable()
	else
		self:disable()
	end
end

---Sets the SpriteEditor
---@param spriteEditor SpriteEditor
function SpriteName:setEditor(spriteEditor)
	self.editor = spriteEditor
	self.canvas = spriteEditor.container.canvasUI

	if self._resourceSelectedAction == nil then
		---@param newResource Resource
		self._resourceSelectedAction = Resources.onResourceSelected:addAction(function(newResource)
			if self.resource == newResource then return end

			if self.resource and self._nameChangedAction then
				-- Disconnect events
				self.resource.name.valueChanged:removeAction(self._nameChangedAction)
				self._nameChangedAction = nil
			end

			self.resource = newResource

			if newResource and newResource.TYPE == "sprite" then
				---@cast newResource Sprite
				self:setText(newResource.name:get())

				self._nameChangedAction = newResource.name.valueChanged:addAction(function(property, newName)
					self:setText(newName)
				end)
			end
		end)
	end
end

return SpriteName
