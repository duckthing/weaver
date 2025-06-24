local Plan = require "lib.plan"
local PopupWindow = require "ui.components.containers.modals.popupwindow"
local VScroll = require "ui.components.containers.box.vscroll"

---@class InspectorPopup: PopupWindow
local InspectorPopup = PopupWindow:extend()
InspectorPopup.CLASS_NAME = "InspectorPopup"

function InspectorPopup:new(rules, inspectable)
	InspectorPopup.super.new(self, rules, nil, "Inspector")

	---@type Inspectable?
	self.selected = nil
	---@type VScroll
	local vscroll = VScroll(Plan.RuleFactory.full())
	self.vscroll = vscroll
	self:addChild(vscroll)

	---@type string?
	self._inspectablesChangedAction = nil
	self:setInspectable(inspectable)
end

function InspectorPopup:updateInspector()
	local inspectable = self.selected
	local oldOffset = self.vscroll.offset
	self.vscroll:clearChildren(true)
	if not inspectable then return end

	local properties = inspectable:getProperties()
	for _, property in ipairs(properties) do
		self.vscroll:addChild(property:getVElement())
	end

	---@type Action[]
	local actions = self:mergeActions({
		PopupWindow.DEFAULT_ACTIONS,
		inspectable:getActions()
	})

	self:setActions(actions, inspectable, inspectable:getActionContext())
	self.vscroll.offset = oldOffset
	self:refresh()
end

---Sets the currently inspected object
---@param newInspectable Inspectable?
function InspectorPopup:setInspectable(newInspectable)
	self.vscroll.offset = 0
	local oldInspectable = self.selected
	if oldInspectable == newInspectable then return end

	-- Disconnect from old events
	if oldInspectable ~= nil then
		oldInspectable.inspectablesChanged:removeAction(self._inspectablesChangedAction)
		self._inspectablesChangedAction = nil
	end

	self.selected = newInspectable
	self:updateInspector()

	if newInspectable then
		-- Connect to new events
		self._inspectablesChangedAction = newInspectable.inspectablesChanged:addAction(function()
			self:updateInspector()
		end)
	end
end

return InspectorPopup
