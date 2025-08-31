local Object = require "lib.classic"
local Luvent = require "lib.luvent"
local Inspectable = require "src.properties.inspectable"
local StringProperty = require "src.properties.string"

---@class Sprite.Animation: Inspectable
local Animation = Inspectable:extend()

---@class Sprite.Animation.TrackPoint
---@field atTime number
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
---@param type string
function AnimationTrack:new(sprite, type)
	AnimationTrack.super.new(self)
	self.sprite = sprite
	---@type StringProperty
	self.name = StringProperty(self, "Name", "New Track")
	---@type Sprite.Animation.TrackPoint[]
	self.points = {}
	---@type string
	self.type = type

	self.pointInserted = Luvent.newEvent()
	self.pointChanged = Luvent.newEvent()
	self.pointRemoved = Luvent.newEvent()
end

---Inserts a new Point at the specified time. If there's an existing Point, we overwrite the data it has.
---@param atTime number
---@param data any
---@return boolean success
---@return Sprite.Animation.TrackPoint[]? point
function AnimationTrack:insertPoint(atTime, data)
	local index = 0

	-- First, pick the index where the point should be inserted
	for i = 1, #self.points do
		local point = self.points[i]
		if point.atTime == atTime then
			-- Same time, overwrite this point with the new data
			point.data = data
			self.pointChanged:trigger(self, point)
			return true, point
		elseif point.atTime < atTime then
			-- Insert before this point
			-- (Picking this index will push it forward)
			index = i
			break
		end
	end

	if #self.points == 0 then
		-- In case there aren't any points yet
		index = 1
	end

	if index > 0 then
		-- Found an index to insert at
		---@type Sprite.Animation.TrackPoint
		local point = {
			atTime = atTime,
			data = data,
		}
		table.insert(self.points, index, point)
		self.pointInserted:trigger(self, point)
		return true, point
	end

	return false, nil
end

---Clones this Animation and returns a new Animation
---@return Sprite.Animation newAnimation
function Animation:clone()
	---@type Sprite.Animation
	local anim = Animation(self.sprite)
	anim.name:set(self.name:get())

	-- TODO: Finish cloning for animations
	return anim
end

return Animation
