local Plan = require "lib.plan"
local Luvent = require "lib.luvent"

local VSplit = require "ui.components.containers.split.vsplit"
local AnimActions = require "plugins.sprite.ui.anim.animactions"

---@class AnimTimeline: Plan.Container
local AnimContainer = Plan.Container:extend()

---@class AnimTimeline.LCSplit: VSplit
local LCSplit = VSplit:extend()

function LCSplit:new(...)
	LCSplit.super.new(self, ...)
	self.splitChanged = Luvent.newEvent()
end

function LCSplit:draw()
	if self.h <= 0 then return end
	love.graphics.setColor(0.1, 0.1, 0.2)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	LCSplit.super.draw(self)
end

function LCSplit:updateSplit(...)
	---@diagnostic disable-next-line
	LCSplit.super.updateSplit(self, ...)
	self.splitChanged:trigger(self.splitPosition)
end

local actionsRules = Plan.Rules.new()
	:addX(Plan.pixel(0))
	:addY(Plan.pixel(5))
	:addWidth(Plan.parent())
	:addHeight(Plan.pixel(24))

function AnimContainer:new(rules)
	AnimContainer.super.new(self, rules)
	self._clipMode = "clip"
	---@type Timeline.Actions
	self.timelineActions = AnimActions(actionsRules)

	self:addChild(self.timelineActions)
end

function AnimContainer:draw()
	if self.w < 0 or self.h < 0 then return end
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(self.x, self.y, self.w, self.h)
	love.graphics.setColor(0.2, 0.2, 0.4)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	AnimContainer.super.draw(self)
	love.graphics.setScissor(ox, oy, ow, oh)
end

return AnimContainer
