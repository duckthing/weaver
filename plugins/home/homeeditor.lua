local Status = require "src.global.status"
local Plugin = require "src.data.plugin"
local HomeWindow = require "plugins.home.homewindow"
local HomeStatus = require "plugins.home.homestatus"
local GlobalConfig = require "src.global.config"

---@class HomeEditor: Plugin
local HomeEditor = Plugin:extend()
HomeEditor.TYPE = "home"

function HomeEditor:new(rules)
	HomeEditor.super.new(self, rules)
	---@type HomeEditor.Window
	self.container = HomeWindow(rules, self)
	self.statusContext = HomeStatus()
end

function HomeEditor:onEnter()
	Status.changeContext(self.statusContext)
	love.window.setTitle("Weaver")
end

function HomeEditor:onExit()
	Status.changeContext()
end

function HomeEditor:setSessionData()
	if GlobalConfig.firstLaunch then
		self.container:showIntroduction()
	else
		self.container:showRecents(GlobalConfig:getSessionData())
	end
end

HomeEditor:assignAsDefault()
return HomeEditor
