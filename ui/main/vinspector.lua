local VScroll = require "ui.components.containers.box.vscroll"
local SpriteTool = require "plugins.sprite.tools.spritetool"

---@class VInspector: HScroll
local VInspector = VScroll:extend()
VInspector.CLASS_NAME = "HInspector"

VInspector.minH = 40

function VInspector:new(rules)
	VInspector.super.new(self, rules)
	---@type Inspectable?
	self.selected = nil
	self.padding = 12
	self.margin = 6

	SpriteTool.toolSelected:addAction(function (newTool)
		self:selectInspectable(newTool)
	end)
	if SpriteTool.currentTool then self:selectInspectable(SpriteTool.currentTool) end
end

---@param inspectable Inspectable?
function VInspector:updateProperties(inspectable)
	local oldOffset = self.offset
	self:clearChildren(true)
	self.selected = inspectable
	-- If it's nil, do nothing else
	if inspectable == nil then return end

	local properties = inspectable:getProperties()
	for _, property in ipairs(properties) do
		self:addChild(property:getVElement())
	end

	if self._inUITree then
		self.offset = oldOffset
		self:sort()
	end
end

---Selects a new Inspectable
---@param other Inspectable?
function VInspector:selectInspectable(other)
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

function VInspector:draw()
	love.graphics.setColor(0.23, 0.23, 0.46)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	VInspector.super.draw(self)
end

return VInspector
