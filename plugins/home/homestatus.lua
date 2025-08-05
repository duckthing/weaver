local Plan = require "lib.plan"
local Status = require "src.global.status"
local Label = require "ui.components.text.label"
local Info = require "src.meta"

---@class HomeStatus: StatusContext
local HomeStatus = Status.StatusContext:extend()

function HomeStatus:new()
	---@diagnostic disable-next-line
	HomeStatus.super.new(self)
	---@type Label
	self.label = Label(
		Plan.RuleFactory.full(),
		("%s   Check the source repository for new features and fixes"):format(Info.VERSION)
	)
	self.label:setPadding(8)
	self:addChild(self.label)
end

function HomeStatus:draw()
	HomeStatus.super.draw(self)
end

return HomeStatus
