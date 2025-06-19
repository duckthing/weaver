local Plan = require "lib.plan"
local Status = require "src.global.status"
local VBox = require "ui.components.containers.box.vbox"
local Flux = require "lib.flux"

---@class StatusBar: VBox
local StatusBar = VBox:extend()

function StatusBar:new(rules)
	StatusBar.super.new(self, rules)
	self:setDirection("last")

	---@type StatusContext?
	self.mainContext = nil
	---@type StatusContext?
	self.tempContext = nil
	self.isTempShown = false
	self.startedAt = 0

	self.contextChangedAction = Status.contextChanged:addAction(function(newContext)
		if self.mainContext then
			self:removeChild(self.mainContext)
		end

		if newContext then
			self.mainContext = newContext
			self:addChild(newContext)
		end
	end)

	self.tempContextAddedAction = Status.temporaryContextAdded:addAction(function(tempContext, duration)
		if self.tempContext then
			self:removeChild(self.tempContext)
			self.tween:stop()
		end

		if tempContext then
			self.tempContext = tempContext
			self:addChild(tempContext)
			self.offset = 0

			-- The animation
			self.isTempShown = true
			self.startedAt = love.timer.getTime()
			self.endAt = self.startedAt + duration
			self.tween = Flux.to(self, 0.2, {offset = self.h}):ease("quartout"):onupdate(function()
				self:sort()
			end):oncomplete(function()
				self.tween = Flux.to(self, 0.2, {offset = 0}):delay(self.endAt - love.timer.getTime()):ease("quartout")
					:onupdate(function()
						self:sort()
					end):oncomplete(function()
						self:removeChild(tempContext)
						self.isTempShown = false
					end)
			end)
		end
	end)
end

function StatusBar:draw()
	love.graphics.setColor(0.15, 0.15, 0.3)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

	if self.isTempShown then
		-- Show a slight progress bar on top of the progress bar
		local width = self.w * ((love.timer.getTime() - self.startedAt) / (self.endAt - self.startedAt))
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.rectangle("fill", self.x, self.y + self.offset - 1, width, 1)
	end

	StatusBar.super.draw(self)
end

return StatusBar
