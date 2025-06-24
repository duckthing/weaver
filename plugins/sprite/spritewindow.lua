local Plan = require "lib.plan"
local Resources = require "src.global.resources"

local PickTool = require "plugins.sprite.tools.pick"

local HSplit = require "ui.components.containers.split.hsplit"
local VSplit = require "ui.components.containers.split.vsplit"
local Canvas = require "plugins.sprite.ui.canvas"
local PaletteSidebar = require "plugins.sprite.ui.palette.palettecontainer"
local Timeline = require "plugins.sprite.ui.timeline.timelinecontainer"
local ToolDrawer = require "plugins.sprite.ui.tooldrawer"
local Inspector = require "ui.main.hinspector"
local SpriteTool = require "plugins.sprite.tools.spritetool"
local SpriteState = require "plugins.sprite.spritestate"

---@class SpriteEditor.Window: Plan.Container
local SpriteWindow = Plan.Container:extend()

---@param rules Plan.Rules
---@param editor SpriteEditor
---@param context SpriteEditor.Context
function SpriteWindow:new(rules, editor, context)
	SpriteWindow.super.new(self, rules)
	---@type SpriteEditor
	self.editor = editor
	---@type SpriteCanvas
	local canvas = Canvas(
		Plan.RuleFactory.full()
	)
	---@type PaletteContainer
	local palette = PaletteSidebar(
		Plan.RuleFactory.full()
	)
	---@type Timeline
	local timeline = Timeline(
		Plan.RuleFactory.full()
	)
	---@type ToolDrawer
	local drawer = ToolDrawer(
		Plan.RuleFactory.full()
	)
	---@type HInspector
	local inspector = Inspector(
		Plan.RuleFactory.full()
	)
	self.canvasUI = canvas
	self.paletteUI = palette
	self.timelineUI = timeline
	self.drawerUI = drawer

	canvas.minH = 40
	local hsplit1 = HSplit(Plan.RuleFactory.full(), inspector, canvas)
	hsplit1.minH = math.min(inspector.minW or 100, canvas.minW or 100)
	hsplit1.splitPosition = 40
	hsplit1.resizeMode = "keepfirst"
	local vsplit1 = VSplit(Plan.RuleFactory.full(), palette, hsplit1)
	vsplit1.splitPosition = 70
	vsplit1.resizeMode = "keepfirst"
	vsplit1.minW = math.min(palette.minW or 100, canvas.minW or 100)
	vsplit1.minH = math.min(palette.minH or 100, canvas.minH or 100)
	local vsplit2 = VSplit(Plan.RuleFactory.full(), vsplit1, drawer)
	vsplit2.splitPosition = 65
	vsplit2.resizeMode = "keepsecond"
	vsplit2.minW = math.min(vsplit1.minW or 100, drawer.minW or 100)
	vsplit2.minH = math.min(vsplit1.minH or 100, drawer.minH or 100)
	local hsplit2 = HSplit(Plan.RuleFactory.full(), vsplit2, timeline)
	hsplit2.splitPosition = -12
	hsplit2.resizeMode = "keepsecond"
	self:addChild(hsplit2)

	---@param newResource Resource
	Resources.onNewResource:addAction(function (newResource)
		-- Create the SpriteState
		if newResource.TYPE == "sprite" then
			---@cast newResource Sprite
			local state = SpriteState(newResource, context)
			newResource.spriteState = state

			canvas:onSpriteCreated(newResource)
		end
	end)

	---@param selectedResource Resource
	Resources.onResourceSelected:addAction(function (selectedResource)
		-- Load the SpriteState
		if selectedResource and selectedResource.TYPE == "sprite" then
			---@cast selectedResource Sprite
			context.sprite = selectedResource

			local state = selectedResource.spriteState
			palette:bindToProperties(selectedResource.palette, state.primaryColorSelection, state.secondaryColorSelection)
			canvas.cameraX = state.cameraX
			canvas.cameraY = state.cameraY
			canvas.imageX = state.imageX
			canvas.imageY = state.imageY
			canvas.imageW = state.imageW
			canvas.imageH = state.imageH
			canvas.scale = state.scale

			if state.spritetool then state.spritetool:selectTool() end
			SpriteTool:bindToProperties(
				selectedResource,
				state.primaryColorSelection, state.secondaryColorSelection,
				state.layer, state.frame
			)
			SpriteTool.canvas = canvas

			canvas:onSpriteSelected(selectedResource)
			timeline:onSpriteSelected(selectedResource)
		end
	end)

	---@param deselectedResource Sprite
	Resources.onResourceDeselected:addAction(function (deselectedResource)
		-- Save the SpriteState
		if deselectedResource.TYPE == "sprite" then
			if SpriteTool.drawing then
				-- Stop drawing if we are
				SpriteTool.currentTool:stopPress(SpriteTool.lastX, SpriteTool.lastY)
			end
			context.sprite = nil

			---@cast deselectedResource Sprite
			local state = deselectedResource.spriteState

			state.cameraX = canvas.cameraX
			state.cameraY = canvas.cameraY
			state.imageX = canvas.imageX
			state.imageY = canvas.imageY
			state.imageW = canvas.imageW
			state.imageH = canvas.imageH
			state.scale = canvas.scale

			state.spritetool = SpriteTool.currentTool
			SpriteTool.sprite = nil
			SpriteTool.canvas = nil

			canvas:onSpriteDeselected(deselectedResource)
			timeline:onSpriteDeselected()
		end
	end)

	PickTool.primaryColorSelected:addAction(function(r, g, b)
		palette.primaryColorSelection:findIndexAndSetColor({r, g, b})
	end)
end

function SpriteWindow:update(dt)
	-- Disable updating everything except canvas
	self.canvasUI:update(dt)
end

return SpriteWindow
