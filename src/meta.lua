local Info = {
	VERSION = "v2025.8a",
	VERSION_NUMBER = 20250800,
}

if not love.filesystem.isFused() then
	Info.VERSION = "vDEV"
end

return Info
