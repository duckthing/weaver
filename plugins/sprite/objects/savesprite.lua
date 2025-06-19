local Modal = require "src.global.modal"
local SaveTemplate = require "src.objects.savetemplate"
local WgfFormat = require "src.formats.wgf"
local SpriteTool = require "plugins.sprite.tools.spritetool"

---@class SaveSprite: SaveTemplate
local SaveSprite = SaveTemplate:extend()
SaveSprite.saveType = "sprite"

local isWindows = love.system.getOS() == "Windows"

function SaveSprite:new(resource)
	SaveSprite.super.new(self, resource)
	self.path:addFilter("wgf")
end

function SaveSprite:present()
	local fb = Modal.pushFileBrowser(self.path)
	local oldOnClose = fb.onClose
	fb.onClose = function()
		oldOnClose(fb)
		if fb.selected then
			self:handleSave()
		end
	end
end

function SaveSprite:save(resource, path)
	---@cast resource Sprite
	local command = SpriteTool.applyFromSelection()

	local success, err = WgfFormat:export(resource, path)

	return success, err
end

function SaveSprite:onSaveResult(success, err, resource, path, formattedPath)
	if success then
		-- Saved
		resource.name:set(self.path:getItem())
		resource.lastSavedIndex = resource.undoStack.index + resource.undoStack.totalShifted
	end
end

return SaveSprite
