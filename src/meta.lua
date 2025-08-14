local Info = {
	VERSION = "v2025.8.2a",
	VERSION_NUMBER = 20250802,
}

if not love.filesystem.isFused() then
	Info.VERSION = "vDEV"
end

return Info
