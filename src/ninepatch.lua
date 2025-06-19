---@class NinePatch
---@field widths integer[] # The widths of each split
---@field heights integer[] # The heights of each split
---@field xStartCache integer[] # Where to start rendering a quad on the X axis
---@field yStartCache integer[] # Where to start rendering a quad on the Y axis
---@field quads love.Quad[] # The quads to render
---@field texture love.Image
local NinePatch = {}
local NinePatchMT = {__index = NinePatch}

---@class NinePatchBatch
---@field batch love.SpriteBatch
---@field ninepatch NinePatch
local NinePatchBatch = {}
local NinePatchBatchMT = {__index = NinePatchBatch}

---Creates a NinePatch that can be drawn
---@param leftSize integer # The size of the left split
---@param midHSize integer # The size of the horizontal mid split
---@param rightSize integer # The size of the right split
---@param topSize integer # The size of the top split
---@param midVSize integer # The size of the vertical mid split
---@param bottomSize integer # The size of the bottom split
---@param texture love.Image # The texture to use
---@param frameCount integer? # The number of frames in the texture
---@param frameIndex integer? # The frame this quad will use
---@return NinePatch
function NinePatch.new(leftSize, midHSize, rightSize, topSize, midVSize, bottomSize, texture, frameCount, frameIndex)
	if not frameCount then
		frameCount = 1
	end

	if not frameIndex then
		frameIndex = 1
	end

	local textureSizeX, textureSizeY = texture:getDimensions()

	if textureSizeX % frameCount ~= 0 then
		-- error if the frame count will result in a fractional coordinate
		-- will occur if any frame is a different size, or if the frame count is wrong
		error("Frame count is not perfectly divisible for this texture")
	end

	local frameSizeX, frameSizeY = math.floor(textureSizeX / frameCount), textureSizeY
	local frameOffsetX, frameOffsetY = (frameIndex - 1) * frameSizeX, 0

	local widths = {leftSize, midHSize, rightSize}
	local heights = {topSize, midVSize, bottomSize}

	-- just an initialization
	---@type love.Quad[]|integer[]
	local quads = {
		0,0,0,
		0,0,0,
		0,0,0
	}

	local xStartCache = {0, leftSize, leftSize + midHSize}
	local yStartCache = {0, topSize, topSize + midVSize}

	for x = 1, 3 do
		local xStart = xStartCache[x]
		local xSize = widths[x]
		for y = 1, 3 do
			local yStart = yStartCache[y]
			local ySize = heights[y]

			quads[x + (y - 1) * 3] = love.graphics.newQuad(xStart + frameOffsetX, yStart + frameOffsetY, xSize, ySize, textureSizeX, textureSizeY)
		end
	end

	return setmetatable({
		widths = widths,
		heights = heights,
		quads = quads,
		texture = texture
	}, NinePatchMT)
end

---Draws the NinePatch
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param scale integer
function NinePatch:draw(x, y, w, h, scale)
	local texture = self.texture

	local midXScale = math.max(0, w - (self.widths[1] + self.widths[3]) * scale)
	local midYScale = math.max(0, h - (self.heights[1] + self.heights[3]) * scale)
	local lastXPos = (self.widths[1] * scale) + self.widths[2] * midXScale
	local lastYPos = (self.heights[1] * scale) + self.heights[2] * midYScale

	for i, quad in ipairs(self.quads) do
		local xIndex = (i - 1) % 3 + 1
		local yIndex = math.ceil(i / 3)

		local xScale, yScale = scale, scale
		local xPos = 0
		local yPos = 0

		if xIndex == 2 then
			xPos = self.widths[1] * scale
			xScale = midXScale
		elseif xIndex == 3 then
			xPos = lastXPos
		end

		if yIndex == 2 then
			yPos = self.heights[1] * scale
			yScale = midYScale
		elseif yIndex == 3 then
			yPos = lastYPos
		end

		love.graphics.draw(texture, quad, x + xPos, y + yPos, 0, xScale, yScale)
	end
end

---Creates a NinePatchBatch, which wraps around SpriteBatch
---and NinePatch
---@param maxSprites integer?
---@param usage love.SpriteBatchUsage
---@return NinePatchBatch
function NinePatch:newSpriteBatch(maxSprites, usage)
	---@class NinePatchBatch
	return setmetatable({
		batch = love.graphics.newSpriteBatch(self.texture, maxSprites, usage),
		ninepatch= self
	}, NinePatchBatchMT)
end


---Adds a frame to the NinePatchBatch
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param scale integer
function NinePatchBatch:add(x, y, w, h, scale)
	local np = self.ninepatch
	local batch = self.batch
	local texture = np.texture

	local midXScale = math.max(0, w - (np.widths[1] + np.widths[3]) * scale)
	local midYScale = math.max(0, h - (np.heights[1] + np.heights[3]) * scale)
	local lastXPos = (np.widths[1] * scale) + np.widths[2] * midXScale
	local lastYPos = (np.heights[1] * scale) + np.heights[2] * midYScale

	for i, quad in ipairs(np.quads) do
		local xIndex = (i - 1) % 3 + 1
		local yIndex = math.ceil(i / 3)

		local xScale, yScale = scale, scale
		local xPos = 0
		local yPos = 0

		if xIndex == 2 then
			xPos = np.widths[1] * scale
			xScale = midXScale
		elseif xIndex == 3 then
			xPos = lastXPos
		end

		if yIndex == 2 then
			yPos = np.heights[1] * scale
			yScale = midYScale
		elseif yIndex == 3 then
			yPos = lastYPos
		end

		batch:add(quad, x + xPos, y + yPos, 0, xScale, yScale)
	end
end

---Clears the SpriteBatch
function NinePatchBatch:clear()
	self.batch:clear()
end

---Sets the color of the next draw
---@param r number?
---@param g number?
---@param b number?
---@param a number?
function NinePatchBatch:setColor(r, g, b, a)
	---@diagnostic disable-next-line
	self.batch:setColor(r, g, b, a)
end

---Sets the values at a specific index in the SpriteBatch.
---The spriteIndex takes into account the other quads.
---@param spriteIndex integer
---@param x number
---@param y number
---@param w integer
---@param h integer
---@param scale integer
function NinePatchBatch:set(spriteIndex, x, y, w, h, scale)
	local np = self.ninepatch
	local batch = self.batch
	local texture = np.texture

	local midXScale = math.max(0, w - (np.widths[1] + np.widths[3]) * scale)
	local midYScale = math.max(0, h - (np.heights[1] + np.heights[3]) * scale)
	local lastXPos = (np.widths[1] * scale) + np.widths[2] * midXScale
	local lastYPos = (np.heights[1] * scale) + np.heights[2] * midYScale

	local startIndex = spriteIndex * 9 - 1

	for i, quad in ipairs(np.quads) do
		local xIndex = (i - 1) % 3 + 1
		local yIndex = math.ceil(i / 3)

		local xScale, yScale = scale, scale
		local xPos = 0
		local yPos = 0

		if xIndex == 2 then
			xPos = np.widths[1] * scale
			xScale = midXScale
		elseif xIndex == 3 then
			xPos = lastXPos
		end

		if yIndex == 2 then
			yPos = np.heights[1] * scale
			yScale = midYScale
		elseif yIndex == 3 then
			yPos = lastYPos
		end

		batch:set(startIndex + i, quad, x + xPos, y + yPos, 0, xScale, yScale)
	end
end

---Draws the NinePatchBatch
---@param x number
---@param y number
---@param scaleX number?
---@param scaleY number?
function NinePatchBatch:draw(x, y, scaleX, scaleY)
	love.graphics.draw(self.batch, x, y, 0, scaleX or 1, scaleY or 1)
end

return NinePatch
