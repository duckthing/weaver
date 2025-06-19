local NumberProperty = require "src.properties.number"
local SetDurationCommand = require "plugins.sprite.commands.setdurationcommand"
local Resources = require "src.global.resources"

---@class DurationProperty: NumberProperty
local DurationProperty = NumberProperty:extend()

function DurationProperty:getVElement()
	---@type NumberProperty.VElement
	local element = DurationProperty.super.getVElement(self)

	element.lineEdit.textSubmitted:removeAction(element._textSubmittedAction)

	element._textSubmittedAction = element.lineEdit.textSubmitted:addAction(function(text)
		---@type Sprite
		local sprite = Resources.getCurrentResource()

		sprite.undoStack:commit(
			SetDurationCommand(
				sprite,
				self.object,
				tonumber(text)
			)
		)
	end)

	return element
end

return DurationProperty
