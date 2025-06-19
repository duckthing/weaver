local Plan = require "lib.plan"
local Fonts = require "src.global.fonts"
local VFlex = require "ui.components.containers.flex.vflex"
local HFlex = require "ui.components.containers.flex.hflex"
local HBox = require "ui.components.containers.box.hbox"
local VScroll = require "ui.components.containers.box.vscroll"
local Label = require "ui.components.text.label"
local LabelButton = require "ui.components.button.labelbutton"
local Contexts = require "src.global.contexts"
local GlobalConfig = require "src.global.config"
local Handler = require "src.global.handler"

local isWindows = love.system.getOS() == "Windows"

---@class HomeEditor.Window: Plan.Container
local HomeWindow = Plan.Container:extend()

function HomeWindow:new(rules)
	HomeWindow.super.new(self, rules)
	---@type Label
	local label = Label(
		Plan.RuleFactory.full()
	)
	label:setText("Loading")
	label:setJustify("center")
	label:setAlign("center")
	self:addChild(label)
end

function HomeWindow:showIntroduction()
	self:clearChildren()
	---@type Label
	local title = Label(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.keep())
			:addWidth(Plan.content(Plan.pixel(0)))
			:addHeight(Plan.content(Plan.pixel(0)))
	)
	title:setFont(Fonts.getDefaultFont(32))
	title:setText("Welcome to Weaver v2025.6a")

	---@type LabelButton
	local docButton = LabelButton(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(200))
			:addHeight(Plan.content(Plan.pixel(0)))
	)
	docButton:setLabel("Read Manual (Open Link)")

	---@type LabelButton
	local newButton = LabelButton(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.keep())
			:addWidth(Plan.pixel(200))
			:addHeight(Plan.content(Plan.pixel(0))),
		function(_)
			Contexts.raiseAction("new_buffer")
		end
	)
	newButton:setLabel("Create Sprite")

	---@type VFlex
	local vflex = VFlex(
		Plan.Rules.new()
			:addX(Plan.center())
			:addY(Plan.pixel(0))
			:addWidth(Plan.content(Plan.pixel(0)))
			:addHeight(Plan.parent())
	)
	vflex:setJustify("center")
	vflex:addChild(title)
	vflex:addChild(docButton)
	vflex:addChild(newButton)

	self:addChild(vflex)
end

function HomeWindow:showRecents(data)
	self:clearChildren()

	---@type HBox
	local actionBox = HBox(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.pixel(30))
	)

	do
		---@type LabelButton
		local newButton = LabelButton(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.pixel(160))
				:addHeight(Plan.parent()),
			function(_)
				Contexts.raiseAction("new_buffer")
			end,
			"Create New..."
		)

		---@type LabelButton
		local openButton = LabelButton(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.pixel(160))
				:addHeight(Plan.parent()),
			function(_)
				Contexts.raiseAction("open_buffer")
			end,
			"Open File..."
		)

		actionBox:addChild(newButton)
		actionBox:addChild(openButton)
	end

	---@type HFlex
	local scrollContainers = HFlex(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(30))
			:addWidth(Plan.parent())
			:addHeight(Plan.max(30))
	)
	scrollContainers:setJustify("spacebetween")

	for i = 1, 2 do
		---@type VScroll
		local vscroll = VScroll(
			Plan.Rules.new()
				:addX(Plan.keep())
				:addY(Plan.pixel(0))
				:addWidth(Plan.keep())
				:addHeight(Plan.parent())
		)
		vscroll.sizeRatio = 1

		local arr

		if i == 1 then
			arr = GlobalConfig.recentItems
		else
			arr = GlobalConfig.recentProjects
		end

		if not arr then goto continue end

		for j = 1, #arr do
			local path = arr[j]

			local formattedPath = path
			if not isWindows then
				-- Replace home directory with ~
				formattedPath = path:gsub(love.filesystem.getUserDirectory(), "~/")
			end

			---@type LabelButton
			local openButton = LabelButton(
				Plan.Rules.new()
					:addX(Plan.pixel(0))
					:addY(Plan.keep())
					:addWidth(Plan.parent())
					:addHeight(Plan.pixel(40)),
				function(_)
					-- Open the file
					Handler.importAndHandle(path)
				end,
				formattedPath
			)
			vscroll:addChild(openButton)
		end
		::continue::

		scrollContainers:addChild(vscroll)
	end

	self:addChild(actionBox)
	self:addChild(scrollContainers)
end

function HomeWindow:draw()
	love.graphics.setColor(0.08, 0.08, 0.18)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1, 1, 1)
	HomeWindow.super.draw(self)
end

return HomeWindow
