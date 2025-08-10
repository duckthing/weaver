local Info = {
	VERSION = "v2025.8.1a",
	VERSION_NUMBER = 20250801,
}

if not love.filesystem.isFused() then
	Info.VERSION = "vDEV"
end

return Info
