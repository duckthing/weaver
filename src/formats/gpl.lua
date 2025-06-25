local Path = require "lib.path"
local Format = require "src.data.format"
local Palette = require "src.data.palette"
local Palettes = require "src.global.palettes"

local MAGIC_NUMBER = "GIMP Palette"
-- a little over 4 kilobytes
local MAX_FILE_SIZE = 32768
local NAME_PREFIX = "Name: "

---@class GplFormat: Format
local GplFormat = Format:extend()
GplFormat.FORMAT_NAME = "GplPaletteFormat"
GplFormat.IMPORT_EXTENSIONS = {"gpl"}
GplFormat.EXPORT_FOR_TYPES = {Palette}

function GplFormat:import(path, file)
	-- Check if this is a valid GPL file
	-- Also check if it isn't too big

	---@type fun(): string
	local lineIter = file:lines()
	do
		if file:getSize() > MAX_FILE_SIZE then
			return false, "File too large to parse"
		end

		local content = lineIter()
		if content ~= MAGIC_NUMBER then
			return false, "Invalid GPL magic number"
		end
	end

	-- Get the name of this palette
	local palette = Palette()
	do
		local lineName = lineIter()
		if lineName then
			if lineName:sub(1, #NAME_PREFIX) == NAME_PREFIX then
				palette.name = lineName:sub(#NAME_PREFIX + 1)
			else
				palette.name = "Unnamed GPL Palette"
			end
		end
	end

	-- Append new colors onto the palette
	local colors = palette.colors

	-- Now, do the parsing
	for line in lineIter do
		-- Stop if this line is a comment
		if line:sub(1, 1) == "#" then goto continue end

		local color = {0., 0., 0.}

		-- TODO: Make sure these numbers are before a comment
		local i = 0
		for match in line:gmatch("%-?%d+") do
			i = i + 1
			color[i] = tonumber(match)

			-- Stop after getting the third channel value
			if i == 3 then
				break
			end
		end

		if i == 3 then
			-- This line had all required channels
			color[1], color[2], color[3] =
				love.math.colorFromBytes(color[1], color[2], color[3])
			colors[#colors+1] = color
		end

		::continue::
	end

	return true, palette
end

---@param palette Palette
---@param path string
---@param file love.File
function GplFormat:export(palette, path, file)
	palette.name = Path.nameext(path)

	file:write(MAGIC_NUMBER)
	file:write(("\nName: %s"):format(palette.name))

	for i = 1, #palette.colors do
		local color = palette.colors[i]
		file:write(
			("\n%d %d %d"):format(
				love.math.colorToBytes(color[1], color[2], color[3])
			)
		)
	end

	return true
end

---@param path string
---@param palette Palette
function GplFormat:handleImportSuccess(path, palette)
	Palettes.globalPalettes[#Palettes.globalPalettes+1] = palette
end

return GplFormat
