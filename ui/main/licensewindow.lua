local Plan = require "lib.plan"
local PopupWindow = require "ui.components.containers.modals.popupwindow"
local VScroll = require "ui.components.containers.box.vscroll"
local Label = require "ui.components.text.label"

-- Lazy loaded later
local Licenses

---@class LicenseWindow: PopupWindow
local LicenseWindow = PopupWindow:extend()

---@param rules Plan.Rules
---@param licenses License[]
function LicenseWindow:new(rules, licenses, title)
	LicenseWindow.super.new(self, rules, nil, title or "Third-Party Licenses")

	---@type VScroll
	local vscroll = VScroll(
		Plan.Rules.new()
			:addX(Plan.pixel(0))
			:addY(Plan.pixel(0))
			:addWidth(Plan.parent())
			:addHeight(Plan.parent())
	)
	self.vscroll = vscroll

	if not Licenses then
		Licenses = require "src.global.licenses"
	end

	---@type License[]
	self.licenses = licenses or Licenses

	local cRules = Plan.Rules.new()
		:addX(Plan.pixel(0))
		:addY(Plan.keep())
		:addWidth(Plan.parent())
		:addHeight(Plan.content(Plan.pixel(40)))

	local spacer = Label(cRules, "\n\n")
	for _, license in ipairs(self.licenses) do
		local name = Label(cRules, license.library)
		-- TODO: Support author as array
		local author = Label(cRules, license.authors)
		local licenseName = Label(cRules, license.licenseName)
		local body = Label(cRules, license.body)
		name._align = "center"
		author._align = "center"
		licenseName._align = "center"

		vscroll:addChild(spacer)
		vscroll:addChild(name)
		vscroll:addChild(author)
		vscroll:addChild(licenseName)
		vscroll:addChild(spacer)
		vscroll:addChild(body)
	end


	self:addChild(vscroll)
end

function LicenseWindow:refresh()
	LicenseWindow.super.refresh(self)
	local containerW = self.container.w
	if not self.vscroll then return end
	for _, child in ipairs(self.vscroll.children) do
		---@cast child Label
		child:setWrapLimit(containerW)
	end
	LicenseWindow.super.refresh(self)
end

return LicenseWindow
