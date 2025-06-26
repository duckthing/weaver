local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"
local Plugin = require "src.data.plugin"
local GlobalConfig

local EnumProperty = require "src.properties.enum"

---@class CreateResource: Inspectable
local CreateResource = Inspectable:extend()
CreateResource.CLASS_NAME = "CreateResource"

---@type EnumProperty.Option[]
local createTemplates = {}
for _, plugin in ipairs(Plugin.plugins) do
	local c = plugin:getCreateInspectable()
	if c then
		createTemplates[#createTemplates+1] = {
			name = c.OBJECT_NAME or plugin.TYPE,
			value = c,
		}
	end
end

---@param newPlugin Plugin
Plugin.pluginInitialized:addAction(function(newPlugin)
	local c = newPlugin:getCreateInspectable()
	if c then
		createTemplates[#createTemplates+1] = {
			name = c.OBJECT_NAME or newPlugin.TYPE,
			value = c,
		}
	end
end)

local lastSelected

function CreateResource:new()
	CreateResource.super.new(self)

	if not GlobalConfig then
		GlobalConfig = require "src.global.config"
		local default = GlobalConfig.defaultResource:get()
		for _, c in ipairs(createTemplates) do
			if c.name == default then
				lastSelected = c.value
				break
			end
		end
	end

	---@type EnumProperty
	self.resource = EnumProperty(self, "Resource", lastSelected)
	self.resource:setOptions(createTemplates)

	self.resource.valueChanged:addAction(function()
		self.inspectablesChanged:trigger()
		lastSelected = self.resource:getValue()
	end)
end

function CreateResource:getProperties()
	---@type Property[]
	local t = {}

	if #createTemplates > 1 then
		t[#t+1] = self.resource
	end

	---@type Inspectable?
	local resource = self.resource:getValue()
	if resource then
		for _, property in ipairs(resource:getProperties()) do
			t[#t+1] = property
		end
	end

	return t
end

function CreateResource:getActionContext()
	return self.resource:getValue():getActionContext()
end

function CreateResource:getActions()
	---@type Action[]
	local t = {}

	---@type Inspectable?
	local resource = self.resource:getValue()
	if resource then
		for _, action in ipairs(resource:getActions()) do
			t[#t+1] = Action(
				action.name,
				function(_, source, presenter, ...)
					if action:run(resource, source, presenter, ...) then
						presenter:close()
					end
				end
			):setType(action:getType())
		end
	end

	return t
end

return CreateResource
