local Plan = require "lib.plan"
local VScroll = require "ui.components.containers.box.vscroll"
local IconButton = require "ui.components.button.iconbutton"
local SpriteSheet = require "src.spritesheet"

local PencilTool = require "plugins.sprite.tools.pencil"
local EraserTool = require "plugins.sprite.tools.eraser"
local BucketTool = require "plugins.sprite.tools.bucket"
local PickTool = require "plugins.sprite.tools.pick"
local RectMarqueeTool = require "plugins.sprite.tools.rectmarquee"
local MagicMarqueeTool = require "plugins.sprite.tools.magicmarquee"
local SelectionTransformTool = require "plugins.sprite.tools.selectiontransform"

PencilTool:register()
EraserTool:register()
BucketTool:register()
PickTool:register()
RectMarqueeTool:register()
MagicMarqueeTool:register()
SelectionTransformTool:register()

local toolsTexture = love.graphics.newImage("assets/sprite_tools.png")
toolsTexture:setFilter("nearest", "nearest")
local toolSpriteSheet = SpriteSheet.new(toolsTexture, 7, 1)

---@class ToolDrawer: VScroll
local ToolDrawer = VScroll:extend()

-- TODO: Offset drag handle so that we don't have to add an offset
local buttonRules = Plan.Rules.new()
	:addX(Plan.pixel(5))
	:addY(Plan.keep())
	:addWidth(Plan.max(5))
	:addHeight(Plan.pixel(30))

function ToolDrawer:new(rules)
	ToolDrawer.super.new(self, rules)
	self.minW = 35

	local pencilBtn = IconButton(buttonRules, function() PencilTool:selectTool() end, toolSpriteSheet, 1, 2)
	local eraserBtn = IconButton(buttonRules, function() EraserTool:selectTool() end, toolSpriteSheet, 2, 2)
	local bucketBtn = IconButton(buttonRules, function() BucketTool:selectTool() end, toolSpriteSheet, 3, 2)
	local pickBtn = IconButton(buttonRules, function() PickTool:selectTool() end, toolSpriteSheet, 4, 2)
	local rectMarqueeBtn = IconButton(buttonRules, function() RectMarqueeTool:selectTool() end, toolSpriteSheet, 5, 2)
	local magicMarqueeBtn = IconButton(buttonRules, function() MagicMarqueeTool:selectTool() end, toolSpriteSheet, 6, 2)
	local selectionTransformBtn = IconButton(buttonRules, function() SelectionTransformTool:selectTool() end, toolSpriteSheet, 6, 2)

	self:addChild(pencilBtn)
	self:addChild(eraserBtn)
	self:addChild(bucketBtn)
	self:addChild(pickBtn)
	self:addChild(rectMarqueeBtn)
	self:addChild(magicMarqueeBtn)
	self:addChild(selectionTransformBtn)
end

function ToolDrawer:draw()
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	ToolDrawer.super.draw(self)
end

return ToolDrawer
