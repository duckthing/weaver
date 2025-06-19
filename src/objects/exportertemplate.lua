local Inspectable = require "src.properties.inspectable"
local Action = require "src.data.action"

---@class ExporterTemplate: Inspectable
local ExporterTemplate = Inspectable:extend()

function ExporterTemplate:new()
	ExporterTemplate.super.new(self)
	---@type boolean
	self.alreadyExported = false
end

function ExporterTemplate:export()
	self.alreadyExported = true
end

---@type Action[]
local actions = {
	Action(
		"Export",
		function (action, exporter)
			---@cast exporter ExporterTemplate
			exporter:export()
			return true
		end
	):setType("accept"),
}

function ExporterTemplate:getActions()
	return actions
end


return ExporterTemplate
