local Info = {
	VERSION = "v2025.8.3a",
	VERSION_NUMBER = 20250803,
}

if not love.filesystem.isFused() then
	Info.VERSION = "vDEV"
end

return Info
