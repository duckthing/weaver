local StringProperty = require "src.properties.string"
local RenameLayerCommand = require "plugins.sprite.commands.renamelayercommand"
local Resources = require "src.global.resources"

---@class LayerNameProperty: StringProperty
local LayerNameProperty = StringProperty:extend()

function LayerNameProperty:getVElement()
	---@type StringProperty.VElement
	local element = LayerNameProperty.super.getVElement(self)

	element.lineEdit.textSubmitted:removeAction(element._textSubmittedAction)

	element._textSubmittedAction = element.lineEdit.textSubmitted:addAction(function(text)
		---@type Sprite
		local sprite = Resources.getCurrentResource()

		sprite.undoStack:commit(
			RenameLayerCommand(
				sprite,
				self.object,
				text
			)
		)
	end)

	return element
end

return LayerNameProperty
