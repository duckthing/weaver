local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Status = require "src.global.status"
local SaveObject = require "src.objects.saveobject"
local Modal = require "src.global.modal"

local Handler = {}

-- TODO: Allow multiple importers/exporters instead of overwriting

---@type {[string]: Format}
local extensionsToImporters = {}
---@type {[Object]: Format}
local objectsToExporters = {}

---Adds a format to the global handler
---@param format Format
function Handler.addFormat(format)
	for _, extension in ipairs(format.IMPORT_EXTENSIONS) do
		extensionsToImporters[extension] = format
	end

	for _, object in ipairs(format.EXPORT_FOR_TYPES) do
		objectsToExporters[object] = format
	end
end

---Imports and handles the data at a filepath
---@param path string
function Handler.importAndHandle(path)
	---@type string
	local extension = Path.ext(path) or ""

	local format = extensionsToImporters[extension]
	if format then
		local success, dataOrError = format:handleImport(path)
		if success then
			if dataOrError then
				-- We got the imported data back
				format:handleImportSuccess(path, dataOrError)
			end
			-- If no imported data, the format likely pushed an inspector to the user for more input
		else
			-- Error message
			Status.pushTemporaryMessage(dataOrError, "error", 5)
			return false
		end
	else
		return false, ("No importer for %s assigned"):format(extension)
	end

	return true
end

---@param data Object
---@param path string
---@param format Format
---@return boolean success
---@return string? err
function Handler.saveToPath(data, path, format)
	local file = nativefs.newFile(path)

	if not file:open("w") then
		Status.pushTemporaryMessage("Could not open file for writing", "error", 5)
		return false, "Could not open file for writing"
	end

	local success, dataOrError = format:export(data, path, file)

	file:close()

	if success then
		Status.pushTemporaryMessage(("Saved: %s"):format(path), nil, 5)
		-- If no imported data, the format likely pushed an inspector to the user for more input
	else
		-- Error message
		Status.pushTemporaryMessage(dataOrError or "Action errored without a message", "error", 5)
		return false, dataOrError
	end

	return true
end

---@param data Object
function Handler.promptForSaving(data, defaultPath)
	---@type Format
	local format
	for obj, f in pairs(objectsToExporters) do
		if data:is(obj) then
			format = f
			break
		end
	end

	if not format then
		Status.pushTemporaryMessage(("No exporter set for %s"):format(tostring(data)), "error", 5)
		return
	end

	local extensions = Handler.getValidExtensionsForData(data)
	---@type SaveObject
	local saveObject = SaveObject(data, defaultPath, extensions, function(_, path)
		local success, err = Handler.saveToPath(data, path, format)
	end)

	saveObject:present()
end

---Returns the extensions this Object can be saved as
---@param data Object
---@return string[] extensions
function Handler.getValidExtensionsForData(data)
	---@type string[]
	local allExtensions = {}

	for obj, f in pairs(objectsToExporters) do
		if data:is(obj) then
			for _, ext in ipairs(f.IMPORT_EXTENSIONS) do
				allExtensions[#allExtensions+1] = ext
			end
		end
	end

	return allExtensions
end

return Handler
