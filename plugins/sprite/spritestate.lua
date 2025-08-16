local SpriteTool = require "plugins.sprite.tools.spritetool"
local Bitmask = require "plugins.sprite.data.bitmask"
local ColorRamp = require "plugins.sprite.data.colorramp"

local Inspectable = require "src.properties.inspectable"
local BoolProperty = require "src.properties.bool"
local IntegerProperty = require "src.properties.integer"
local ColorSelectionProperty = require "src.properties.colorselection"
local EnumProperty = require "src.properties.enum"
local GridOptions = require "plugins.sprite.objects.gridoptions"

---@class SpriteState: Inspectable
local SpriteState = Inspectable:extend()

local PRIMARY_DEFAULT_COLOR = {0, 0, 0}
local SECONDARY_DEFAULT_COLOR = {1, 1, 1}

---@param sprite Sprite
---@param context SpriteEditor.Context
function SpriteState:new(sprite, context)
	---@type SpriteEditor.Context
	self.context = context
	self.sprite = sprite

	local palette = sprite.palette:get()
	---@type ColorSelectionProperty
	self.primaryColorSelection = ColorSelectionProperty(self, "Primary Color", PRIMARY_DEFAULT_COLOR)
	self.primaryColorSelection:setDefaultIndex(1)
	self.primaryColorSelection:setPalette(palette)
	---@type ColorSelectionProperty
	self.secondaryColorSelection = ColorSelectionProperty(self, "Secondary Color", SECONDARY_DEFAULT_COLOR)
	self.secondaryColorSelection:setDefaultIndex(2)
	self.secondaryColorSelection:setPalette(palette)

	---@type love.PixelFormat
	self.format = sprite.format

	---@type love.Canvas # A canvas that can be rendered to temporarily, but is separate from the image
	self.mimicCanvas = love.graphics.newCanvas(sprite.width, sprite.height)
	self.mimicCanvas:setWrap("clampzero", "clampzero")

	-- Used for drawing, before copying to the final cel
	self.drawCel = sprite:createInternalCel()
	-- Where moved selections are put before copied to the final cel
	self.selectionCel = sprite:createInternalCel()
	---@type boolean # Whether the buffer should be drawn, too
	self.includeDrawBuffer = false
	---@type boolean # Whether the selection contents should be drawn, too
	self.includeSelection = false
	---@type boolean # Whether the bitmask should be drawn, too
	self.includeBitmask = false
	---@type boolean # Whether the mimic canvas should be drawn, too
	self.includeMimic = false
	---@type boolean # Whether the mimic canvas should have a selection outline
	self.includeMimicOutline = false

	---@type string[] # For the ResizeCommand to know to modify these
	self.internalCelNames = {
		"drawCel",
		"selectionCel"
	}

	---@type number
	self.cameraX = 0.
	---@type number
	self.cameraY = 0.
	---@type number
	self.scale = 1.
	self.imageW = sprite.width
	self.imageH = sprite.height
	self.imageX = sprite.width * -0.5
	self.imageY = sprite.height * -0.5

	---@type integer, integer # For moving selections, added on top of other offsets
	self.selectionX, self.selectionY = 0, 0
	---@type number, number
	self.selectionScaleX, self.selectionScaleY = 1, 1
	---@type number
	self.selectionRotation = 0
	---@type integer, integer # For moving selections, added on top of other offsets
	self.selectionOriginX, self.selectionOriginY = 0, 0

	---@type Bitmask
	self.bitmask = Bitmask.new(sprite.width, sprite.height)
	---@type Bitmask.Renderer
	self.bitmaskRenderer = self.bitmask:newRenderer()

	---@type SpriteTool
	self.spritetool = SpriteTool.currentTool or SpriteTool.spriteTools[1]
	---@type IntegerProperty
	self.frame = IntegerProperty(self, "Frame", 1)
	---@type IntegerProperty
	self.layer = IntegerProperty(self, "Layer", 1)

	---@type EnumProperty.Option[]
	local animOptions = {
		{
			value = nil,
			name = "None"
		},
	}

	---@type EnumProperty
	self.currentAnimation = EnumProperty(self, "Animation", nil)
	self.currentAnimation:setOptions(animOptions)

	---@type ColorRamp
	self.colorRamp = ColorRamp()

	---@type GridOptions
	self.gridOptions = GridOptions()

	local function updateFrameBounds()
		self.frame.range:setMax(#sprite.frames)
		if SpriteTool.sprite == sprite then
			SpriteTool:selectFrame(self.frame:get())
		end
	end

	local function updateLayerBounds()
		local oldValue = self.layer:get()
		self.layer:getRange().value = -1

		self.layer.range:setMax(#sprite.layers)
		self.layer:set(oldValue)
		if SpriteTool.sprite == sprite then
			SpriteTool:selectLayer(self.layer:get())
		end
	end

	updateFrameBounds()
	updateLayerBounds()
	self.frame.range:setMin(1)
	self.layer.range:setMin(1)
	sprite.layerInserted:addAction(updateLayerBounds)
	sprite.layerRemoved:addAction(updateLayerBounds)
	sprite.frameInserted:addAction(updateFrameBounds)
	sprite.frameRemoved:addAction(updateFrameBounds)

	sprite.spriteResized:addAction(function(newW, newH)
		self.imageX = newW * -0.5
		self.imageY = newH * -0.5

		-- This occurs in ResizeCommand
		-- self.bitmask:resize(newW, newH)
		-- self.bitmaskRenderer:update()

		self.mimicCanvas:release()
		self.mimicCanvas = love.graphics.newCanvas(newW, newH)
	end)

	sprite.palette.valueChanged:addAction(function(property, value)
		self.primaryColorSelection:setPalette(value)
		self.secondaryColorSelection:setPalette(value)
	end)

	sprite.animationInserted:addAction(function(s, animation, index)
		table.insert(animOptions, index + 1, {
			name = animation.name:get(),
			value = animation
		})

		self.currentAnimation:setIndex(index + 1)
	end)

	sprite.animationRemoved:addAction(function(s, animation, index)
		table.remove(animOptions, index + 1)

		self.currentAnimation:setIndex(index + 1)
	end)
end

---Returns the Sprite.Cel and cel index associated with the layer and frame set in the sprite state
---@return Sprite.Cel
---@return integer
function SpriteState:getCurrentCel()
	local sprite = self.sprite
	local celIndex = sprite.layers[self.layer:get()].celIndices[self.frame:get()]
	return sprite.cels[celIndex], celIndex
end

return SpriteState
