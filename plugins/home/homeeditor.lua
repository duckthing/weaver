local Status = require "src.global.status"
local Editor = require "src.data.editor"
local HomeWindow = require "plugins.home.homewindow"
local HomeStatus = require "plugins.home.homestatus"
local ConfigGlobals = require "plugins.home.configglobals"

---@class HomeEditor: Editor
local HomeEditor = Editor:extend()
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

---@param plugin GlobalConfig
function HomeEditor:setSourcePlugin(plugin)
	HomeEditor.super.setSourcePlugin(self, plugin)
	GlobalConfig = plugin
	self.container.GlobalConfig = plugin
end

return HomeEditor
