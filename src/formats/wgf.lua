local ffi = require "ffi"
local nativefs = require "lib.nativefs"
local StringBuffer = require "string.buffer"
local Format = require "src.data.format"
local GlobalConfig = require "src.global.config"
local Resource = require "src.data.resource"
local Resources = require "src.global.resources"

-- Weaver Generic File
---@class WgfFormat: Format
local WgfFormat = Format:extend()
WgfFormat.FORMAT_NAME = "WgfFormat"
WgfFormat.IMPORT_EXTENSIONS = {"wgf"}
WgfFormat.EXPORT_FOR_TYPES = {Resource}

-- http://stackoverflow.com/questions/9137415/ddg#9140231
local function fromhex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16))
	end))
end

local function tohex(str)
	return (str:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

-- local STRING_MAGIC_NUMBER = fromhex("501ACE00") -- "Solace00" (RIP)
local STRING_MAGIC_NUMBER = fromhex("3EA7E400") -- "Weaver00"

local typeToResource = {}

local function deepPrint(t, name, depth)
	if not name then name = "" end
	if not depth then depth = 1 end

	local buffer = ""
	for i = 1, depth do
		buffer = buffer.."    "
	end

	if type(t) ~= "table" then
		print(buffer..tostring(t))
		return
	end

	local bracketBuffer = ""
	for i = 2, depth do
		bracketBuffer = bracketBuffer.."    "
	end


	if #name > 0 then
		print(bracketBuffer..name.." = {")
	else
		print(bracketBuffer.."{")
	end
	for k, v in pairs(t) do
		if type(v) == "table" then
			deepPrint(v, tostring(k), depth + 1)
		else
			print(buffer..k.." = "..tostring(v))
		end
	end
	print(bracketBuffer.."}")
end

---Registers the type for WGF files
---@param resource Resource
function WgfFormat.registerWGFType(resource)
	local type = resource.getWGFType()
	if not type then return end
	if typeToResource[type] then
		-- Something exists here, warn about override
		print(("[WARN] Overriding previous type at '%s'"):format(type))
	end
	typeToResource[type] = resource
end

---@param path string
---@param file love.File
---@return boolean success
---@return Resource | string bufferOrMessage
function WgfFormat:import(path, file)
	do
		-- Check magic number
		local contents, length = file:read(#STRING_MAGIC_NUMBER)
		if contents ~= STRING_MAGIC_NUMBER then
			file:close()
			print(contents, "~=", STRING_MAGIC_NUMBER)
			return false, "Invalid WGF (magic number does not match)"
		end
	end

	local buf = StringBuffer.new()

	---@type table
	local headerTable
	do
		-- Get the length of the header, and read it
		local lengthHex = file:read(4)
		local length = tonumber(tohex(lengthHex), 16)
		local headerBytes, readLength = file:read("data", length)
		---@cast headerBytes love.FileData

		buf:putcdata(ffi.cast("uint8_t*", headerBytes:getFFIPointer()), readLength)
		---@diagnostic disable-next-line
		headerTable = buf:decode()
	end

	if headerTable == nil then
		return false, "Header was not found"
	end

	local ResourceType = typeToResource[headerTable.type]
	if not ResourceType then
		file:close()
		return false, "Type not found"
	end

	-- Read the rest of the file, and let the ResourceType handle it
	local container, containerSize = file:read("data", "all")
	---@cast container love.FileData
	local containerPointer = ffi.cast("uint8_t*", container:getFFIPointer())
	buf:putcdata(containerPointer, containerSize)

	---@type Resource
	local resource = ResourceType.deserializeWGF(headerTable, buf, path)
	file:close()
	GlobalConfig.addFileToRecents(path)
	return true, resource
end

---@param resource Resource
---@param path string
---@return boolean success
---@return string? err
function WgfFormat:export(resource, path)
	local type = resource.getWGFType()
	if not type then
		return false, "This Resource does not have an WGF exporter"
	end

	local buf = StringBuffer.new()
	buf:put(STRING_MAGIC_NUMBER)

	local headerTable = {
		type = resource:getWGFType()
	}
	resource:prepareHeaderWGF(headerTable)

	do
		-- Insert the length of the header, and the header
		local encodedHeader = StringBuffer.encode(headerTable)
		buf:put(fromhex(string.format("%08X", #encodedHeader)))
		buf:put(encodedHeader)
	end

	local success = resource:serializeWGF(headerTable, buf)

	if success then
		local file = nativefs.newFile(path)
		if not file:open("w") then
			return false, "Failed to open"
		end

		while true do
			local ref, len = buf:ref()
			if len == 0 then break end
			buf:skip(len)
			if not file:writecdata(ref, len) then
				file:close()
				return false, "Failed writing"
			end
		end

		file:close()
		return true
	else
		print("Failed to export")
		return false
	end
end

function WgfFormat:handleImportSuccess(path, data)
	Resources.selectResourceId(Resources.addResource(data))
end

--== The WGF format
-- First 4 bytes of the file is the magic number (0x501ACE00)
-- The next 4 bytes is the size of the Lua table header ('n').
-- The next 'n' bytes is the serialized Lua table header, containing the type and other useful at-a-glance info
-- Then, the rest of the file is handled by the resource deserializer

return WgfFormat
