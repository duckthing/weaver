local Object = require "lib.classic"
local Keybinds = require "src.data.keybinds"

---@class Context: Object
local Context = Object:extend()
Context.CONTEXT_NAME = "Context"

---@param actions Keybinds.ActionsMap?
---@param defaultKeybinds Keybinds.KeyCombinations?
function Context:new(actions, defaultKeybinds)
	Context.super.new(self)
	self.actions = actions or {}
	---@type Keybinds
	self.keybinds = Keybinds(defaultKeybinds, actions)
	---@type boolean If true, the key events won't be passed to other Contexts
	self.sinkAllEvents = false
end

---Returns all Actions that are a part of this Context.
---@return Keybinds.ActionsMap?
function Context:getActions()
	return self.actions
end

---Returns the Keybinds object
---@return Keybinds?
function Context:getKeybinds()
	return self.keybinds
end

---@return Keybinds.KeyCombinations?
function Context:deserializeKeybinds()
	return self.keybinds.defaultKeyMap
end

---@return Keybinds.SerializedData?
function Context:serializeKeybinds()
	return self.keybinds:serialize()
end

---Sets a lot of keybinds at once. Useful for loading from Context:getChangedKeybinds()
---@param serializedKeybinds Keybinds.SerializedData?
function Context:addChangedKeybinds(serializedKeybinds)
	self.keybinds:deserialize(serializedKeybinds)
	--[[ if not serializedKeybinds then return end

	local keybinds = self.keybinds
	for modifier, keyMap in pairs(serializedKeybinds) do
		---@cast modifier Keybinds.ModifierCombinations
		---@cast keyMap {[love.KeyConstant]: string}

		for key, action in pairs(keyMap) do
			keybinds:remapAction(action, modifier, key)
		end
	end --]]
end

---@param key love.KeyConstant
---@param scanCode love.Scancode
---@param isRepeat boolean
---@return boolean validKeybind
function Context:keypressed(key, scanCode, isRepeat)
	local keybinds = self:getKeybinds()
	if keybinds then
		return keybinds:keypressed(self, key, scanCode, isRepeat)
			or self.sinkAllEvents
	end
	return self.sinkAllEvents
end

function Context:onPushed()
end

function Context:onPopped()
end

function Context:__tostring()
	return self.CONTEXT_NAME
end

local specialByte = ("%"):byte(1, 1)
local ContextRefMT = {
	__index = function(self, k)
		if k ~= "is" then
			-- Not checking its type
			local realVal = rawget(self, k)
			if realVal ~= nil then return realVal end
			return rawget(self, "ref")[k]
		end
	end,
	__newindex = function(self, k, v)
		---@cast k string
		if k:byte(1, 1) == specialByte then
			rawset(self, k:sub(2), v)
		else
			rawget(self, "ref")[k] = v
		end
	end,
	__tostring = function(self)
		return tostring(rawget(self, "ref")).." (ref)"
	end
}

---@class ContextRef: Context

local function referenceIs(self, type)
	local ref = rawget(self, "ref")
	return ref:is(type)
end

---Returns a temporary reference to a Context.
---This is useful if you want to share keybinds without creating a copy per new element.
---@return ContextRef
function Context:asReference()
	return setmetatable({
		ref = self,
		isReference = true,
		is = referenceIs,

	}, ContextRefMT)
end

return Context
