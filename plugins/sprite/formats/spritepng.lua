local ffi = require "ffi"
local nativefs = require "lib.nativefs"
local Path = require "lib.path"
local Serpent = require "lib.serpent"
local json = require "lib.json"
local Blend = require "plugins.sprite.common.blend"
local Status = require "src.global.status"

local isWindows = love.system.getOS() == "Windows"

local SpritePngFormat = {}
local SpriteBuffer

function SpritePngFormat.setSprite(type)
	SpriteBuffer = type
end

function SpritePngFormat:import(path, file, options)
	---@type string
	local name = Path.file(path) -- sprite.png

	file:open("r")
	local data = file:read("data", file:getSize())

	if data then
		local image = love.image.newImageData(data)
		local rows, columns = options.rows:get(), options.columns:get()
		local dataWidth, dataHeight = image:getDimensions()

		local width, height =
			dataWidth / columns,
			dataHeight / rows

		if width % 1 ~= 0 or height % 1 ~= 0 then
			Status.pushTemporaryMessage("Row/column parameters are not divisible by the image dimensions", "error", 5)
			return
		end
		width, height =
			math.floor(width),
			math.floor(height)

		---@type Sprite
		local buffer = SpriteBuffer(width, height)
		buffer.name:set(name)
		buffer:getSaveTemplate().path:set(Path.parentdirsep(path)..name..".wgf")

		local frames = rows * columns
		local imagePointer = ffi.cast("uint8_t*", image:getFFIPointer())
		local layer = buffer.layers[1]

		-- 1 frame exists by default, create #layers - 1
		for _ = 2, frames do buffer:createFrame() end

		for i = 1, frames do
			local cel, celIndex = buffer:createCel()
			layer.celIndices[i] = celIndex
			local celPointer = ffi.cast("uint8_t*", cel.data:getFFIPointer())

			local currCol = ((i - 1) % columns) + 1
			local currRow = math.floor((i - 1) / columns) + 1
			-- The top left pixel
			local imageX, imageY =
				(currCol - 1) * width,
				(currRow - 1) * height
			local frameIndex = (imageX + imageY * dataWidth) * 4

			for x = 0, width - 1 do
				for y = 0, height - 1 do
					local celPIndex = (x + y * width) * 4
					local dataIndex = frameIndex + (x + y * dataWidth) * 4

					celPointer[celPIndex    ] = imagePointer[dataIndex    ]
					celPointer[celPIndex + 1] = imagePointer[dataIndex + 1]
					celPointer[celPIndex + 2] = imagePointer[dataIndex + 2]
					celPointer[celPIndex + 3] = imagePointer[dataIndex + 3]
				end
			end

			cel.image:release()
			cel.image = love.graphics.newImage(cel.data)
		end

		-- Update the exporter info
		local exporter = buffer.exporter
		exporter.rows:set(rows)
		exporter.imagePath:set(path)
		exporter.alreadyExported = true

		return true, buffer
	end
end

local serpentOptions = {
	nocode = true,
	nohuge = true,
	comment = false
}

---@param sprite Resource
---@param options table
---@return boolean success
function SpritePngFormat:export(sprite, options)
	local scale = (options and options.scale) or 1
	local rows = (options and options.rows) or 1

	-- Check if it's a sprite
	if not (sprite and sprite.TYPE == "sprite") then print("Not a sprite") return false end
	---@cast sprite Sprite

	local width, height, frames =
		sprite.width * scale,
		sprite.height * scale,
		#sprite.frames

	local columns = math.ceil(frames / rows)
	local dataWidth, dataHeight = width * columns, height * rows

	if options.imagePath then
		-- PNG export
		local imagePath = options.imagePath
		local targetInfo = nativefs.getInfo(imagePath)
		local valid = targetInfo == nil or targetInfo.type == "file"

		if not valid then
			Status.pushTemporaryMessage(("Error target image path: %s (Can we write there?)"):format(imagePath), "error", 10)
			return false
		end
		-- Either empty or a file
		local file, err = nativefs.newFile(imagePath)
		if not file or not file:open("w") then
			Status.pushTemporaryMessage(("Error exporting image: %s"):format(err), "error", 10)
			return false
		end

		-- Now we export
		local exportedID = love.image.newImageData(dataWidth, dataHeight)

		-- This is where we put the scaled up pixels, if the scale isn't 1
		---@type love.ImageData
		local bufferID
		if scale ~= 1 then
			bufferID = love.image.newImageData(dataWidth, dataHeight)
		end

		for i = 1, frames do
			local currCol = ((i - 1) % columns) + 1
			local currRow = math.floor((i - 1) / columns) + 1
			-- The top left pixel
			local imageX, imageY =
				(currCol - 1) * width,
				(currRow - 1) * height

			for _, layer in ipairs(sprite.layers) do
				if layer.visible then
					local celIndex = layer.celIndices[i]
					if celIndex ~= 0 then
						local cel = sprite.cels[celIndex]

						if scale == 1 then
							-- Scale is 1, use the cel data directly
							Blend.copyVisible(exportedID, cel.data, imageX, imageY, 0, 0, width, height)
						else
							-- Scale isn't 1, scale up the data
							local exportedP = ffi.cast("uint8_t*", exportedID:getFFIPointer())
							local bufferP = ffi.cast("uint8_t*", bufferID:getFFIPointer())
							local celP = ffi.cast("uint8_t*", cel.data:getFFIPointer())

							for x = 0, sprite.width - 1 do
								for y = 0, sprite.height - 1 do
									local scaledIndex = (x + y * width) * scale * 4
									local unscaledIndex = (x + y * sprite.width) * 4

									for j = 0, scale - 1 do
										for k = 0, scale - 1 do
											-- (x, y): unscaled coordinates
											-- (x * scale + j, y * scale + k): scaled
											local newIndex = scaledIndex + (j + k * width) * 4

											bufferP[newIndex    ] = celP[unscaledIndex    ]
											bufferP[newIndex + 1] = celP[unscaledIndex + 1]
											bufferP[newIndex + 2] = celP[unscaledIndex + 2]
											bufferP[newIndex + 3] = celP[unscaledIndex + 3]
										end
									end
								end
							end

							Blend.copyVisible(exportedID, bufferID, imageX, imageY, 0, 0, width, height)
						end
					end
				end
			end
		end

		local filedata = exportedID:encode("png")
		file:write(filedata)
		exportedID:release()
		filedata:release()
		if bufferID then bufferID:release() end
		file:close()
	end

	if options.dataPath then
		-- Export the animation info
		local data = {
			spriteW = width,
			spriteH = height,
			imageW = dataWidth,
			imageH = dataHeight,
			frames = {},
			tags = {},
		}
		---@type string
		local dataPath = options.dataPath
		local extension = Path.ext(dataPath)
		if extension ~= "json" and extension ~= "lua" then print("Invalid data extension: ", extension) return false end

		-- Insert all the frame information
		for i = 1, frames do
			local currCol = ((i - 1) % columns) + 1
			local currRow = math.floor((i - 1) / columns) + 1
			-- The top left pixel
			local imageX, imageY =
				(currCol - 1) * width,
				(currRow - 1) * height

			data.frames[#data.frames+1] = {
				x = imageX,
				y = imageY,
				w = width,
				h = height,
				duration = sprite.frames[i].duration:get()
			}
		end

		local targetInfo = nativefs.getInfo(dataPath)
		local valid = targetInfo == nil or targetInfo.type == "file"

		if not valid then
			Status.pushTemporaryMessage(("Error target data path: %s (Can we write there?)"):format(dataPath), "error", 10)
			return false
		end

		-- Either empty or a file
		local file, err = nativefs.newFile(dataPath)
		if not file or not file:open("w") then
			Status.pushTemporaryMessage(("Error exporting image: %s"):format(err), "error", 10)
			return false
		end

		-- Write the data
		---@type string
		local encoded
		if extension == "json" then
			encoded = json.encode(data)
		elseif extension == "lua" then
			encoded = Serpent.block(data, serpentOptions)
			file:write("return ")
		end
		file:write(encoded)

		file:close()
	end

	-- At this point, both have been written.
	local editedImagePath = options.imagePath
	local editedDataPath = options.dataPath

	if not isWindows then
		-- Replace home directory with ~
		local homeDir = love.filesystem.getUserDirectory()
		editedImagePath = (options.imagePath and options.imagePath:gsub(homeDir, "~/")) or nil
		editedDataPath = (options.dataPath and options.dataPath:gsub(homeDir, "~/")) or nil
	end

	if editedImagePath and editedDataPath then
		Status.pushTemporaryMessage(("Exported: %s, %s"):format(editedImagePath, editedDataPath))
	elseif editedImagePath or editedDataPath then
		Status.pushTemporaryMessage(("Exported: %s"):format(editedImagePath or editedDataPath))
	end

	return true
end

return SpritePngFormat
