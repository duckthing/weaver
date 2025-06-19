-- Adapted from the Ellipse section of this link (MIT licensed):
-- (attribution added in src/global/licenses.lua)
-- https://zingl.github.io/bresenham.html

---Runs a function around the outline of an ellipse. Takes in the top left and bottom right points as parameters.
---Positions should ALWAYS be an integer!
---Also: This function may run over the same point twice, so make your function deterministic.
---
---Uses an adapted version of Bresenham's line algorithm.
---@param x0 integer
---@param y0 integer
---@param x1 integer
---@param y1 integer
---@param func fun(x: integer, y: integer, ...: unknown): nil
---@param ... unknown
local function bellipse(x0, y0, x1, y1, func, ...)
	local a = math.abs(x1 - x0)
	local b = math.abs(y1 - y0)
	local b1 = math.floor(b) % 2

	local dx = 4 * (1 - a) * b * b
	local dy = 4 * (b1 + 1) * a * a
	local err = dx + dy + b1 * a * a
	local e2 = 0

	if x0 > x1 then
		x0 = x1
		x1 = x1 + a
	end

	if y0 > y1 then
		y0 = y1
	end

	y0 = y0 + math.floor((b + 1)/2)
	y1 = y0 - b1
	a = 8 * a * a
	b1 = 8 * b * b

	while x0 <= x1 do
		func(x1, y0, ...)
		func(x0, y0, ...)
		func(x0, y1, ...)
		func(x1, y1, ...)

		e2 = 2 * err

		if (e2 <= dy) then
			y0 = y0 + 1
			y1 = y1 - 1
			dy = dy + a
			err = err + dy
		end

		if (e2 >= dx) or (2 * err > dy) then
			x0 = x0 + 1
			x1 = x1 - 1
			dx = dx + b1
			err = err + dx
		end
	end

	while (y0 - y1 < b) do
		func(x0 - 1, y0, ...)
		func(x1 + 1, y0, ...)
		func(x0 - 1, y1, ...)
		func(x1 + 1, y1, ...)
		y0 = y0 + 1
		y1 = y1 - 1
	end
end

return bellipse
