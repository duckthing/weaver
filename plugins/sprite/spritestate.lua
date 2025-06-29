local SpriteTool = require "plugins.sprite.tools.spritetool"
local Bitmask = require "plugins.sprite.data.bitmask"

local Inspectable = require "src.properties.inspectable"
local IntegerProperty = require "src.properties.integer"
local ColorSelectionProperty = require "src.properties.colorselection"
local EnumProperty = require "src.properties.enum"

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

	-- Used for drawing, before copying to the final cel
	self.drawCel = sprite:createInternalCel()
	-- Where moved selections are put before copied to the final cel
	self.selectionCel = sprite:createInternalCel()
	---@type boolean # Whether the buffer should be drawn, too
	self.includeDrawBuffer = false
	---@type boolean # Whether the selection should be drawn, too
	self.includeSelection = false
	---@type boolean # Whether the mimic canvas should be drawn, too
	self.includeMimic = false

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
	---@type EnumProperty
	self.currentAnimation = EnumProperty(self, "Animation", nil)
	self.currentAnimation:setOptions({
		{
			value = nil,
			name = "All",
		},
	})

	local function updateFrameBounds()
		self.frame.range:setMax(#sprite.frames)
	end

	local function updateLayerBounds()
		self.layer.range:setMax(#sprite.layers)
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
