love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
love.keyboard.setKeyRepeat(true)

local GlobalConfig = require "src.global.config"
local Sessions = require "src.global.sessions"
local Fonts = require "src.global.fonts"
Sessions.load()
local scale = 1

do
	-- (Temp) switch fonts
	local data = Sessions.getCachedData()
	if data.global then
		local settings = data.global.settings
		if settings then
			if settings["Use Pixel Font"] == false then
				Fonts.defaultFont = "normal"
			end

			scale = settings["App Scale"] or 1
		end
	end
end

-- TODO: Move plugin loading out of previewer
local Previewer = require "ui.main.previewer"

local Plan = require "lib.plan"
local Modal = require "src.global.modal"
local Resources = require "src.global.resources"
local Palettes = require "src.global.palettes"
local SpriteResource = require "plugins.sprite.spriteresource"
local Contexts = require "src.global.contexts"
local Plugin = require "src.data.plugin"
local Flux = require "lib.flux"
local Status = require "src.global.status"

local Handler = require "src.global.handler"
local GplFormat = require "src.formats.gpl"
local WgfFormat = require "src.formats.wgf"

Handler.addFormat(GplFormat)
Handler.addFormat(WgfFormat)

---@type Plan.Root
local uiRoot = nil

function love.load()
	-- The UI root
	uiRoot = Plan.Root(scale)

	-- The GlobalContext
	---@type GlobalContext
	---@diagnostic disable-next-line: assign-type-mismatch
	local globalContext = Plugin.defaultEditors.global:getContext()
	globalContext.uiRoot = uiRoot
	Plugin.setGlobalContext(globalContext)
	Contexts.pushContext(globalContext)

	-- The Previewer, which relies on the GlobalContext being set
	local previewer = Previewer(
		Plan.RuleFactory.full()
	)
	uiRoot:addChild(previewer)

	Modal.uiRoot = uiRoot

	Contexts.raiseAction("open_home")

	-- Palettes
	Palettes.reloadPalettes()

	-- Icon
	love.window.setIcon(love.image.newImageData("assets/icon_small.png"))
end

function love.update(dt)
	-- dt is high when tabbing back in
	dt = math.min(0.1, dt)
	Flux.update(dt)
	uiRoot:update(dt)
end

local diagLineShader
do
	local diagLineShaderCode = [[
vec4 effect(vec4 color, Image texture, vec2 texturePos, vec2 screenPos)
{
	float num = step(
		mod(
			0.02 * screenPos.x +
			0.02 * screenPos.y,
		1.f),
	0.2f) * 0.2 + 0.4;
	return vec4(color.rgb, num);
}
]]
	diagLineShader = love.graphics.newShader(diagLineShaderCode)
end

local waitStep = 0.1
local waitLimit = math.huge -- TODO: allow adjusting later
local timeWaited = waitLimit
function love.draw()
	if love.window.hasFocus() then
		timeWaited = waitLimit
		uiRoot:draw()
	else
		local shouldQuit = false

		-- Lower the FPS and handle any events
		while not love.window.hasFocus() and timeWaited < waitLimit do
			love.timer.sleep(waitStep)
			timeWaited = timeWaited + waitStep

			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					shouldQuit = true
					timeWaited = waitLimit
					goto breakLoop
				end
				---@diagnostic disable-next-line: undefined-field
				love.handlers[name](a,b,c,d,e,f)
			end
		end
		::breakLoop::

		-- Quit if needed
		if shouldQuit then
			love.event.quit()
			return
		end

		timeWaited = 0
		uiRoot:draw()
		love.graphics.setColor(0, 0, 0)
		love.graphics.setShader(diagLineShader)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
		love.graphics.setShader()
		love.graphics.setColor(1, 1, 1)
	end
end

function love.mousemoved(...)
	uiRoot:mousemoved(...)
end

function love.mousepressed(...)
	uiRoot:mousepressed(...)
end

function love.mousereleased(...)
	uiRoot:mousereleased(...)
end

function love.wheelmoved(...)
	uiRoot:wheelmoved(...)
end

function love.keypressed(key, scanCode, isRepeat)
	local sunk = uiRoot:keypressed(key, scanCode, isRepeat)
	if not sunk then
		Contexts.keypressed(key, scanCode, isRepeat)
	end
end

function love.textinput(text)
	local focusedUI = uiRoot.context.focusedUI
	if focusedUI and focusedUI.textinput then
		focusedUI:textinput(text)
	end
end

function love.resize()
	uiRoot:refresh()
end

local checkInterval = 10
local lastChecked = -checkInterval
function love.quit()
	local currentTime = love.timer.getTime()
	if not love.filesystem.isFused() then
		-- Dev mode, quit
	else
		-- Release mode
		if currentTime - lastChecked > checkInterval then
			-- Check if there's any unsaved resources
			local hasUnsavedResources = false
			for _, resource in ipairs(Resources.activeResources) do
				if resource.modified:get() then
					hasUnsavedResources = true
					goto continue
				end
			end
			::continue::

			if hasUnsavedResources then
				-- Show warning about quitting without saving
				lastChecked = currentTime
				Status.pushTemporaryMessage(
					"You have unsaved resources; quit again to confirm",
					"warning",
					checkInterval
				)
				return true
			end
		end
	end

	-- Quit for real
	Sessions.save()
	return false
end
