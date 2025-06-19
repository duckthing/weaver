local Plan = require "lib.plan"
local HScroll = require "ui.components.containers.box.hscroll"
local SpriteTool = require "plugins.sprite.tools.spritetool"

---@class Inspector: HScroll
local Inspector = HScroll:extend()

Inspector.minH = 40

function Inspector:new(rules)
	Inspector.super.new(self, rules)
	---@type Inspectable?
	self.selected = nil
	self.padding = 12
	self.margin = 12

	SpriteTool.toolSelected:addAction(function (newTool)
		self:selectInspectable(newTool)
	end)
	if SpriteTool.currentTool then self:selectInspectable(SpriteTool.currentTool) end
end

function Inspector:updateProperties(inspectable)
	self:clearChildren(true)
	self.selected = inspectable
	-- If it's nil, do nothing else
	if inspectable == nil then return end

	local properties = inspectable:getProperties()
	for _, property in ipairs(properties) do
		self:addChild(property:getHElement())
	end

	if self._inUITree then
		self:sort()
	end
end

---Selects a new Inspectable
---@param other Inspectable?
function Inspector:selectInspectable(other)
	local currSelection = self.selected
	-- If it's the same, do nothing
	if currSelection == other then return end

	-- Remove properties changed event
	if currSelection ~= nil and self._inspectablesChanged then
		currSelection.inspectablesChanged:removeAction(self._inspectablesChanged)
		self._inspectablesChanged = nil
	end

	-- Add the new one
	if other ~= nil then
		if other.inspectablesChanged then
			self._inspectablesChanged = other.inspectablesChanged:addAction(function()
				self:updateProperties(self.selected)
			end)
		end
	end

	self:updateProperties(other)
end

function Inspector:draw()
	love.graphics.setColor(0.23, 0.23, 0.46)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	Inspector.super.draw(self)
end

return Inspector
