local Plan = require "lib.plan"
local Status = require "src.global.status"
local Label = require "ui.components.text.label"

---@class HomeStatus: StatusContext
local HomeStatus = Status.StatusContext:extend()

function HomeStatus:new()
	---@diagnostic disable-next-line
	HomeStatus.super.new(self)
	---@type Label
	self.label = Label(
		Plan.RuleFactory.full(),
		"v2025.6.1a"
	)
	self.label:setPadding(8)
	self:addChild(self.label)
end

function HomeStatus:draw()
	HomeStatus.super.draw(self)
end

return HomeStatus
