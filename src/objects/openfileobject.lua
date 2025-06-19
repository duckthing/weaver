local Inspectable = require "src.properties.inspectable"
local Modal = require "src.global.modal"
local FilePathProperty = require "src.properties.filepath"
local Plugin = require "src.data.plugin"
local Handler = require "src.global.handler"

---@class OpenFileObject: Inspectable
local OpenFileObject = Inspectable:extend()

function OpenFileObject:new()
	OpenFileObject.super.new(self)
	---@type FilePathProperty
	self.path = FilePathProperty(self, "Path", love.filesystem.getUserDirectory().."Desktop/")
	self.path:setPathMode("read")

	-- Adds supported file extensions
	for _, plugin in ipairs(Plugin.plugins) do
		local i = plugin:getImportInspectable()
		if i then
			local extensions = i:getSupportedExtensions()
			if extensions then
				for _, extension in ipairs(extensions) do
					self.path:addFilter(extension)
				end
			end
		end
	end

	self.path.valueChanged:addAction(function(_, requestedPath)
		Handler.importAndHandle(requestedPath)
	end)
end

function OpenFileObject:present()
	Modal.pushFileBrowser(self.path)
end

return OpenFileObject
