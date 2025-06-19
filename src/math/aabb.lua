local AABBMath = {}

---Intersects two rectangles and returns the result.
---If there's no intersection, the width and height are 0.
---@param ax number
---@param ay number
---@param aw number
---@param ah number
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@return number x
---@return number y
---@return number w
---@return number h
function AABBMath.intersect(ax, ay, aw, ah, bx, by, bw, bh)
	local x, y =
		math.max(ax, bx),
		math.max(ay, by)

	local x2, y2 =
		math.min(ax + aw, bx + bw),
		math.min(ay + ah, by + bh)

	local w, h =
		math.max(0, x2 - x), math.max(0, y2 - y)
	return x, y, w, h
end

return AABBMath
