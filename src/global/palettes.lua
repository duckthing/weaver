local nativefs = require "lib.nativefs"
local Palette = require "src.data.palette"
local Handler = require "src.global.handler"
local GlobalConfig = require "src.global.config"

local PalettesModule = {}

---@type string[]
PalettesModule.paletteDirectories = {
	love.filesystem.getSaveDirectory().."/palettes/"
}

if GlobalConfig.firstLaunch then
	love.filesystem.createDirectory("/palettes")
end

---@type Palette[]
PalettesModule.globalPalettes = {}

function PalettesModule.reloadPalettes()
	-- Clear the global palettes
	local palettes = PalettesModule.globalPalettes
	for i = #palettes, 1, -1 do
		palettes[i] = nil
	end

	-- Check all default palette directories
	for _, directory in ipairs(PalettesModule.paletteDirectories) do
		local dirInfo = nativefs.getInfo(directory, "directory")
		if dirInfo then
			-- If it's a directory, check it
			local dirItems = nativefs.getDirectoryItems(directory)
			if dirItems then
				for _, filePath in ipairs(dirItems) do
					local success, err = Handler.importAndHandle(directory..filePath)
					if not success then print(err) end
				end
			end
		else
			-- Not a valid directory, warn about it
			print("[WARN] PalettesModule (palettes.lua) could not open directory: "..directory)
		end
	end

	-- Create a default one, just in case
	if #palettes == 0 then
		local palette = Palette()
		palette.colors[1], palette.colors[2] = {0, 0, 0}, {1, 1, 1}
		palettes[1] = palette
	end
end

return PalettesModule
