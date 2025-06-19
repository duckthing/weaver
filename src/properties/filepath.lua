local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Plan = require "lib.plan"
local Modal = require "src.global.modal"
local Property = require "src.properties.property"
local Label = require "ui.components.text.label"
local LineEdit = require "ui.components.text.lineedit"
local IconButton = require "ui.components.button.iconbutton"
local VBox = require "ui.components.containers.box.vbox"
local HBox = require "ui.components.containers.box.hbox"
local FileBrowser = require "ui.components.containers.modals.filebrowser"
local SpriteSheet = require "src.spritesheet"

local iconsTexture = love.graphics.newImage("assets/layer_buttons.png")
iconsTexture:setFilter("nearest", "nearest")
local iconSpriteSheet = SpriteSheet.new(iconsTexture, 22, 1)

local isWindows = love.system.getOS() == "Windows"
local pathSeparator = (isWindows and "\\") or "/"
local pathSeparatorByte = pathSeparator:byte(1)
-- /path/file.png => /path/
-- /path/to/folder/ => /path/to/folder/
-- local getDirOrParentPattern = (isWindows and "(.*[/\\])") or "(.*[/\\])"
local getFileParentDirPattern = (isWindows and "(.*[/\\])") or "(.*/)"
local getDirParentDirPattern = (isWindows and "(.*[/\\]).*[/\\]") or "(.*/).*/"

---@class FilePathProperty: Property
local FilePathProperty = Property:extend()

---@alias FilePathProperty.PathMode
---| "read"
---| "write"
---| "directory"

function FilePathProperty:new(object, name, value)
	FilePathProperty.super.new(self, object, name, value or "")
	self.type = "filepath"
	---@type FilePathProperty.PathMode
	self.pathMode = "read"
	---@type boolean # If we should apply a filter to the extensions
	self.limitExtensions = false
	---@type {[string]: boolean}
	self.allowedExtensions = {}
	---@type string?
	self.defaultExtension = nil
end

---@return string
function FilePathProperty:get()
	return self.value
end

---@param value string
function FilePathProperty:set(value)
	FilePathProperty.super.set(self, self:sanitizeInput(value))
end

---@param input string
---@return string
function FilePathProperty:sanitizeInput(input)
	local pathMode = self.pathMode

	local inputEndsWithSlash = Path.endsep(input) ~= nil

	if (pathMode == "read" or pathMode == "write") and not inputEndsWithSlash then
		-- Doesn't end with the end separator
		local result = input
		local filename, extension = Path.nameext(input)

		if self.limitExtensions and self.allowedExtensions[extension] ~= true then
			-- This property has limits on what extensions are allowed
			-- This one isn't valid

			if extension ~= nil then
				-- Extension exists, remove it
				result = result:gsub("."..extension, "", 1)
			end

			if self.defaultExtension then
				-- Use the default extension
				result = result.."."..self.defaultExtension
			else
				-- No default extension, get the first one found
				result = result.."."..next(self.allowedExtensions)
			end
		end

		return result
	else
		-- Directory (adds a slash to the end if it isn't there)
		local path = Path.endsep(input, nil, true)
		return path
	end
end

---Returns true if the path is valid based off of the provided parameters.
---@return boolean isValid
function FilePathProperty:isValidPath()
	local pathMode = self.pathMode
	local path = self.value

	if pathMode == "read" then
		-- File MUST exist
		local info = nativefs.getInfo(path, "file")
		return info ~= nil
	elseif pathMode == "write" then
		-- File can exist
		local info = nativefs.getInfo(path)
		return info == nil or info.type == "file"
	else
		-- Directory
		local info = nativefs.getInfo(path, "directory")
		return info ~= nil
	end
end

---Limits the extensions that can be set to this property.
---
---The first filter added will become the default, unless makeDefault is true.
---'extension' should not include the period.
---@param extension string
---@param makeDefault boolean?
function FilePathProperty:addFilter(extension, makeDefault)
	-- TODO: Prevent setting with a disallowed extension
	if extension:sub(1, 1) == "." then
		-- Remove the starting period
		extension = extension:sub(2)
		print(
			("Attempted to add extension filter to FilePathProperty '%s', which should not include the first period")
				:format(extension)
		)
	end

	self.allowedExtensions[extension] = true

	if makeDefault or not self.defaultExtension then
		self.defaultExtension = extension
	end

	if not self.limitExtensions then
		self.limitExtensions = true
		-- To sanitize it
		self:set(self.value)
	end
end

---Sets the path mode of the FilePathProperty.
---"read" only allows picking an existing file.
---"write" allows picking a non-existent file.
---"directory" only allows picking a directory.
---@param pathMode FilePathProperty.PathMode
function FilePathProperty:setPathMode(pathMode)
	if self.pathMode ~= pathMode then
		self.pathMode = pathMode
	end
end

-- First boolean = isWindows, second boolean = isDirectory
local itemPatterns = {
	[true] = {
		[true] = ".*([/\\])",
		[false] = ".*[/\\](.*)"
	},
	[false] = {
		[true] = ".*/(.*/)",
		[false] = ".*/(.*)"
	}
}

---Returns the item.
---
---If a directory, we return 'item' in '/path/to/item/'.
---If a file, we return 'item.ext' in '/path/to/item.ext'.
---@return string
function FilePathProperty:getItem()
	---@type string
	local pattern = itemPatterns[isWindows][self.pathMode == "directory"]
	return self.value:match(pattern)
end

---Returns the item, with the extension removed if it's there.
---
---If a directory, we return 'item' in '/path/to/item/'.
---If a file, we return 'item' in '/path/to/item.ext'.
---@return string
function FilePathProperty:getItemName()
	local item = self:getItem()
	if self.pathMode == "directory" then return item end

	local name, ext = Path.nameext(item)
	return name
end

---Returns the file extension
---'/path/to/file.ext' => 'ext', excluding the period
---@return string?
function FilePathProperty:getExtension()
	return Path.ext(self:getItem())
end

---Returns the parent directory.
---@return string
function FilePathProperty:getParentDirectory()
	return Path.parentdirsep(self.value) or ""
end

---Sets the item name.
---
---If a directory, we set 'item' in '/path/to/item/'.
---If a file, we set 'item' in '/path/to/item.ext'.
function FilePathProperty:setItemName(newName)
	local item = self:getItem()

	local newValue = self.value:gsub(item, newName, 1)
	self:set(newValue)
end

---@class FilePathProperty.VElement: VBox
local FilePathPropertyVElement = VBox:extend()

---@param rules Plan.Rules
---@param property FilePathProperty
function FilePathPropertyVElement:new(rules, property)
	FilePathPropertyVElement.super.new(self, rules)
	self.property = property

	---@type Label
	local label = Label(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(20)),
		self.property.name
	)

	self.label = label
	self:addChild(label)

	---@type LineEdit
	local lineEdit = LineEdit(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(0))
			:addWidth(Plan.max(26))
			:addHeight(Plan.pixel(26)),
		property:get()
	)
	lineEdit.preferStart = false
	lineEdit.property = property
	self.lineEdit = lineEdit

	self.lineEdit.sanitizeInput = function(line)
		line.inputfield:setText(line.property:sanitizeInput(line.inputfield:getText()))
	end

	self.lineEdit.textSubmitted:addAction(function(text)
		property:set(text)
	end)

	---@type Button
	local pickFileButton = IconButton(
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.pixel(0))
			:addWidth(Plan.pixel(26))
			:addHeight(Plan.aspect(1)),
		function(button)
			Modal.pushFileBrowser(self.property)
		end,
		iconSpriteSheet,
		18,
		2
	)
	self.button = pickFileButton

	---@type HBox
	local hbox = HBox(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(26))
	)
	self.hbox = hbox

	hbox:addChild(lineEdit)
	hbox:addChild(pickFileButton)
	self:addChild(hbox)

	self._valueChangedAction = property.valueChanged:addAction(function(p, value)
		self.lineEdit:setText(value)
	end)
end

function FilePathProperty:getVElement()
	return FilePathPropertyVElement(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(46)),
		self
	)
end

return FilePathProperty
