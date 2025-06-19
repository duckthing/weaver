local nativefs = require "lib.nativefs"
local Object = require "lib.classic"

---@class Format: Object
local Format = Object:extend()
Format.FORMAT_NAME = "Unimplemented Format"
---@type string[]
Format.IMPORT_EXTENSIONS = {}
---@type Object[]
Format.EXPORT_FOR_TYPES = {}

---Imports a file with the path and file object
---@param path string
---@param file love.File
---@return boolean success
---@return any | string dataOrError
function Format:import(path, file, ...)
	return false, ("Importer not implemented for %s"):format(self.FORMAT_NAME)
end

---Exports a file with the path and file object
---@param data any
---@param path string
---@param file love.File
---@return boolean success
---@return string? error
function Format:export(data, path, file, ...)
	return false, ("Exporter not implemented for %s"):format(self.FORMAT_NAME)
end

---This makes the format perform the import process manually. You might want to look at Format:import() instead.
---@param path string
---@return boolean success
---@return any | string dataOrError
function Format:handleImport(path)
	local canImport = #self.IMPORT_EXTENSIONS > 0
	if not canImport then return false, ("Importer not implemented for %s"):format(self.FORMAT_NAME) end

	local info = nativefs.getInfo(path, "file")
	if info then
		local file = nativefs.newFile(path)

		if not file:open("r") then
			return false, "Could not open file for reading"
		end

		local success, dataOrError = self:import(path, file)

		file:close()

		if success and dataOrError then
			return true, dataOrError
		else
			-- Error message
			return false, dataOrError
		end
	else
		return false, "File doesn't exist"
	end
end

---Handles an import success with any expected automatic behavior.
---
---For example, if you import a palette, this function should add it to the global palettes.
---Importing a sprite should focus it in the editor.
---@param path string
---@param data any
function Format:handleImportSuccess(path, data)
	print(":handleImportSuccess is unimplemented for:", path)
end

return Format
