local Luvent = require "lib.luvent"
local Plan = require "lib.plan"
local Label = require "ui.components.text.label"
local HBox = require "ui.components.containers.box.hbox"

local StatusModule = {}

-- StatusContext is different from Context.
-- This one is just for the bar at the bottom.

---@class StatusContext: Plan.Container
local StatusContext = Plan.Container:extend()
local MessageStatusContext = StatusContext:extend()
StatusModule.StatusContext = StatusContext
StatusModule.MessageStatusContext = MessageStatusContext

function StatusContext:new()
	StatusContext.super.new(
		self,
		Plan.Rules.new()
			:addX(Plan.keep())
			:addY(Plan.keep())
			:addWidth(Plan.parent())
			:addHeight(Plan.parent())
	)
end

function StatusContext:onExit()
end

function StatusContext:onEnter()
end

---@type StatusContext?
StatusModule.currentContext = nil
---@type StatusContext?
StatusModule.temporaryContext = nil -- For temporary notices
---@type number
StatusModule.temporaryDisappearAt = 0

StatusModule.contextChanged = Luvent.newEvent()
StatusModule.temporaryContextAdded = Luvent.newEvent()

---Changes the context
---@param newContext StatusContext?
function StatusModule.changeContext(newContext)
	local currentContext = StatusModule.currentContext
	-- Make sure it's different
	if newContext == currentContext then return end

	StatusModule.currentContext = newContext
	StatusModule.contextChanged:trigger(newContext)
end

---Pushes a temporary context that will appear for 'duration' over the current status.
---@param tempContext StatusContext
---@param duration number? # Seconds to appear for
function StatusModule.pushTemporaryContext(tempContext, duration)
	if not duration then duration = 5 end
	StatusModule.temporaryDisappearAt = love.timer.getTime() + duration
	StatusModule.temporaryContext = tempContext
	StatusModule.temporaryContextAdded:trigger(tempContext, duration)
end

---Pushes a temporary message over the current status.
---@param message string
---@param importance string?
---@param duration number? # Seconds to appear for
function StatusModule.pushTemporaryMessage(message, importance, duration)
	StatusModule.pushTemporaryContext(MessageStatusContext(message), duration)
end

function MessageStatusContext:new(message)
	---@diagnostic disable-next-line
	MessageStatusContext.super.new(self) -- this adds a Full rule

	---@type HBox
	local hbox = HBox(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.parent())
	)
	hbox.padding = 8
	hbox:addChild(
		Label(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.parent())
				:addHeight(Plan.parent()),
			message
		)
	)
	self:addChild(hbox)
end

return StatusModule
