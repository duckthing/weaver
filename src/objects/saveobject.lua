local Inspectable = require "src.properties.inspectable"
local Modal = require "src.global.modal"
local FilePathProperty = require "src.properties.filepath"

---@class SaveObject: Inspectable
local SaveObject = Inspectable:extend()

local isWindows = love.system.getOS() == "Windows"

---@param object Object
function SaveObject:new(object, defaultPath, extensions, callback)
	SaveObject.super.new(self)
	---@type FilePathProperty
	self.path = FilePathProperty(self, "Path", defaultPath or love.filesystem.getUserDirectory().."Desktop/")
	self.path:setPathMode("write")

	-- Adds supported file extensions
	for _, extension in ipairs(extensions) do
		self.path:addFilter(extension)
	end

	self.path.valueChanged:addAction(callback)
end

function SaveObject:present()
	Modal.pushFileBrowser(self.path)
	-- To force an update
	self.path.value = ""
end

return SaveObject
