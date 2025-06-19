local Object = require "lib.classic"

-- Actions are just objects that can run something.
-- They do not have undo/redo functionality, but can create something that does.

---@class Action: Object
local Action = Object:extend()

---@alias Action.Context Context
---@alias Action.Type
---| "normal"
---| "close"
---| "confirm"
---| "decline"

function Action:new(name, callback)
	Action.super.new(self)
	---@type string
	self.name = name
	---The callback ran when required.
	---The first return value is a boolean on whether the action was a success.
	---@type (fun(self: Action, source, presenter, context: Action.Context))?
	self.callback = callback
end

---Returns the type of this Action
---@return Action.Type
function Action:getType()
	return self.type or "normal"
end

---Sets the type of this Action
---@param type Action.Type
---@return self
function Action:setType(type)
	self.type = type
	return self
end

function Action:run(source, presenter, context)
	if self.callback then
		return self:callback(source, presenter, context)
	end
	return false
end

return Action
