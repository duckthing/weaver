---Runs a function from a start position to an end position.
---Positions should ALWAYS be an integer!
---
---Uses Bresenham's line algorithm.
---@param startX integer
---@param startY integer
---@param endX integer
---@param endY integer
---@param func fun(curX: integer, curY: integer, ...): nil
local function bline(startX, startY, endX, endY, func, ...)
	-- Difference, step
	-- Difference will always be absolute
	local dx, sx = 0, 0
	local dy, sy = 0, 0

	local curX, curY = startX, startY

	if startX < endX then
		dx = endX - startX
		sx = 1
	elseif endX < startX then
		dx = startX - endX
		sx = -1
	end

	if startY < endY then
		dy = endY - startY
		sy = 1
	elseif endY < startY then
		dy = startY - endY
		sy = -1
	end

	if dx > dy then
		-- X is the fast axis
		local e = (dy * 2) - dx
		for _ = 0, dx do
			func(curX, curY, ...)

			if e >= 0 then
				curY = curY + sy
				e = e - dx * 2
			end

			curX = curX + sx
			e = e + dy * 2
		end
	else
		-- Y is the fast axis
		local e = (dx * 2) - dy
		for _ = 0, dy do
			func(curX, curY, ...)

			if e >= 0 then
				curX = curX + sx
				e = e - dy * 2
			end

			curY = curY + sy
			e = e + dx * 2
		end
	end
end

return bline
