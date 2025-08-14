local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Inspectable = require "src.properties.inspectable"
local StringProperty = require "src.properties.string"

---@class Sprite.Animation: Inspectable
local Animation = Inspectable:extend()

---@alias Sprite.Animation.TrackPoint.Type
---| "marker"
---| "frame"

---@class Sprite.Animation.TrackPoint
---@field atTime number
---@field type Sprite.Animation.TrackPoint.Type
---@field data any

---@class Sprite.Animation.Track: Object
local AnimationTrack = Object:extend()

---@param sprite Sprite
function Animation:new(sprite)
	Animation.super.new(self)
	self.sprite = sprite
	---@type StringProperty
	self.name = StringProperty(self, "Name", "New Animation")
	---@type Sprite.Animation.Track[]
	self.tracks = {AnimationTrack(sprite)}

	self.trackInserted = Luvent.newEvent()
	self.trackRemoved = Luvent.newEvent()
end

function Animation:createTrack()
	---@type Sprite.Animation.Track
	local newTrack = AnimationTrack(self.sprite)
	self.tracks[#self.tracks+1] = newTrack
	self.trackInserted:trigger(self, newTrack)
end

---@param sprite Sprite
function AnimationTrack:new(sprite)
	AnimationTrack.super.new(self)
	self.sprite = sprite
	---@type StringProperty
	self.name = StringProperty(self, "Name", "New Track")
	---@type Sprite.Animation.TrackPoint[]
	self.points = {}

	self.pointInserted = Luvent.newEvent()
	self.pointChanged = Luvent.newEvent()
	self.pointRemoved = Luvent.newEvent()
end

---Inserts a new Point at the specified time. If there's a type that matches at that Point, it will be replaced.
---@param atTime number
---@param type Sprite.Animation.TrackPoint.Type
---@param data any
---@return boolean success
---@return Sprite.Animation.TrackPoint[]? point
function AnimationTrack:insertPoint(atTime, type, data)
	local index = -1

	for i = 1, #self.points do
		local point = self.points[i]
		if point.atTime == atTime then
			-- Same time, insert/overwrite at this point
			if point.type == type then
				-- Also same type, overwrite
				point.data = data
				self.pointChanged:trigger(self, point)
				return true, point
			else
				-- Different type, insert
				index = i
			end
		elseif point.atTime < atTime then
			-- Insert before this point
			-- (Picking this index will push it forward)
			index = i
			break
		end
	end

	if index ~= -1 then
		-- Found an index to insert at
		---@type Sprite.Animation.TrackPoint
		local point = {
			atTime = atTime,
			type = type,
			data = data,
		}
		table.insert(self.points, index, point)
		self.pointInserted:trigger(self, point)
		return true, point
	end

	return false, nil
end

return Animation
