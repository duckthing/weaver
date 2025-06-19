local Fonts = {}

Fonts.defaultFont = "pixeloid"

---@type {[string]: string}
Fonts.fontPaths = {
	["pixeloid"] = "assets/fonts/pixeloid/PixeloidSans.ttf",
}

Fonts.defaultFontSize = 14

---Returns an already existing font of the specified size.
---
---Don't touch.
---@type {[string]: {[integer]: love.Font}}
Fonts.loadedFonts = setmetatable({
	normal = setmetatable({}, {
		__index = function (selffont, j)
			-- j is the font size
			if not rawget(selffont, j) then
				rawset(selffont, j, love.graphics.newFont(j))
			end
			return selffont[j]
		end
	})
}, {
	__index = function(self, i)
		if not rawget(self, i) then
			rawset(self, i, setmetatable({}, {
				__index = function (selffont, j)
					-- j is the font size
					if not rawget(selffont, j) then
						rawset(selffont, j, love.graphics.newFont(Fonts.fontPaths[i], j, "light"))
					end
					return selffont[j]
				end
			}))
		end

		return self[i]
	end
})

---@param fontSize integer?
function Fonts.getDefaultFont(fontSize)
	return Fonts.loadedFonts[Fonts.defaultFont][fontSize or Fonts.defaultFontSize]
end

return Fonts
