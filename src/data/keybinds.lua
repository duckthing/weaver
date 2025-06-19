local Object = require "lib.classic"

---@class Keybinds: Object
local Keybinds = Object:extend()

---@alias Keybinds.ModifierCombinations
---| "normal"
---| "alt"
---| "ctrl"
---| "shift"
---| "altctrl"
---| "altshift"
---| "ctrlshift"
---| "altctrlshift"

---@class Keybinds.KeyCombinations
---@field normal {[love.KeyConstant]: string}?
---@field alt {[love.KeyConstant]: string}?
---@field ctrl {[love.KeyConstant]: string}?
---@field shift {[love.KeyConstant]: string}?
---@field altctrl {[love.KeyConstant]: string}?
---@field altshift {[love.KeyConstant]: string}?
---@field ctrlshift {[love.KeyConstant]: string}?
---@field altctrlshift {[love.KeyConstant]: string}?

---@alias Keybinds.ActionsMap
---| {[string]: Action}

local function getModifier()
	local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
	local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

	if alt then
		if ctrl then
			if shift then
				return "altctrlshift"
			end
			return "altctrl"
		elseif shift then
			return "altshift"
		end
		return "alt"
	elseif ctrl then
		if shift then
			return "ctrlshift"
		end
		return "ctrl"
	elseif shift then
		return "shift"
	end
	return "normal"
end

---Creates a new Keybinds object
---@param defaultMap Keybinds.KeyCombinations?
---@param actions Keybinds.ActionsMap?
function Keybinds:new(defaultMap, actions)
	Keybinds.super.new(self)
	self.defaultKeyMap = defaultMap or {}
	---@type Keybinds.KeyCombinations
	self.currKeyMap = {}
	self.actions = actions or {}
end

---Activates the relevant action bound to a keybind
---@param context Context
---@param key love.KeyConstant
---@param scanCode love.Scancode
---@param isRepeat boolean
---@return boolean validKeybind
function Keybinds:keypressed(context, key, scanCode, isRepeat)
	local modifier = getModifier()

	---@type {[love.KeyConstant]: string}?
	local modified = self.currKeyMap[modifier]
	if modified then
		local bound = modified[key]
		if bound then
			local actions = self.actions
			local action = actions[bound]
			if action then
				actions[bound]:run(nil, nil, context)
			end
			return true
		end
	end

	return false
end

---Remaps an action to a modifier combination and a key, removing the old key combination if it exists
---@param actionName string
---@param modifiers Keybinds.ModifierCombinations
---@param key love.KeyConstant
function Keybinds:remapAction(actionName, modifiers, key)
	local action = self.actions[actionName]
	if not action then return end

	if not self.currKeyMap[modifiers] then
		self.currKeyMap[modifiers] = {}
	end

	--[[ if self.defaultKeyMap[modifiers] and self.defaultKeyMap[modifiers][key] == actionName then
		-- Remap to original key combination, remove this keymap
		self.currKeyMap[modifiers][key] = nil
		return
	end --]]

	-- Remap
	self.currKeyMap[modifiers][key] = actionName
end

---Returns the action name under a key combination, if it exists
---@param modifiers Keybinds.ModifierCombinations
---@param key love.KeyConstant
---@return string?
function Keybinds:hasMapping(modifiers, key)
	return (self.currKeyMap[modifiers] and self.currKeyMap[modifiers][key]) or nil
end

---Resets the current keybinds to the default. Should be called after creating a context.
function Keybinds:resetToDefault()
	self.currKeyMap = {}
	for modifier, keyToAction in pairs(self.defaultKeyMap) do
		local modifierArr = {}
		self.currKeyMap[modifier] = modifierArr

		for key, action in pairs(keyToAction) do
			modifierArr[key] = action
		end
	end
end

---Returns a table that can be deserialized later
---@return Keybinds.SerializedData
function Keybinds:serialize()
	-- Save the available actions so we can upgrade easily later
	---@type string[]
	local availableActions = {}

	-- Also save the keymap
	---@type Keybinds.KeyCombinations
	local keymap = self.currKeyMap

	---@class Keybinds.SerializedData
	local data = {
		actions = availableActions,
		keymap = keymap,
	}

	local nameToAction = self.actions
	for actionName, _ in pairs(nameToAction) do
		availableActions[#availableActions+1] = actionName
	end

	return data
end

---Remaps keys to actions from serialized data
---@param data Keybinds.SerializedData?
function Keybinds:deserialize(data)
	if data == nil then
		self:resetToDefault()
		return
	end

	---The actions we have now
	---@type {[string]: boolean}
	local currentActions = {}

	do
		local nameToAction = self.actions
		for actionName, _ in pairs(nameToAction) do
			currentActions[actionName] = true
		end
	end

	---The actions we had when these keybinds were serialized
	---@type {[string]: boolean}
	local formerActions = {}

	do
		local nameToAction = data.actions
		for _, actionName in ipairs(nameToAction) do
			formerActions[actionName] = true
		end
	end


	---The actions that were added since these keybinds were serialized, so we can add them
	---@type {[string]: boolean}
	local newActions = {}
	local totalNewFound = 0

	-- (Getting the difference)
	do
		for currAction, _ in pairs(currentActions) do
			if formerActions[currAction] == nil then
				-- This action is new (there can be duplicate new actions, though)
				newActions[currAction] = true
				totalNewFound = totalNewFound + 1
			end
		end
	end

	---The actions that were removed since these keybinds were serialized, so we can ignore them
	---@type {[string]: boolean}
	local removedActions = {}

	do
		for formerAction, _ in pairs(formerActions) do
			if currentActions[formerAction] == nil then
				-- This action was removed
				removedActions[formerAction] = true
			end
		end
	end

	---The new keymap
	---@type Keybinds.KeyCombinations
	local newKeyMap = {}
	self.currKeyMap = newKeyMap

	-- First, map the actions that weren't there before
	if totalNewFound > 0 then
		-- There exists at least 1 new action
		for modifiers, keys in pairs(self.defaultKeyMap) do
			---@cast modifiers string
			---@cast keys {[string]: string}
			for key, currentAction in pairs(keys) do
				if newActions[currentAction] then
					-- Found the new action
					totalNewFound = totalNewFound - 1

					if not newKeyMap[modifiers] then newKeyMap[modifiers] = {} end
					newKeyMap[modifiers][key] = currentAction

					if totalNewFound < 1 then
						goto stopNewKeyRemapping
					end
				end
			end
		end
	end
	::stopNewKeyRemapping::

	-- Now map the old ones on top
	for modifiers, keys in pairs(data.keymap) do
		---@cast modifiers string
		---@cast keys {[string]: string}
		for key, currentAction in pairs(keys) do
			if removedActions[currentAction] == nil then
				-- This action wasn't removed in this version
				if not newKeyMap[modifiers] then newKeyMap[modifiers] = {} end
				newKeyMap[modifiers][key] = currentAction
			end
		end
	end
end

return Keybinds
