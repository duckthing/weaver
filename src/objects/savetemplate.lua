local Inspectable = require "src.properties.inspectable"
local Modal = require "src.global.modal"
local FilePathProperty = require "src.properties.filepath"
local Status = require "src.global.status"
local Resources = require "src.global.resources"
local GlobalConfig = require "src.global.config"

---@class SaveTemplate: Inspectable
local SaveTemplate = Inspectable:extend()
SaveTemplate.saveType = "unassigned"

local isWindows = love.system.getOS() == "Windows"

---@param resource Resource
function SaveTemplate:new(resource)
	SaveTemplate.super.new(self)
	---@type boolean
	self.alreadySaved = false
	---@type FilePathProperty
	self.path = FilePathProperty(self, "Path", love.filesystem.getUserDirectory().."Desktop/"..resource.name:get())
	self.path:setPathMode("write")
end

function SaveTemplate:saveOrPresent()
	if self.alreadySaved then
		self:handleSave()
	else
		self:present()
	end
end

function SaveTemplate:present()
	Modal.pushInspector(self)
end

---The logic for saving
---@param resource Resource
---@param path string
---@return boolean success
---@return string? err
function SaveTemplate:save(resource, path)
	return true
end

function SaveTemplate:handleSave()
	if self.alreadySaved then
		local path = self.path:get()
		local formattedPath = path

		if not isWindows then
			-- Replace home directory with ~
			formattedPath = path:gsub(love.filesystem.getUserDirectory(), "~/")
		end

		if self.path:isValidPath() then
			local resource = Resources.getCurrentResource()
			if not resource or resource.TYPE ~= self.saveType then return end
			---@cast resource Resource

			local success, err = self:save(resource, path)
			self:onSaveResult(success, err, resource, path, formattedPath)
			if success then
				resource.modified:set(false)
				Status.pushTemporaryMessage(("Saved: %s"):format(formattedPath), nil, 5)
				GlobalConfig.addFileToRecents(path)
			else
				-- Couldn't save
				Status.pushTemporaryMessage(("Failed to save: %s"):format(err), "error", 10)
				self.alreadySaved = false
			end
		else
			Status.pushTemporaryMessage(("Invalid save path: %s"):format(formattedPath), "error", 10)
			self.alreadySaved = false
		end
	else
		self.alreadySaved = true
		self:handleSave()
	end
end

---Ran after attempting :save()
---@param success boolean
---@param err string?
---@param resource Resource
---@param path string
---@param formattedPath string
function SaveTemplate:onSaveResult(success, err, resource, path, formattedPath)
end

local EMPTY_ARR = {}
function SaveTemplate:getActions()
	return EMPTY_ARR
end

return SaveTemplate
