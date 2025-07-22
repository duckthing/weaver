local ffi = require "ffi"
local BlendModule = {}

---@alias BlendOperation
---| fun(destination: love.ImageData, source: love.ImageData, dx: integer, dy: integer, sx: integer, sy: integer, w: integer, h: integer)

---@param dest love.ImageData
---@param source love.ImageData
---@param dx integer
---@param dy integer
---@param sx integer
---@param sy integer
---@param sw integer
---@param sh integer
---@return integer
---@return integer
---@return integer
---@return integer
---@return integer
---@return integer
local function normalizeParams(dest, source, dx, dy, sx, sy, sw, sh)
	-- Copied from the Love2D source
	local dstW, dstH = dest:getDimensions()
	local srcW, srcH = source:getDimensions()
	if (dx < 0) then
			sw = sw + dx
			sx = sx - dx
			dx = 0
	end
	if (dy < 0) then
		sh = sh + dy
		sy = sy - dy
		dy = 0
	end
	if (sx < 0) then
		sw = sw + sx
		dx = dx - sx
		sx = 0
	end
	if (sy < 0) then
		sh = sh + sy
		dy = dy - sy
		sy = 0
	end
	if (dx + sw > dstW) then
		sw = dstW - dx
	end

	if (dy + sh > dstH) then
		sh = dstH - dy
	end

	if (sx + sw > srcW) then
		sw = srcW - sx
	end

	if (sy + sh > srcH) then
		sh = srcH - sy
	end
	return dx, dy, sx, sy, sw, sh
end

---Modifies 'target' with 'other' through normal alpha blending
---@param target love.ImageData
---@param other love.ImageData
---@param dx integer
---@param dy integer
---@param sx integer
---@param sy integer
---@param w integer
---@param h integer
function BlendModule.alphaBlend(target, other, dx, dy, sx, sy, w, h)
	local targetFFI = ffi.cast("uint8_t*", target:getFFIPointer())
	local otherFFI = ffi.cast("uint8_t*", other:getFFIPointer())

	local tw, th = target:getDimensions()
	local ow, oh = other:getDimensions()

	dx, dy, sx, sy, w, h = normalizeParams(target, other, dx, dy, sx, sy, w, h)

	-- TODO: possible issue with love2d documentation reading out of bounds?
	-- https://www.love2d.org/wiki/ImageData:mapPixel
	--print(celImageData:getSize())
	--print(4 * (width * height - 1))

	for j = 0, h - 1 do
		local ty = (dy + j) * tw
		local oy = (sy + j) * ow
		for i = 0, w - 1 do
			local tx = dx + i
			local ox = sx + i
			local tIndex = (ty + tx) * 4
			local oIndex = (oy + ox) * 4

			-- TODO: Make operations not use floats
			local otherA = otherFFI[oIndex + 3]
			if otherA == 255 then
				-- Simple copy
				targetFFI[tIndex    ] = otherFFI[oIndex    ]
				targetFFI[tIndex + 1] = otherFFI[oIndex + 1]
				targetFFI[tIndex + 2] = otherFFI[oIndex + 2]
				targetFFI[tIndex + 3] = otherA
			elseif otherA ~= 0 then
				-- Blend two colors together
				local dA = otherFFI[oIndex + 3] / 255 -- the buffer alpha (1 / 255)
				targetFFI[tIndex    ] = targetFFI[tIndex    ] * (1 - dA) + otherFFI[oIndex    ] * dA
				targetFFI[tIndex + 1] = targetFFI[tIndex + 1] * (1 - dA) + otherFFI[oIndex + 1] * dA
				targetFFI[tIndex + 2] = targetFFI[tIndex + 2] * (1 - dA) + otherFFI[oIndex + 2] * dA
				targetFFI[tIndex + 3] = targetFFI[tIndex + 3] * (1 - dA) + otherA               * dA
			end
		end
	end
end

---Pastes into 'target' with 'other'
---@param target love.ImageData
---@param other love.ImageData
---@param dx integer
---@param dy integer
---@param sx integer
---@param sy integer
---@param w integer
---@param h integer
function BlendModule.copy(target, other, dx, dy, sx, sy, w, h)
	target:paste(other, dx, dy, sx, sy, w, h)
end

---Pastes into 'target' with 'other', but only if the pixel isn't invisible
---@param target love.ImageData
---@param other love.ImageData
---@param dx integer
---@param dy integer
---@param sx integer
---@param sy integer
---@param w integer
---@param h integer
function BlendModule.copyVisible(target, other, dx, dy, sx, sy, w, h)
	local targetFFI = ffi.cast("uint8_t*", target:getFFIPointer())
	local otherFFI = ffi.cast("uint8_t*", other:getFFIPointer())

	local tw, th = target:getDimensions()
	local ow, oh = other:getDimensions()

	dx, dy, sx, sy, w, h = normalizeParams(target, other, dx, dy, sx, sy, w, h)

	for j = 0, h - 1 do
		local ty = (dy + j) * tw
		local oy = (sy + j) * ow
		for i = 0, w - 1 do
			local tx = dx + i
			local ox = sx + i
			local tIndex = (ty + tx) * 4
			local oIndex = (oy + ox) * 4

			if otherFFI[oIndex + 3] ~= 0 then
				targetFFI[tIndex    ] = otherFFI[oIndex    ]
				targetFFI[tIndex + 1] = otherFFI[oIndex + 1]
				targetFFI[tIndex + 2] = otherFFI[oIndex + 2]
				targetFFI[tIndex + 3] = otherFFI[oIndex + 3]
			end
		end
	end
end

return BlendModule
