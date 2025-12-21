local Info = {
	VERSION = "v2025.8.4a",
	VERSION_NUMBER = 20250804,
}

if not love.filesystem.isFused() then
	Info.VERSION = "vDEV"
end

return Info
