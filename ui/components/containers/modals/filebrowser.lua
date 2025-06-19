local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Plan = require "lib.plan"
local PopupWindow = require "ui.components.containers.modals.popupwindow"
local LineEdit = require "ui.components.text.lineedit"
local VScroll = require "ui.components.containers.box.vscroll"
local LabelButton = require "ui.components.button.labelbutton"

local Contexts = require "src.global.contexts"
local Context = require "src.data.context"
local Action = require "src.data.action"

local isWindows = love.system.getOS() == "Windows"
local pathSeparator = (isWindows and "\\") or "/"
local pathSeparatorByte = pathSeparator:byte(1)
local getDirOrParentPattern = (isWindows and "(.*[/\\])") or "(.*[/\\])"
local getParentDirPattern = (isWindows and "(.*[/\\]).*[/\\]") or "(.*/).*/"
local folderIcon = love.graphics.newImage("assets/folder.png")

---@class FileBrowser.Button: LabelButton
local FBButton = LabelButton:extend()

---@param self FileBrowser.Button
local function onFBButtonClicked(self)
	self:bubble("_bubbleFBClicked", self.fullPath, self.isFile)
end

local fbActions = {
	select_current_working_directory = Action(
		"Select Current Working Directory",
		function(source, _, _, context)
			---@type FileBrowser?
			local fb = context.fileBrowser
			if fb then
				local lineEdit = fb.cwdLineEdit
				lineEdit:startEdit()
				lineEdit.inputfield:selectAll()
			end
		end
	)
}

local fbKeybinds = {
	ctrl = {
		l = "select_current_working_directory"
	}
}

---@type Context
local FileBrowserContext = Context(fbActions, fbKeybinds)
FileBrowserContext.CONTEXT_NAME = "FileBrowserContext"
FileBrowserContext.keybinds:resetToDefault()

---@param rules Plan.Rules
---@param itemName string
---@param fullPath string
---@param isFile boolean
function FBButton:new(rules, itemName, fullPath, isFile)
	FBButton.super.new(self, rules, onFBButtonClicked, itemName)
	self.fullPath = fullPath
	self.isFile = isFile
end

function FBButton:refresh()
	FBButton.super.refresh(self)
	self._offsetX = self.x + 26
end

function FBButton:draw()
	local hovering, pressing = self.hovering, self.pressing
	if pressing then
		love.graphics.setColor(0.1, 0.1, 0.2)
	elseif hovering then
		love.graphics.setColor(0.3, 0.3, 0.45)
	else
		love.graphics.setColor(0.2, 0.2, 0.35)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	if pressing then
		love.graphics.setColor(0.6, 0.6, 0.6)
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(self._textObj, self._offsetX, self._offsetY)
	if not self.isFile then
		love.graphics.draw(folderIcon, self.x + 5, self.y + 5, 0, 2, 2)
	end
	love.graphics.setColor(1, 1, 1)
end

---@class FileBrowser: PopupWindow
local FileBrowser = PopupWindow:extend()

function FileBrowser:new(rules)
	FileBrowser.super.new(self, rules, nil, "File Browser")
	---@type boolean # True if the user selected a folder or file
	self.selected = false
	---@type {[string]: boolean} # Extension filters
	self.extensionFilters = {}
	---@type boolean # If we should be applying these filters
	self.shouldApplyFilter = false

	---@type LineEdit
	local cwdLineEdit = LineEdit(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.max(26))
			:addHeight(Plan.pixel(26))
	)
	self.cwdLineEdit = cwdLineEdit
	self:addChild(cwdLineEdit)

	---@type VBox
	local fileContainer = VScroll(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(30))
			:addWidth(Plan.parent())
			:addHeight(Plan.max(64))
	)
	self.fileContainer = fileContainer
	self:addChild(fileContainer)

	---@type LineEdit
	local fileLineEdit = LineEdit(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.max(30))
			:addWidth(Plan.max(26))
			:addHeight(Plan.pixel(26))
	)
	self.fileLineEdit = fileLineEdit
	self:addChild(fileLineEdit)

	---@type string
	self.currentDirectory = love.filesystem.getUserDirectory()
	---@type FilePathProperty?
	self.property = nil
	---@type string?
	self._valueChangedAction = nil

	cwdLineEdit.textSubmitted:addAction(function(cwd)
		if cwd:byte(#cwd) ~= pathSeparatorByte then
			cwd = cwd..pathSeparator
			self.cwdLineEdit:setText(cwd)
		end
		self.currentDirectory = cwd
		self:updatePreview()
	end)
end

---Adds a filter to the file extensions
---@param extension string
function FileBrowser:addFilter(extension)
	self.extensionFilters[extension] = true
	self.shouldApplyFilter = true
end

---Binds the FileBrowser to a FilePathProperty
---@param newProperty FilePathProperty?
function FileBrowser:bindToProperty(newProperty)
	local oldProperty = self.property

	if oldProperty == newProperty then return end

	if oldProperty then
		oldProperty.valueChanged:removeAction(self._valueChangedAction)
		self._valueChangedAction = nil
	end

	self.property = newProperty
	if newProperty then
		-- The "match" gets the parent directory, if this isn't a directory itself
		local path = Path.dirsep(newProperty:get()) or love.filesystem.getUserDirectory()
		self.cwdLineEdit:setText(path)
		self.currentDirectory = path
		if self.isPoppedUp then
			self:updatePreview()
		end
		self._valueChangedAction = newProperty.valueChanged:addAction(function(property, value)
			self.currentDirectory = Path.parentdirsep(value) or love.filesystem.getUserDirectory()
			if self.isPoppedUp then
				self:updatePreview()
			end
		end)

		if newProperty.limitExtensions then
			for k, _ in pairs(newProperty.allowedExtensions) do
				self:addFilter(k)
			end
		end

		-- Set the file name
		if newProperty.pathMode ~= "directory" then
			self.fileLineEdit:setText(newProperty:getItem())
		end
	end
end

---@type {[string]: Action[]}
local possibleActions = {
	directory = {
		Action(
			"Select Folder",
			function(_, menu)
				---@cast menu FileBrowser
				menu.selected = true
				menu.property:set(menu.currentDirectory)
				return true
			end
		):setType("accept")
	},
	read = {},
	write = {
		Action(
			"Select File",
			function(_, menu)
				---@cast menu FileBrowser
				menu.selected = true
				menu.property:set(menu.property:sanitizeInput(menu.currentDirectory..menu.fileLineEdit:getText()))
				return true
			end
		):setType("accept")
	},
}

function FileBrowser:onPopup()
	self:updatePreview()

	local property = self.property
	if property then
		local pathMode = property.pathMode
		local actions = self:mergeActions({PopupWindow.DEFAULT_ACTIONS, possibleActions[pathMode]})
		self:setActions(actions, self)
	end
end

local buttonRules = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.keep())
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(26))

function FileBrowser:updatePreview()
	local cwd = self.currentDirectory
	local container = self.fileContainer
	container:clearChildren()

	local info = nativefs.getInfo(cwd, "directory")
	if info then
		-- Current directory exists
		---@type string[]
		local items = nativefs.getDirectoryItems(cwd)

		local files = {}
		local directories = {
			-- parent directory
			"../",
			cwd:match(getParentDirPattern)
		}

		local shouldFilter = self.shouldApplyFilter
		local filters = self.extensionFilters
		for _, item in ipairs(items) do
			if item:byte(1, 1) ~= 46 then
				-- Not hidden
				local fullPath = cwd..item
				local itemInfo = nativefs.getInfo(fullPath)
				if itemInfo then
					if itemInfo.type == "file" then
						if shouldFilter then
							-- Need to check the extension
							local extension = Path.ext(item)
							if extension and filters[extension] then
								-- Passed the filter
								files[#files+1] = item
								files[#files+1] = fullPath
							end
						else
							-- Don't need to check
							files[#files+1] = item
							files[#files+1] = fullPath
						end
					elseif itemInfo.type == "directory" then
						directories[#directories+1] = item..pathSeparator
						directories[#directories+1] = fullPath..pathSeparator
					end
				end
			end
		end

		-- First, add the directories
		for i = 1, #directories, 2 do
			local dir = directories[i]
			local fullPath = directories[i + 1]
			local b = FBButton(buttonRules, dir, fullPath, false)
			container:addChild(b)
		end

		-- Now add the files
		for i = 1, #files, 2 do
			local file = files[i]
			local fullPath = files[i + 1]
			local b = FBButton(buttonRules, file, fullPath, true)
			container:addChild(b)
		end
	else
		-- Current directory is invalid
		local b = FBButton(buttonRules, "Invalid directory", cwd:match(getParentDirPattern), false)
		container:addChild(b)
	end
end

function FileBrowser:_bubbleFBClicked(sourceButton, fullPath, isFile)
	local property = self.property
	if property then
		local pathMode = property.pathMode
		if not isFile and pathMode ~= "directory" then
			self.cwdLineEdit:setText(fullPath)
			self.cwdLineEdit:submitText()
		else
			self.selected = true
			property:set(fullPath)
			self:close()
		end
	end
end

local titles = {
	read = "Open File",
	write = "Write to File",
	directory = "Pick Folder"
}

function FileBrowser:popup()
	self:setTitle(titles[(self.property and self.property.pathMode) or "read"])

	FileBrowser.super.popup(self)

	self._fbContext = FileBrowserContext:asReference()
	self._fbContext["%fileBrowser"] = self
	Contexts.pushContext(self._fbContext)

end

function FileBrowser:close()
	Contexts.popContext(self._fbContext)
	FileBrowser.super.close(self)
end

return FileBrowser
