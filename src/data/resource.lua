local Object = require "lib.classic"
local StringProperty = require "src.properties.string"
local BoolProperty = require "src.properties.bool"

---@alias Resource.Type
---| "none"
---| "home"
---| "sprite"
---| "scene"

---@alias Resource.Callback fun(self: Resource, ...): nil

---@class Resource: Object
local Resource = Object:extend()
Resource.TYPE = "none"

function Resource:new()
	---@type StringProperty
	self.name = StringProperty(self, "Name", "Buffer")
	---@type integer
	self.id = 0
	---@type table
	self.editorData = {}
	---@type ExporterTemplate?
	self.exporter = nil
	---@type SaveTemplate?
	self.saveTemplate = nil
	---@type BoolProperty
	self.modified = BoolProperty(self, "Modified", false)
	return self
end

---@return ExporterTemplate?
function Resource:getExporter()
	return self.exporter
end

---@return SaveTemplate?
function Resource:getSaveTemplate()
	return self.saveTemplate
end

---Removes all actions from the Resource
function Resource:removeAllActions()
end

---Returns the WGF type of this Resource
---@return string?
function Resource.getWGFType()
	return nil
end

---Add necessary info to the header here. The type is already inserted.
---@param headerTable table
function Resource:prepareHeaderWGF(headerTable)
end

---Serializes this Buffer into the WGF format.
---This function also needs to serialize the headerTable
---@param headerTable table
---@param strbuf string.buffer
---@return boolean success
---@return integer miscSize
function Resource:serializeWGF(headerTable, strbuf)
	return false, 0
end

---Deserializes this string.buffer into a Buffer
---@param headerTable table
---@param strbuf string.buffer
---@param path string
---@return boolean # success
---@return string | Resource # buffer
function Resource.deserializeWGF(headerTable, strbuf, path)
	return false, "Not implemented"
end

function Resource:__tostring()
	return self.TYPE
end

return Resource
