local Plan = {
	_VERSION = '0.6.0',
	_DESCRIPTION = 'Plan, a layout helper, designed for LÖVE',
	_URL = 'https://github.com/zombrodo/plan',
	_LICENSE = [[
		MIT License
		Copyright (c) 2021 Jack Robinson
		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:
		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]]
}
Plan.__index = Plan

local Shash = require "lib.shash"

-- ============================================================================
-- Utils
-- ============================================================================

---Returns true if the value exists
---@param x any?
---@return boolean
local function some(x)
	return x ~= nil
end

---Returns the index of a value in an array
---@param coll table
---@param item any
---@return integer
local function indexOf(coll, item)
	for i, x in ipairs(coll) do
		if x == item then
			return i
		end
	end
	return -1
end

---Returns true if the table contains the item
---@param coll table
---@param item any
---@return boolean
local function contains(coll, item)
	return indexOf(coll, item) ~= -1
end

---Gets the UI Root from the UI object
---@param container Plan.Container
---@return Plan.Container?
local function getRoot(container)
	local parent = container.parent
	if parent then
		---@diagnostic disable-next-line: need-check-nil
		while parent.parent ~= nil do
			parent = parent.parent
		end
	end
	return parent
end

---Returns true if this value is a number
---@param maybeNumber any
---@return boolean
local function isNumber(maybeNumber)
	return type(maybeNumber) == "number"
end

---@return boolean
local function isValidRule(maybeRule)
	return maybeRule.realise ~= nil and type(maybeRule.realise) == "function"
end

-- ============================================================================
-- Root Object (not public)
-- ============================================================================

local Object = require "lib.classic"

--[[
--@class Plan.Object
local Object = {}
Object.__index = Object

---Creates a new Plan.Object
function Object:new()
end

---Extends the Plan.Object
---@return Plan.Object
function Object:extend()
	local subclass = {}
	for k, v in pairs(self) do
		if k:find("__") == 1 then
			subclass[k] = v
		end
	end
	subclass.__index = subclass
	subclass.super = self
	setmetatable(subclass, self)
	return subclass
end
]]

-- ============================================================================
-- Context
-- ============================================================================

---@type Plan.Root
local root
---@type Plan.RootContext
local rootContext

---@class BoundsContext: Object
local BoundsContext = Object:extend()

---@param self BoundsContext
---@param px integer
---@param py integer
local function boundsContextSimpleOverlap(self, px, py)
	-- Move the pointer position
	local tx, ty = px - self.x, py - self.y
	return tx > 0 and tx <= self.w and ty > 0 and ty <= self.h
end

---Creates a new BoundsContext that
---@param ui Plan.Container
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param overlapCheck? fun(self: self): boolean
function BoundsContext:new(ui, x, y, w, h, overlapCheck)
	BoundsContext.super.new(self)
	self.ui = ui
	---@type BoundsContext?
	self.parentBounds = nil
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.shash = Shash.new()
	---@type BoundsContext?
	self.parent = nil
	self.overlapCheck = overlapCheck or boundsContextSimpleOverlap
end

---Returns whether the point is within bounds
---@param px integer
---@param py integer
---@return boolean
function BoundsContext:isWithinBounds(px, py)
	local parent = self.parent
	if parent then
		return self:overlapCheck(px, py) and parent:overlapCheck(px, py)
	else
		return self:overlapCheck(px, py)
	end
end

---Adds a BoundsContext
---@param newBounds BoundsContext
function BoundsContext:addChildBounds(newBounds)
	newBounds.parent = self
	table.insert(rootContext.bounds, newBounds)
end

---Removes a BoundsContext
---@param bounds any
function BoundsContext:removeBounds(bounds)
	local index = indexOf(rootContext.bounds, bounds)
	if index ~= -1 then
		table.remove(rootContext.bounds, index)
		bounds.parent = nil
	end
end

---@class Plan.RootContext
local RootContext = Object:extend()

---@param rootUI Plan.Container
function RootContext:new(rootUI)
	---@type BoundsContext
	local rootBounds = BoundsContext(rootUI, 0, 0, 0, 0)
	self.rootBounds = rootBounds

	---@type BoundsContext[]
	self.bounds = {
		rootBounds,
	}

	---@type Plan.Container[]
	self.modals = {}

	---@type Plan.Container?
	self.hoveredUI = nil
	---@type Plan.Container?
	self.focusedUI = nil
	-- Pointer for cursor entering/exiting bounds
	---@type integer, integer
	self.px, self.py = -1, -1
end

---Calls a function on the deepest UI element within bounds.
---
---If focused, the event will get to the target instead, regardless of bounds.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param eventName string
---@param ... unknown
function RootContext:emitInArea(x, y, w, h, eventName, ...)
	do
		-- Send to focused UI if it exists
		local ui = self.focusedUI
		if ui then
			if ui[eventName] then
				local shouldContinue = ui[eventName](ui, ...)
				if shouldContinue ~= true then
					-- Return if the function doesn't return true
					-- This means that we shouldn't send this event to something else
					return
				end
			end
		end
		-- If the focused UI doesn't have it, continue.
	end

	-- Get the deepest UI element with 'eventName'
	---@type Plan.Container?
	local activeModal = self.modals[#self.modals]
	local deepestDepth, deepestUI = 1, nil
	for _, bounds in ipairs(self.bounds) do
		-- TODO: Make bounds check within an area, not a point
		bounds.shash:each(x, y, w, h, function(ui)
			---@cast ui Plan.Container
			if ui._depth >= deepestDepth and ui[eventName] and ui._passMode == "sink" and ui:withinParentBounds(x, y) and ui:underActiveModal() then
				deepestDepth = ui._depth
				deepestUI = ui
			end
		end, deepestDepth, deepestUI)
	end

	if deepestUI then
		deepestUI[eventName](deepestUI, ...)
	elseif activeModal and not activeModal:isOverlapping(x, y) and activeModal.outofbounds then
		activeModal:outofbounds(eventName, ...)
	end
end

---Calls a function on the deepest UI element at a point.
---
---If focused, the event will get to the target instead, regardless of bounds.
---@param x integer
---@param y integer
---@param eventName string
---@param ... unknown
function RootContext:emitAtPoint(x, y, eventName, ...)
	self:emitInArea(x, y, 0, 0, eventName, ...)
end

---Emits "pointerentered" and "pointerexited"
---@param x integer
---@param y integer
function RootContext:movePointer(x, y)
	self.px, self.py = x, y
	local lastHovered = self.hoveredUI

	-- Get the deepest UI element with 'eventName'
	---@type Plan.Container?
	local activeModal = self.modals[#self.modals]
	local deepestDepth, deepestUI = 1, nil
	for _, bounds in pairs(self.bounds) do
		if bounds:isWithinBounds(x, y) then
			bounds.shash:each(x, y, 0, 0, function(ui)
				---@cast ui Plan.Container
				if ui._depth >= deepestDepth and ui.pointerentered and ui._passMode == "sink" and ui:withinParentBounds(x, y) and ui:underActiveModal() then
					deepestDepth = ui._depth
					deepestUI = ui
				end
			end, deepestDepth, deepestUI)
		end
	end

	-- No changes
	if deepestUI == lastHovered then
		return
	end

	-- No longer hovering the last hovered thing
	if deepestUI ~= lastHovered then
		---@diagnostic disable-next-line
		if lastHovered and lastHovered.pointerexited then
			---@diagnostic disable-next-line
			lastHovered:pointerexited()
		end
		self.hoveredUI = deepestUI
	end

	-- Hovering over something else
	if deepestUI ~= nil then
		if deepestUI.pointerentered then
			deepestUI:pointerentered()
		end
		self.hoveredUI = deepestUI
	end
end

-- ============================================================================
-- Container
-- ============================================================================

---@alias Plan.ClipMode
---| "free" # Doesn't clip children, but will check ancestors for clipping anyways
---| "clip" # Will clip children, and check ancestors for clipping
---| "independent" # Doesn't check if an ancestor clips. Useful for modals.

---@alias Plan.PassMode
---| "sink" # Will receive events if overlapping a checked area
---| "pass" # Will ignore events, and let other elements receive them

---@class (exact) Plan.Container: Object
---@field super Plan.Container
---@field CLASS_NAME string
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field rules Plan.Rules
---@field parent Plan.Container?
---@field children Plan.Container[]
---@field _active boolean
---@field _depth integer
---@field _bounds BoundsContext
---@field _inUITree boolean
---@field _valid boolean Not destroyed; can be used or recycled
---@field _clipMode Plan.ClipMode
---@field _passMode Plan.PassMode
---@field isUIRoot boolean
---@field sizeRatio number
---@field extend fun(self: self): Plan.Container
---@field refresh fun(self: self): nil
---@field withinBounds fun(self: self, x: integer, y: integer): boolean
---@field mousemoved (fun(self: self, mx: integer, my: integer, cx: integer, cy: integer): nil)?
---@field mousepressed (fun(self: self, x: integer, y: integer, button: integer, isTouch: boolean, pressCount: integer): nil)?
---@field mousereleased (fun(self: self, x: integer, y: integer, button: integer): nil)?
---@field wheelmoved (fun(self: self, x: integer, y: integer): nil)?
---@field keypressed (fun(self: self, key: love.KeyConstant, scanCode: love.Scancode, isRepeat: boolean): nil)?
---@field textinput (fun(self: self, text: string): nil)?
---@field pointerentered (fun(self: self, mouseX: integer, mouseY: integer): nil)?
---@field pointerexited (fun(self: self, mouseX: integer, mouseY: integer): nil)?
---@field outofbounds (fun(self: self, eventName: string, ...))?
---@field modaldraw (fun(self: self))?
local Container = Object:extend()
Container.CLASS_NAME = "Container"
Container.sizeRatio = 0

---Creates a new Plan.Container
---@param rules Plan.Rules
---@param ... unknown
function Container:new(rules, ...)
	---@class Plan.Container
	Container.super.new(self, rules)
	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0
	self._depth = 0
	self._clipMode = "free"
	self._passMode = "sink"
	---@type BoundsContext?
	self._bounds = nil

	--- If the element can be shown (but may not be right now),
	--- this will be true.
	self._active = true
	--- If the element is valid.
	--- Basically, it can be used or reused.
	self._valid = true
	--- If the element is clickable, this will be true
	self._inUITree = false
	self.rules = rules
	self.parent = nil
	---@type Plan.Container[]
	self.children = {}
	self.isUIRoot = false
end

---Returns true if this Plan.Container has an ancestor Plan.Root
---@return unknown
function Container:_isAttached()
	-- local root = getRoot(self)
	-- return root and root.isUIRoot
	return self._inUITree
end

---Returns the Plan.Root this container belongs to
---@return Plan.Root
function Container:getRoot()
	--TODO: Avoid globals. This doesn't take into account multiple roots either.
	return root
end

---Returns the desired width and height, but not the current one
---@return integer? dw
---@return integer? dh
function Container:getDesiredDimensions()
	return nil, nil
end

---Adds the child to this Plan.Container
---@param child Plan.Container
---@param atIndex integer?
function Container:addChild(child, atIndex)
	assert(child ~= self, "Can't add self as child to self")
	assert(child._valid == true, "Child has been destroyed; not valid")

	child.parent = self
	child._depth = self._depth + 1
	child._bounds = self._bounds
	atIndex = (atIndex and math.max(1, math.min(atIndex, #self.children + 1))) or #self.children + 1
	table.insert(self.children, atIndex, child)
	child:onAddedToParent()
	if self.isUIRoot or self:_isAttached() then
		self:refresh()
	end
end

---Removes the child from this Plan.Container
---@param child Plan.Container
---@param destroy boolean? Calls the destructor on the Container
function Container:removeChild(child, destroy)
	local toRemove = indexOf(self.children, child)
	if some(toRemove) then
		child:onRemovedFromParent()
		table.remove(self.children, toRemove)
	end
end

---Removes all children from this Plan.Container
---@param destroyAll boolean? Destroys all Containers
function Container:clearChildren(destroyAll)
	if destroyAll then
		for i = #self.children, 1, -1 do
			self.children[i]:onRemovedFromParent()
			self.children[i]:destroy(true)
			self.children[i] = nil
		end
	else
		for i = #self.children, 1, -1 do
			self.children[i]:onRemovedFromParent()
			self.children[i] = nil
		end
	end
end

---The destructor for this container. It should disconnect from all events.
---@param recursive boolean? Destroy everything
function Container:destroy(recursive)
	self._valid = false
	if self.parent then
		self.parent:removeChild(self)
	end
	self:_treeRemove()
	self:clearChildren(recursive)
end

---Adds this Container to the tree.
---Does not check if this element is active, use refresh instead.
function Container:_treeUpdate()
	if self._inUITree then
		self._bounds.shash:update(self, self.x, self.y, self.w, self.h)
	else
		self._bounds.shash:add(self, self.x, self.y, self.w, self.h)
		self._inUITree = true
	end
end

function Container:_treeRemove()
	if self._inUITree then
		self._inUITree = false
		self._bounds.shash:remove(self)
	end
end

function Container:onAddedToParent()
	-- Refresh is performed by the parent already
end

function Container:onRemovedFromParent()
	self.parent = nil
	self:_treeRemove()
	self:emit("_treeRemove")
end

---Handles what happens when a child element's size changes outside of refresh
---@param source Plan.Container
---@return boolean?
function Container:_bubbleSizeChanged(source)
	-- By default, stop bubbling
	return false
end

---Handles what happens when a child element's is enabled/disabled
---@param source Plan.Container
---@return boolean?
function Container:_bubbleStatusChanged(source)
	-- By default, stop bubbling
	if source:isActive() then
		source:refresh()
	end
	return false
end

function Container:enable()
	if not self._active then
		self._active = true
		self:bubble("_bubbleStatusChanged")
	end
end

function Container:disable()
	if self._active then
		self._active = false
		self:_treeRemove()
		self:emit("_treeRemove")
		self:bubble("_bubbleStatusChanged")
	end
end

function Container:getFocus()
	rootContext.focusedUI = self
end

function Container:releaseFocus()
	rootContext.focusedUI = nil
end

function Container:_pushModal()
	rootContext.modals[#rootContext.modals+1] = self
end

function Container:_popModal()
	for i = #rootContext.modals, 1, -1 do
		local v = rootContext.modals[i]
		if v == self then
			table.remove(rootContext.modals, i)
			return
		end
	end
	print("Could not find self as a modal")
	-- local poppedModal = rootContext.modals[#rootContext.modals]
	-- if poppedModal ~= self then error("Attempt to pop self off of modal stack while not at the top") end
	-- rootContext.modals[#rootContext.modals] = nil
end

---Returns true if this Container is active and should be included in the tree.
---
---It might not be in the tree yet.
---@return boolean active
function Container:isActive()
	return self._active
end

---Checks if a point is overlapping with the element
---@param px integer
---@param py integer
---@return boolean
function Container:isOverlapping(px, py)
	local rx, ry = px - self.x, py - self.y
	return rx >= 0 and rx <= self.w and ry >= 0 and ry <= self.h
end

---Returns true whether the point is within the element and within the
---clipped area by the parents.
---@param px integer
---@param py integer
---@return boolean isValid
function Container:withinParentBounds(px, py)
	if self._clipMode == "clip" then
		if not self:isOverlapping(px, py) then
			return false
		end
	elseif self._clipMode == "independent" then
		return true
	end

	local parent = self.parent
	if parent then
		return self.parent:withinParentBounds(px, py)
	end
	return true
end

---Returns true if the ancestor is found
---@param ancestor Plan.Container
---@return boolean hasAncestor
function Container:hasAncestor(ancestor)
	local parent = self.parent
	if parent == nil then return false end
	return parent == ancestor or parent:hasAncestor(ancestor)
end

---Returns true if this Container is under the active modal.
---This also returns true if there is no active modal.
---@return boolean isActive
function Container:underActiveModal()
	local activeModal = rootContext.modals[#rootContext.modals]
	if activeModal == nil then return true end
	return self == activeModal or self:hasAncestor(activeModal)
end

---Recalculates the position and sizing for itself and all children.
---
---Do NOT enable/disable elements here.
function Container:refresh()
	if not self._active then return end
	local x, y, w, h = self.rules:realise(self)
	local dimensionsChanged = self.w ~= w or self.h ~= h
	self.x, self.y, self.w, self.h = x, y, w, h
	self:_treeUpdate()
	local lowerDepth = self._depth + 1
	for _, child in ipairs(self.children) do
		child._depth = lowerDepth
		child._bounds = self._bounds
		if some(child.refresh) then
			child:refresh()
		end
	end

	if dimensionsChanged then
		return self:bubble("_bubbleSizeChanged")
	end
end

---Recursively updates this container and all children
---@param dt number
function Container:update(dt)
	for _, child in ipairs(self.children) do
		if child.update then
			child:update(dt)
		end
	end
end

---Draws the container
function Container:draw()
	for _, child in ipairs(self.children) do
		if child._active and some(child.draw) then
			child:draw()
		end
	end
end

---Emits an event downwards
---@param event string
---@param ... unknown
function Container:emit(event, ...)
	for _, child in ipairs(self.children) do
		if some(child[event]) and type(child[event]) == "function" then
			local result = child[event](child, ...)
			-- If we return false, then we stop passing this around.
			if result == false then
				return
			end
		end

		-- Pass this event down to the child elements
		child:emit(event, ...)
	end
end

---Same as emit, but calls it on the target container as well
---@param event string
---@param ... unknown
function Container:callAndEmit(event, ...)
	if self[event] then
		self[event](self, ...)
	end
	self:emit(event, ...)
end

---[INTERNALLY] emits an event upwards with the source container. Done automatically.
---@param event string
---@param sourceElement Plan.Container
---@param ... unknown
---@return boolean | nil
function Container:_bubble(event, sourceElement, ...)
	local parent = self.parent
	if parent then
		if some(parent[event]) and type(parent[event]) == "function" then
			local result = parent[event](parent, sourceElement, ...)
			-- If we return false, then we stop passing this around.
			if result == false then
				return
			end
		end
		-- Call upwards
		parent:_bubble(event, sourceElement, ...)
	end
end

---Emits an event upwards
---@param event string
---@param ... unknown
function Container:bubble(event, ...)
	self:_bubble(event, self, ...)
end

function Container:__tostring()
	return self.CLASS_NAME
end

Plan.Container = Container

-- ============================================================================
-- Default Rules
-- ============================================================================

-- ====================================
-- Pixel Rule
-- ====================================

---@class Plan.Rule
---@field new fun(...): self # Creates a new Plan.Rule
---@field realise fun(self: self, dimension: string, element: Plan.Container, rules: Plan.Rules, desiredW: integer?, desiredH: integer?): number # Recalculates the Plan.Rule
---@field set fun(self: self, value: any) # Sets a value inside of the Plan.Rule
---@field clone fun(self: self): Plan.Rule

---@class Plan.Rule.PixelRule: Plan.Rule
local PixelRule = {}
PixelRule.__index = PixelRule
PixelRule.__tostring = function(self)
	return ("Pixel(%d)"):format(self.value)
end

function PixelRule.new(value)
	local self = setmetatable({value = value or 0}, PixelRule)
	return self
end

function PixelRule:realise(dimension, element, rules)
	return self.value
end

function PixelRule:clone()
	return PixelRule.new(self.value)
end

function PixelRule:set(value)
	self.value = value
end

function Plan.pixel(value)
	return PixelRule.new(value)
end

-- ====================================
-- Relative Rule
-- ====================================

---@class Plan.Rule.RelativeRule: Plan.Rule
local RelativeRule = {}
RelativeRule.__index = RelativeRule
RelativeRule.__tostring = function(self)
	return ("Relative(%d)"):format(self.value)
end

---@param value number Percent of parent
function RelativeRule.new(value)
	local self = setmetatable({}, RelativeRule)
	self.value = value
	return self
end

function RelativeRule:realise(dimension, element, rules)
	if dimension == "w" or dimension == "h" then
		return element.parent[dimension] * self.value
	end

	if dimension == "x" then
		return element.parent["w"] * self.value
	end

	if dimension == "y" then
		return element.parent["h"] * self.value
	end
end

function RelativeRule:clone()
	return RelativeRule.new(self.value)
end

function RelativeRule:set(value)
	self.value = value
end

function Plan.relative(value)
	return RelativeRule.new(value)
end

-- ====================================
-- Center Rule
-- ====================================

---@class Plan.Rule.CenterRule: Plan.Rule
local CenterRule = {}
CenterRule.__index = CenterRule
CenterRule.__tostring = function(self)
	return "Center"
end

function CenterRule.new()
	local self = setmetatable({}, CenterRule)
	return self
end

function CenterRule:realise(dimension, element, rules, desiredW, desiredH)
	if dimension == "w" or dimension == "h" then
		error("Center Rule doesn't work for widths or heights")
	end

	-- We know for sure that the parent has realised its position
	-- But we assume that this element hasn't worked it out yet, so we do it ahead of time.
	-- There is no checks against circular references.

	if dimension == "x" then
		return (element.parent.w / 2) - (rules.w:realise("w", element, rules, desiredW, desiredH) / 2)
	end

	if dimension == "y" then
		return (element.parent.h / 2) - (rules.h:realise("h", element, rules, desiredW, desiredH) / 2)
	end
end

function CenterRule:clone()
	return CenterRule.new()
end

function CenterRule:set()
	-- no op
end

function Plan.center()
	return CenterRule.new()
end

-- ====================================
-- Aspect Rule
-- ====================================

---@class Plan.Rule.AspectRule: Plan.Rule
local AspectRule = {}
AspectRule.__index = AspectRule
AspectRule.__tostring = function(self)
	return ("Aspect(%f)"):format(self.value)
end

function AspectRule.new(value)
	local self = setmetatable({}, AspectRule)
	self.value = value
	return self
end

function AspectRule:realise(dimension, element, rules, desiredW, desiredH)
	if dimension == "x" or dimension == "y" then
		error("Aspect rule doesn't work for x or y coordinates")
	end

	if dimension == "w" then
		return rules.h:realise("h", element, rules, desiredW, desiredH) * self.value
	end

	if dimension == "h" then
		return rules.w:realise("w", element, rules, desiredW, desiredH) * self.value
	end
end

function AspectRule:clone()
	return AspectRule.new(self.value)
end

function AspectRule:set(value)
	self.value = value
end

function Plan.aspect(value)
	return AspectRule.new(value)
end

-- ====================================
-- Parent Rule
-- ====================================

---@class Plan.Rule.ParentRule: Plan.Rule
local ParentRule = {}
ParentRule.__index = ParentRule
ParentRule.__tostring = function(self)
	return "Parent"
end

function ParentRule.new()
	local self = setmetatable({}, ParentRule)
	return self
end

function ParentRule:realise(dimension, element, rules)
	return element.parent[dimension]
end

function ParentRule:clone()
	return ParentRule.new()
end

function ParentRule:set()
	-- no op
end

function Plan.parent()
	return ParentRule.new()
end

-- ====================================
-- Max Rule
-- ====================================

---@class Plan.Rule.MaxRule: Plan.Rule
local MaxRule = {}
MaxRule.__index = MaxRule
MaxRule.__tostring = function(self)
	return ("Max(%d)"):format(self.value)
end

function MaxRule.new(value)
	local self = setmetatable({}, MaxRule)
	self.value = value or 0
	return self
end

function MaxRule:realise(dimension, element, rules)
	if dimension == "x" then
		return element.parent.w - self.value
	end

	if dimension == "y" then
		return element.parent.h - self.value
	end

	if dimension == "w" then
		return element.parent.w - self.value
	end

	if dimension == "h" then
		return element.parent.h - self.value
	end
end

function MaxRule:set(value)
	self.value = value
end

function MaxRule:clone()
	return MaxRule.new(self.value)
end

function Plan.max(value)
	return MaxRule.new(value)
end

-- ====================================
-- Keep Rule
-- ====================================

---@class Plan.Rule.KeepRule: Plan.Rule
local KeepRule = {}
KeepRule.__index = KeepRule
KeepRule.__tostring = function(self)
	return "Keep"
end

function KeepRule.new()
	local self = setmetatable({}, KeepRule)
	return self
end

function KeepRule:realise(dimension, element, rules)
	return element[dimension]
end

function KeepRule:set(value)
end

function KeepRule:clone()
	return KeepRule.new()
end

function Plan.keep()
	return KeepRule.new()
end

-- ====================================
-- Keep Rule
-- ====================================

---@class Plan.Rule.ContentRule: Plan.Rule
---@field value Plan.Rule?
local ContentRule = {}
ContentRule.__index = ContentRule
ContentRule.__tostring = function(self)
	return "Content"
end

function ContentRule.new(defaultRule)
	local self = setmetatable({value = defaultRule}, ContentRule)
	return self
end

function ContentRule:realise(dimension, element, rules, desiredW, desiredH)
	return ((dimension == "w" and desiredW) or desiredH) or self.value:realise(dimension, element, rules, desiredW, desiredH) or 0
end

function ContentRule:set(value)
	self.value = value
end

function ContentRule:clone()
	return ContentRule.new()
end

---@param defaultRule Plan.Rule?
function Plan.content(defaultRule)
	return ContentRule.new(defaultRule)
end


-- ============================================================================
-- Rules Builder
-- ============================================================================

---@class Plan.Rules
---@field rules {x: Plan.Rule, y: Plan.Rule, w: Plan.Rule, h: Plan.Rule}
local Rules = {}
Rules.__index = Rules
Rules.__tostring = function(self)
	return ("X: %s\nY: %s\nW: %s\nH: %s"):format(
		self:getX(),
		self:getY(),
		self:getWidth(),
		self:getHeight()
	)
end

function Rules.new()
	local self = setmetatable({}, Rules)
	-- Default to take up full parent.
	self.rules = {
		x = Plan.parent(),
		y = Plan.parent(),
		w = Plan.parent(),
		h = Plan.parent(),
	}
	return self
end

---Validates the Plan.Rule input
---@param input Plan.Rule
---@param dimension string
---@return Plan.Rule
local function validateRuleInput(input, dimension)
	if isNumber(input) then
		return PixelRule.new(input)
	end

	if not isValidRule(input) then
		error("An invalid input was passed to " .. dimension .. " dimension")
	end

	return input
end

---Adds the X rule
---@param rule Plan.Rule
---@return self
function Rules:addX(rule)
	self.rules.x = validateRuleInput(rule, "x")
	return self
end

---Gets the X rule
---@return Plan.Rule
function Rules:getX()
	return self.rules.x
end

---Adds the Y rule
---@param rule Plan.Rule
---@return self
function Rules:addY(rule)
	self.rules.y = validateRuleInput(rule, "y")
	return self
end

---Gets the Y rule
---@return Plan.Rule
function Rules:getY()
	return self.rules.y
end

---Adds the W rule
---@param rule Plan.Rule
---@return self
function Rules:addWidth(rule)
	self.rules.w = validateRuleInput(rule, "width")
	return self
end

---Gets the W rule
---@return Plan.Rule
function Rules:getWidth()
	return self.rules.w
end

---Adds the H rule
---@param rule Plan.Rule
---@return self
function Rules:addHeight(rule)
	self.rules.h = validateRuleInput(rule, "height")
	return self
end

---Gets the H rule
---@return Plan.Rule
function Rules:getHeight()
	return self.rules.h
end

---Recalculates the sizing from the rules
---@param element Plan.Container
---@return number x
---@return number y
---@return number w
---@return number h
function Rules:realise(element)
	local parent = element.parent or {}
	local dw, dh = element:getDesiredDimensions()
	return (parent.x or 0) + self.rules.x:realise("x", element, self.rules, dw, dh),
			(parent.y or 0) + self.rules.y:realise("y", element, self.rules, dw, dh),
			self.rules.w:realise("w", element, self.rules, dw, dh),
			self.rules.h:realise("h", element, self.rules, dw, dh)
end

---Clones itself and returns a new Plan.Rules
---@return Plan.Rules
function Rules:clone()
	local copy = Rules.new()

	if self.rules.x then
		copy:addX(self.rules.x:clone())
	end

	if self.rules.y then
		copy:addY(self.rules.y:clone())
	end

	if self.rules.w then
		copy:addWidth(self.rules.w:clone())
	end

	if self.rules.h then
		copy:addHeight(self.rules.h:clone())
	end

	return copy
end

function Rules:update(dimension, fn, ...)
	dimension = string.lower(dimension)
	if dimension == "x" then
		self.rules.x = fn(self:getX(), ...)
	end

	if dimension == "y" then
		self.rules.y = fn(self:getY(), ...)
	end

	if dimension == "w" or dimension == "width" then
		self.rules.w = fn(self:getWidth(), ...)
	end

	if dimension == "h" or dimension == "height" then
		self.rules.h = fn(self:getHeight(), ...)
	end
end

Plan.Rules = Rules

-- ============================================================================
-- Rule Factories
-- ============================================================================

---@class Plan.RuleFactory
local RuleFactory = {}

---Returns Plan.Rules that fills up the entire parent
---@return Plan.Rules
function RuleFactory.full()
	local rules = Rules.new()
	rules:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.parent())
	return rules
end

---Returns Plan.Rules that be halved in the direction specified
---@param direction "top"|"bottom"|"left"|"right"
---@return Plan.Rules
function RuleFactory.half(direction)
	local rules = RuleFactory.full()

	if direction == "top" then
		rules:addHeight(Plan.relative(0.5))
	elseif direction == "bottom" then
		rules:addY(Plan.relative(0.5))
		rules:addHeight(Plan.relative(0.5))
	elseif direction == "left" then
		rules:addWidth(Plan.relative(0.5))
	elseif direction == "right" then
		rules:addX(Plan.relative(0.5))
		rules:addWidth(Plan.relative(0.5))
	else
		error("Invalid direction passed to RuleFactory.half(): "..direction)
	end

	return rules
end

---Adds "padding" around this Plan.Container by a factor.
---
---It makes this Plan.Container smaller around the edges.
---@param value number
---@return Plan.Rules
function RuleFactory.relativeGutter(value)
	local rules = Rules.new()
	rules:addX(Plan.relative(value))
			:addY(Plan.relative(value))
	-- margin must be applied on both "sides"
			:addWidth(Plan.relative(1 - value * 2))
			:addHeight(Plan.relative(1 - value * 2))
	return rules
end

---Adds "padding" around this Plan.Container by pixels.
---
---It makes this Plan.Container smaller around the edges.
---@param value number
---@return Plan.Rules
function RuleFactory.pixelGutter(value)
	local rules = Rules.new()
	rules:addX(Plan.pixel(value))
			:addY(Plan.pixel(value))
	-- margin must be applied on both "sides"
			:addWidth(Plan.max(value * 2))
			:addHeight(Plan.max(value * 2))
	return rules
end

---Makes this Plan.Container keep its position and size between refreshes.
---@return Plan.Rules
function RuleFactory.keepAll()
	local rules = Rules.new()
	rules:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.keep())
			:addHeight(Plan.keep())
	return rules
end

---Makes this Plan.Container keep its position between refreshes.
---
---Useful for determining the container's own size.
---@return Plan.Rules
function RuleFactory.keepSize()
	local rules = Rules.new()
	rules:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.keep())
			:addHeight(Plan.keep())
	return rules
end

Plan.RuleFactory = RuleFactory

-- ============================================================================
-- Entrypoint
-- ============================================================================

-- We cannot use `RuleFactory.full` as it relies on a parent, and this is the
-- root.
---@param scale number
local function __fullScreen(scale)
	local rules = Rules.new()
			:addX(PixelRule.new(0))
			:addY(PixelRule.new(0))
			:addWidth(PixelRule.new(love.graphics.getWidth() / scale))
			:addHeight(PixelRule.new(love.graphics.getHeight() / scale))
	return rules
end

---@class Plan.Root
local PlanRoot = Object:extend()

---Creates a new Plan.Root
---@param scale number
---@return Plan.Root
function PlanRoot:new(scale)
	do
		local root = Container(__fullScreen(scale))
		root._bubble = function() return false end
		root.isUIRoot = true
		root._depth = 1
		root._active = true
		root._inUITree = false
		---@type Plan.RootContext
		self.context = RootContext(root)
		---@type BoundsContext
		root._bounds = self.context.rootBounds
		---@type Plan.Container
		self.root = root
	end
	---@type number
	self.scale = scale or 1
	---@type boolean
	self.scaled = false
	---@type love.Canvas
	self.canvas = nil
	local w, h = love.graphics.getDimensions()
	if true or scale ~= 1 then
		self.scaled = true
		local canvasW, canvasH = math.ceil(w / scale), math.ceil(h / scale)
		self.context.rootBounds.w = canvasW
		self.context.rootBounds.h = canvasH
		self.canvas = love.graphics.newCanvas(canvasW, canvasH)
	--[[ else
		self.context.rootBounds.w = w
		self.context.rootBounds.h = h --]]
	end
	root = self
	rootContext = self.context
	return self
end

function PlanRoot:refresh()
	self.root.rules = __fullScreen(self.scale)
	local w, h = love.graphics.getDimensions()
	if true then
		local scale = self.scale
		local canvasW, canvasH = math.ceil(w / scale), math.ceil(h / scale)
		if canvasW ~= self.context.rootBounds.w or canvasH ~= self.context.rootBounds.h then
			-- Resize the canvas if it changed
			self.context.rootBounds.w = canvasW
			self.context.rootBounds.h = canvasH
			self.canvas:release()
			self.canvas = love.graphics.newCanvas(canvasW, canvasH)
		end
	--[[ else
		self.context.rootBounds.w = w
		self.context.rootBounds.h = h --]]
	end
	rootContext = self.context
	self.root:refresh()
end

function PlanRoot:addChild(child)
	rootContext = self.context
	self.root:addChild(child)
end

function PlanRoot:removeChild(child)
	rootContext = self.context
	self.root:removeChild(child)
end

function PlanRoot:update(dt)
	self.root:update(dt)
end

function PlanRoot:draw()
	-- Not nil when it has the "modaldraw" function
	---@type Plan.Container?
	local lastModal = self.context.modals[#self.context.modals]
	lastModal = (lastModal and lastModal.modaldraw and lastModal) or nil

	if true then
		love.graphics.setCanvas(self.canvas)
		love.graphics.clear()
		love.graphics.push("all")

		self.root:draw()
		if lastModal then
			lastModal:modaldraw()
		end

		love.graphics.pop()
		love.graphics.setCanvas()
		love.graphics.draw(self.canvas, 0, 0, 0, self.scale, self.scale)
	--[[ else
		self.root:draw()
		if lastModal then
			lastModal:modaldraw()
		end --]]
	end
end

function PlanRoot:drawCache()
	love.graphics.draw(self.canvas, 0, 0, 0, self.scale, self.scale)
end

---@type integer, integer
local lastX, lastY = 0, 0

---mousemoved callback
---@param mx integer
---@param my integer
---@param cx integer
---@param cy integer
function PlanRoot:mousemoved(mx, my, cx, cy)
	local factor = 1 / self.scale
	local windowX, windowY = mx * factor, my * factor
	lastX, lastY = windowX, windowY
	local focusedUI = self.context.focusedUI
	if focusedUI then
		if focusedUI.mousemoved then
			focusedUI:mousemoved(windowX, windowY, cx * factor, cy * factor)
		end
	else
		self.context:emitAtPoint(windowX, windowY, "mousemoved",
									windowX, windowY, cx * factor, cy * factor)
	end
	self.context:movePointer(windowX, windowY)
end

---mousepressed callback
---@param x integer
---@param y integer
---@param button integer
---@param isTouch boolean
---@param pressCount integer
function PlanRoot:mousepressed(x, y, button, isTouch, pressCount)
	local factor = 1 / self.scale
	local windowX, windowY = x * factor, y * factor
	lastX, lastY = windowX, windowY
	self.context:emitAtPoint(windowX, windowY, "mousepressed",
								windowX, windowY, button, isTouch, pressCount)
end

---mousereleased callback
---@param x integer
---@param y integer
---@param button integer
function PlanRoot:mousereleased(x, y, button)
	local factor = 1 / self.scale
	local windowX, windowY = x * factor, y * factor
	lastX, lastY = windowX, windowY
	self.context:emitAtPoint(windowX, windowY, "mousereleased",
								windowX, windowY, button)
end

---wheelmoved callback
---@param x integer
---@param y integer
function PlanRoot:wheelmoved(x, y)
	self.context:emitAtPoint(lastX, lastY, "wheelmoved", x, y)
end

---keypressed callback
---@param key love.KeyConstant
---@param scanCode love.Scancode
---@param isRepeat boolean
function PlanRoot:keypressed(key, scanCode, isRepeat)
	local focusedUI = self.context.focusedUI
	if focusedUI and focusedUI.keypressed then
		focusedUI:keypressed(key, scanCode, isRepeat)
		return true
	end
	return false
end

---textinput callback
---@param text string
function PlanRoot:textinput(text)
	local focusedUI = self.context.focusedUI
	if focusedUI and focusedUI.textinput then
		focusedUI:textinput(text)
	end
end

function PlanRoot:emit(event, ...)
	self.root:emit(event, ...)
end

function PlanRoot:_bubble(event, sourceElement)
	print("Bubble event received at root: "..event)
end

Plan.Root = PlanRoot

return Plan
