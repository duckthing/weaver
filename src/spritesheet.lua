---@class SpriteSheet
---@field quads love.Quad[]
---@field texture love.Image
---@field frameSizeX integer
---@field frameSizeY integer
local SpriteSheet = {}
local SpriteSheetMT = {__index = SpriteSheet}

---@class SpriteSheetBatch
---@field batch love.SpriteBatch
---@field spritesheet SpriteSheet
local SpriteSheetBatch = {}
local SpriteSheetBatchMT = {__index = SpriteSheetBatch}

---Creates a spritesheet that can be drawn
---@param texture love.Image
---@param columns integer
---@param rows integer
---@return SpriteSheet
function SpriteSheet.new(texture, columns, rows)
	local textureX, textureY = texture:getDimensions()

	if textureX % columns ~= 0 or textureY % rows ~= 0 then
		error("Spritesheet is not evenly divisble by parameters.")
	end

	local frameSizeX, frameSizeY = textureX / columns, textureY / rows

	---@type love.Quad[]
	local quads = {}
	for x = 1, columns do
		local columnOffsetX = (x - 1) * frameSizeX
		for y = 1, rows do
			quads[#quads+1] = love.graphics.newQuad(columnOffsetX, (y - 1) * frameSizeY, frameSizeX, frameSizeY, textureX, textureY)
		end
	end

	return setmetatable({
			quads = quads,
			texture = texture,
			frameSizeX = frameSizeX,
			frameSizeY = frameSizeY,
		},
		SpriteSheetMT
	)
end

---Draws the spritesheet with the frame
---@param self SpriteSheet
---@param frame integer
---@param x integer
---@param y integer
---@param scaleX integer
---@param scaleY integer
function SpriteSheet:draw(frame, x, y, scaleX, scaleY)
	local quad = self.quads[frame]
	local texture = self.texture

	love.graphics.draw(texture, quad, x, y, 0, scaleX or 1, scaleY or 1)
end

---Creates a SpriteSheetBatch, which wraps around SpriteBatch
---and SpriteSheet
---@param maxSprites integer?
---@param usage love.SpriteBatchUsage
---@return SpriteSheetBatch
function SpriteSheet:newSpriteBatch(maxSprites, usage)
	---@class SpriteSheetBatch
	return setmetatable({
		batch = love.graphics.newSpriteBatch(self.texture, maxSprites, usage),
		spritesheet = self
	}, SpriteSheetBatchMT)
end

---Adds a frame to the SpriteSheetBatch
---@param frame integer
---@param x integer
---@param y integer
---@param scaleX integer?
---@param scaleY integer?
function SpriteSheetBatch:add(frame, x, y, scaleX, scaleY)
	local quad = self.spritesheet.quads[frame]
	local batch = self.batch
	batch:add(quad, x, y, 0, scaleX or 1, scaleY or 1)
end

---Clears the SpriteBatch
function SpriteSheetBatch:clear()
	self.batch:clear()
end

---Sets the color of the next draw
---@param r number?
---@param g number?
---@param b number?
---@param a number?
function SpriteSheetBatch:setColor(r, g, b, a)
	---@diagnostic disable-next-line
	self.batch:setColor(r, g, b, a)
end

---Draws the SpriteSheetBatch
---@param x number
---@param y number
---@param scaleX number?
---@param scaleY number?
function SpriteSheetBatch:draw(x, y, scaleX, scaleY)
	love.graphics.draw(self.batch, x, y, 0, scaleX or 1, scaleY or 1)
end

---Sets the values at a specific index in the SpriteBatch
---@param spriteIndex integer
---@param x number
---@param y number
---@param scaleX number?
---@param scaleY number?
function SpriteSheetBatch:set(spriteIndex, x, y, scaleX, scaleY)
	self.batch:set(spriteIndex, x, y, 0, scaleX or 1, scaleY or 1)
end

return SpriteSheet
