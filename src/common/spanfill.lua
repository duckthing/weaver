---Runs the span fill algorithm. Imagine a 4-way bucket fill with this.
---
---The 'inside' function should return a boolean on whether a point is 'inside'. The start position should be inside.
---The 'set' function will make this point no longer 'inside'.
---@param startX integer
---@param startY integer
---@param inside fun(x: integer, y: integer): boolean
---@param set fun(x: integer, y: integer)
local function spanfill(startX, startY, inside, set)
	-- Span fill algorithm
	-- (Combined-scan-and-fill)
	-- https://en.wikipedia.org/wiki/Flood_fill#Span_filling

	if not inside(startX, startY) then return end

	local s = {
		{ startX, startX, startY,      1 },
		{ startX, startX, startY - 1, -1 },
	}

	while #s > 0 do
		local popped = s[#s]
		s[#s] = nil
		local x1, x2, y, dy = popped[1], popped[2], popped[3], popped[4]
		local x = x1
		if inside(x, y) then
			while inside(x - 1, y) do
				set(x - 1, y)
				x = x - 1
			end
			if x < x1 then
				s[#s+1] = { x, x1 - 1, y - dy, -dy }
			end
		end
		while x1 <= x2 do
			while inside(x1, y) do
				set(x1, y)
				x1 = x1 + 1
			end
			if x1 > x then
				s[#s+1] = {x, x1 - 1, y + dy, dy}
			end
			if x1 - 1 > x2 then
				s[#s+1] = {x2 + 1, x1 - 1, y - dy, -dy}
			end
			x1 = x1 + 1
			while x1 < x2 and not inside(x1, y) do
				x1 = x1 + 1
			end
			x = x1
		end
	end
end

return spanfill
