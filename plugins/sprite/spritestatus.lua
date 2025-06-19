local Plan = require "lib.plan"
local Status = require "src.global.status"
local CanvasPos = require "plugins.sprite.status.canvaspos"
local CanvasZoom = require "plugins.sprite.status.canvaszoom"
local ColorSelect = require "plugins.sprite.status.colorselect"
local SpriteName = require "plugins.sprite.status.spritename"
local HBox = require "ui.components.containers.box.hbox"

---@class SpriteStatus: StatusContext
local SpriteStatus = Status.StatusContext:extend()

function SpriteStatus:new()
	---@diagnostic disable-next-line
	SpriteStatus.super.new(self)
	---@type HBox
	self.leftHBox = HBox(Plan.RuleFactory.full())
	self.leftHBox.padding = 8
	self.leftHBox.margin = 8
	-- self.leftHBox.direction = "last"
	---@type HBox
	self.rightHBox = HBox(Plan.RuleFactory.full())
	self.rightHBox.padding = 8
	self.rightHBox.margin = 8
	self.rightHBox.direction = "last"
	---@type SpriteEditor
	self.editor = nil
	---@type Label
	self.namelabel = SpriteName(
		Plan.RuleFactory.keepSize()
			:addX(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.parent())
	)
	---@type SpriteStatus.CanvasPos
	self.canvaspos = CanvasPos(
		Plan.RuleFactory.keepSize()
			:addX(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.parent())
	)
	---@type SpriteStatus.CanvasZoom
	self.canvaszoom = CanvasZoom(
		Plan.RuleFactory.keepSize()
			:addX(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.parent())
	)
	---@type SpriteStatus.ColorSelect
	self.colorselect = ColorSelect(
		Plan.RuleFactory.keepSize()
			:addX(Plan.keep())
			:addWidth(Plan.content())
			:addHeight(Plan.parent())
	)
	self:addChild(self.leftHBox)
	self:addChild(self.rightHBox)
	self.leftHBox:addChild(self.namelabel)
	self.leftHBox:addChild(self.canvaspos)
	self.leftHBox:addChild(self.colorselect)
	self.rightHBox:addChild(self.canvaszoom)
end

---Sets the SpriteEditor
---@param spriteEditor SpriteEditor
function SpriteStatus:setEditor(spriteEditor)
	self.editor = spriteEditor
	self:emit("setEditor", spriteEditor)
end

function SpriteStatus:draw()
	self:emit("update")
	SpriteStatus.super.draw(self)
end

return SpriteStatus
