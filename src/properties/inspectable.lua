local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Property = require "src.properties.property"
local LabelProperty = require "src.properties.label"

---@class Inspectable: Object
local Inspectable = Object:extend()
Inspectable.CLASS_NAME = "Inspectable"

function Inspectable:new()
	Inspectable.super.new(self)
	--- This event fires when the amount of properties or actions changed
	self.inspectablesChanged = Luvent.newEvent()
end

---@type table
local EMPTY_ARR = {}
local AUTOGEN_WARNING = LabelProperty(EMPTY_ARR, "Warning", "Obj:getProperties() is not implemented")

---Returns the properties of the Inspectable
---@return Property[]
function Inspectable:getProperties()
	-- Do the default property scan.
	-- NOT RECOMMENDED!! Implement this function yourself!!
	local properties = {
		AUTOGEN_WARNING
	}

	for _, v in pairs(self) do
		if type(v) == "table" and v["is"] and v:is(Property) then
			properties[#properties+1] = v
		end
	end

	return properties
end

---Returns the actions that can be performed on the Inspectable
---@return Action[]
function Inspectable:getActions()
	return EMPTY_ARR
end

---Sets the value of a property
---@param key string
---@param ... unknown
function Inspectable:setProperty(key, ...)
	---@type Property
	local property = self[key]
	if key and type(property) == "table" and property:is(Property) then
		property:set(...)
	else
		print(("[WARN] Attempt to set property at key %s, which is not a valid property"):format(key))
	end
end

--[[ ---Converts own actions from Inspectable.Action[] to PopupMenu.Action[]
function Inspectable:getPopupMenuActions()
	local actions = self:getActions()
	---@type Action[]
	local popupActions = {}

	for _, action in ipairs(actions) do
		popupActions[#popupActions+1] = {
			name = action.name,
			type = action.type or "normal",
			---@param window PopupWindow
			---@param item Action
			---@param button Button
			callback = function(window, item, button)
				action.callback(self)
				window:close()
			end
		}
	end

	return popupActions
end --]]

---Returns the context that should be used for the associated actions
---@return Action.Context?
function Inspectable:getActionContext()
	return nil
end

---Destroys all Properties in this Inspectable
function Inspectable:destroy()
end

function Inspectable:__tostring()
	return self.CLASS_NAME
end

return Inspectable
