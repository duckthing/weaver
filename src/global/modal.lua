local Modal = {}

local Plan = require "lib.plan"
local InspectorPopup = require "ui.components.containers.modals.inspectorpopup"
local PopupMenu = require "ui.components.containers.modals.popupmenu"
local Dropdown = require "ui.components.containers.modals.dropdown"
local FileBrowser = require "ui.components.containers.modals.filebrowser"
local ColorSelect = require "ui.components.containers.modals.colorselect"

local popupOnClose = function(menu)
	menu.parent:removeChild(menu)
end

local DEFAULT_WIDTH, DEFAULT_HEIGHT =
	270, 300

---Creates and pushes a PopupWindow
---@param window PopupWindow # As a class, not an instanced object
---@param w integer?
---@param h integer?
local function pushNewWindow(window, w, h)
	---@type PopupWindow
	local popup = window(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(w or DEFAULT_WIDTH))
			:addHeight(Plan.pixel(h or DEFAULT_HEIGHT))
	)
	Modal.uiRoot:addChild(popup)
	popup:popupCentered()
	popup.onClose = popupOnClose
end

---Pushes an existing PopupWindow
---@param window PopupWindow # As an instanced object
---@param w integer?
---@param h integer?
local function pushExistingWindow(window, w, h)
	window.rules =
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(w or DEFAULT_WIDTH))
			:addHeight(Plan.pixel(h or DEFAULT_HEIGHT))
	Modal.uiRoot:addChild(window)
	window:popupCentered()
	window.onClose = popupOnClose
end

---Pushes a Inspector as a modal
---@param inspectable Inspectable
---@param w integer?
---@param h integer?
local function pushInspector(inspectable, w, h)
	---@type InspectorPopup
	local popup = InspectorPopup(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(w or DEFAULT_WIDTH))
			:addHeight(Plan.pixel(h or DEFAULT_HEIGHT)),
		inspectable
	)
	Modal.uiRoot:addChild(popup)
	popup:popupCentered()
	popup.onClose = popupOnClose
end

---Pushes a context menu (like when you right click)
---@param x integer
---@param y integer
---@param items Action[]
---@param source any
---@param context Action.Context?
local function pushMenu(x, y, items, source, context)
	---@type InspectorPopup
	local popup = PopupMenu(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.content()),
		items,
		source,
		context
	)
	local uiRoot = Modal.uiRoot
	local rootBounds = uiRoot.context.rootBounds
	local sw, sh = rootBounds.w, rootBounds.h
	local dw, dh = popup:getDesiredDimensions()

	x = math.max(0, math.min(x or 0, sw - dw))
	y = math.max(0, math.min(y or 0, sh - dh))
	popup.x, popup.y = x, y
	popup:refresh()

	uiRoot:addChild(popup)
	popup:popup()
	popup.onClose = popupOnClose
end

---Pushes a dropdown for an EnumProperty
---@param x integer
---@param y integer
---@param property EnumProperty
---@param minW integer?
local function pushDropdown(x, y, property, minW)
	---@type Dropdown
	local dropdown = Dropdown(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.content()),
		property,
		minW
	)
	local uiRoot = Modal.uiRoot
	local rootBounds = uiRoot.context.rootBounds
	local sw, sh = rootBounds.w, rootBounds.h
	local dw, dh = dropdown:getDesiredDimensions()

	x = math.max(0, math.min(x, sw - dw))
	y = math.max(0, math.min(y, sh - dh))
	dropdown.x, dropdown.y = x, y
	dropdown:refresh()

	uiRoot:addChild(dropdown)
	dropdown:popup()
	dropdown.onClose = popupOnClose
end

---@param pathProperty FilePathProperty
---@param w integer?
---@param h integer?
---@return FileBrowser
local function pushFileBrowser(pathProperty, w, h)
	---@type FileBrowser
	local fb = FileBrowser(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(w or 450))
			:addHeight(Plan.pixel(h or 360))
	)
	fb:bindToProperty(pathProperty)
	local uiRoot = Modal.uiRoot
	uiRoot:addChild(fb)
	fb:popupCentered()
	fb.onClose = function(browser)
		browser.parent:removeChild(browser)
		fb:bindToProperty(nil)
	end

	return fb
end

Modal.DEFAULT_COLOR_WIDTH = 200
Modal.DEFAULT_COLOR_HEIGHT = 310

---@param colorProperty ColorSelectionProperty
---@param x integer?
---@param y integer?
---@param w integer?
---@param h integer?
---@return ColorSelect
local function pushColorSelect(colorProperty, x, y, w, h)
	---@type ColorSelect
	local cs = ColorSelect(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(w or Modal.DEFAULT_COLOR_WIDTH))
			:addHeight(Plan.pixel(h or Modal.DEFAULT_COLOR_HEIGHT))
	)
	cs:bindToProperty(colorProperty)
	local uiRoot = Modal.uiRoot
	uiRoot:addChild(cs)
	if x == nil and y == nil then
		cs:popupCentered()
	else
		---@diagnostic disable-next-line
		cs.x, cs.y = x or 0, y or 0
		cs:popup()
	end
	cs.onClose = function(browser)
		browser.parent:removeChild(browser)
		cs:bindToProperty(nil)
	end

	return cs
end

---@type Plan.Root
Modal.uiRoot = nil
Modal.pushNewWindow = pushNewWindow
Modal.pushExistingWindow = pushExistingWindow
Modal.pushInspector = pushInspector
Modal.pushMenu = pushMenu
Modal.pushDropdown = pushDropdown
Modal.pushFileBrowser = pushFileBrowser
Modal.pushColorSelect = pushColorSelect

return Modal
