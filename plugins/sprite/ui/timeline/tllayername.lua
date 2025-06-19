local Plan = require "lib.plan"
local Action = require "src.data.action"
local Contexts = require "src.global.contexts"
local Modal = require "src.global.modal"
local BaseButton = require "ui.components.button.basebutton"
local LineEdit = require "ui.components.text.lineedit"
local NinePatch = require "src.ninepatch"
local RenameLayerCommand = require "plugins.sprite.commands.renamelayercommand"

local backgroundTexture = love.graphics.newImage("assets/timeline_button.png")
backgroundTexture:setFilter("nearest", "nearest")
local backgroundNP = NinePatch.new(2, 1, 2, 2, 1, 2, backgroundTexture)

local ibeamCursor = love.mouse.getSystemCursor("ibeam")

---@class Timeline.LayerLabel: Timeline.Button
local LayerEdit = BaseButton:extend()

---@type Action[]
local layerActions = {
	-- Filled later
}

local extraActions = {
	Action(
		"Properties",
		function (action, source, presenter, context)
			Contexts.raiseAction("inspect_layer")
		end
	),
}

---@type SpriteEditor.Context
local context

local lineEditRules = Plan.Rules.new()
	:addX(Plan.pixel(2))
	:addY(Plan.pixel(0))
	:addWidth(Plan.max(4))
	:addHeight(Plan.parent())

LayerEdit.scale = 2
---@param self Timeline.LayerLabel
local function selectLayer(self)
	 self:bubble("_bSelectLayer", self.layer)
end

---@param rules Plan.Rules
---@param sprite Sprite
---@param layer Sprite.Layer
function LayerEdit:new(rules, sprite, layer)
	LayerEdit.super.new(self, rules, selectLayer, 2)
	self._passMode = "pass"
	self.sprite = sprite
	self.layer = layer
	---@type LineEdit
	self.lineEdit = LineEdit(lineEditRules, layer.name:get())
	self.lineEdit.maxLength = 32
	-- self.lineEdit.marginX = 2
	self:addChild(self.lineEdit)
	self.editingName = false
	self.selected = false

	layer.name.valueChanged:addAction(function(property, newText)
		self.lineEdit:setText(newText)
	end)

	local newContext = sprite.spriteState.context
	if context == nil then
		local actions = newContext:getActions()
		layerActions[1] = actions.clone_layer
		layerActions[2] = actions.delete_layer
		layerActions[3] = actions.merge_layer_down

		for i = 1, #extraActions do
			layerActions[#layerActions+1] = extraActions[i]
		end
	end
	context = newContext
end

function LayerEdit:refresh()
	LayerEdit.super.refresh(self)
	if not self.editingName then
		self._passMode = "sink"
		self.lineEdit._passMode = "pass"
	else
		self._passMode = "pass"
		self.lineEdit._passMode = "sink"
	end
end

function LayerEdit:mousepressed(x, y, button, isTouch, pressCount)
	if pressCount > 1 and (button == 1 or button == 2) and not self.editingName then
		-- Left clicked twice or more
		self.editingName = true
		-- self.lineEdit:getFocus()
		-- self.lineEdit:mousemoved(x, y)
		love.mouse.setCursor(ibeamCursor)
		self:mousereleased(x, y, button)
		self.lineEdit:mousepressed(x, y, button, isTouch, pressCount)
	else
		LayerEdit.super.mousepressed(self, x, y, button, isTouch, pressCount)
	end
end

function LayerEdit:mousereleased(x, y, button)
	if button == 2 then
		self:onClick()
		Modal.pushMenu(x, y, layerActions, self, context)
	else
		LayerEdit.super.mousereleased(self, x, y, button)
	end
end

function LayerEdit:lineEditUnfocused(_, text)
	self.editingName = false
	self.sprite.undoStack:commit(
		RenameLayerCommand(self.sprite, self.layer, text)
	)
	love.mouse.setCursor()
end

function LayerEdit:draw()
	if self.editingName then
		love.graphics.setColor(0.12, 0.12, 0.15)
	elseif self.pressing then
		love.graphics.setColor(0.1, 0.1, 0.2)
	else
		if self.selected then
			if self.hovering then
				love.graphics.setColor(0.45, 0.45, 0.6)
			else
				love.graphics.setColor(0.3, 0.3, 0.5)
			end
		else
			if self.hovering then
				love.graphics.setColor(0.25, 0.25, 0.5)
			else
				love.graphics.setColor(0.2, 0.2, 0.4)
			end
		end
	end
	backgroundNP:draw(self.x, self.y, self.w, self.h, self.scale)
	LayerEdit.super.draw(self)
end

return LayerEdit
