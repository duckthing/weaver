local NumberProperty = require "src.properties.number"
local SetDurationCommand = require "plugins.sprite.commands.setdurationcommand"
local Resources = require "src.global.resources"

---@class DurationProperty: NumberProperty
local DurationProperty = NumberProperty:extend()

function DurationProperty:getVElement()
	---@type NumberProperty.VTextElement
	local element = DurationProperty.super.getVElement(self)

	element.lineEdit.textSubmitted:removeAction(element._textSubmittedAction)

	element._textSubmittedAction = element.lineEdit.textSubmitted:addAction(function(text)
		local sprite = Resources.getCurrentResource()
		---@cast sprite Sprite

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
