local Contexts = {}

---@type Context?
Contexts.activeContext = nil
---@type Context[]
Contexts.contextStack = {}

---Gets the most recent Context of the class type
---@param type Context
---@return Context?
function Contexts.getContextOfType(type)
	local stack = Contexts.contextStack
	for i = #stack, 1, -1 do
		local context = stack[i]
		if context:is(type) then
			return context
		end
	end
	return nil
end

---@param context Context
function Contexts.pushContext(context)
	Contexts.contextStack[#Contexts.contextStack+1] = context
	Contexts.activeContext = context
	context:onPushed()
end

---@param context Context?
function Contexts.popContext(context)
	local stack = Contexts.contextStack
	if context == nil then
		stack[#stack] = nil
		Contexts.activeContext = stack[#stack]
	else
		local index = 0
		for i = #stack, 1, -1 do
			if stack[i] == context then
				-- found it
				index = i
				break
			end
		end

		if index ~= 0 then
			table.remove(stack, index):onPopped()
		end
		Contexts.activeContext = stack[#stack]
	end
end

function Contexts.keypressed(key, scanCode, isRepeat)
	local stack = Contexts.contextStack
	for i = #stack, 1, -1 do
		local context = stack[i]
		local success = context:keypressed(key, scanCode, isRepeat)
		if success then
			return true
		end
	end
	return false
end

---Causes an Action to happen, if it exists
---@param actionName string
---@param source Plan.Container?
---@param presenter Plan.Container?
---@return boolean success
function Contexts.raiseAction(actionName, source, presenter)
	local stack = Contexts.contextStack
	for i = #stack, 1, -1 do
		local context = stack[i]
		local actions = context:getActions()
		if actions then
			local desiredAction = actions[actionName]
			if desiredAction then
				desiredAction:run(source, presenter, context)
				return true
			end
		end
	end
	return false
end

return Contexts
