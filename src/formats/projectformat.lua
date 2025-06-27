local json = require "lib.json"
local Path = require "lib.path"
local Format = require "src.data.format"
local Palette = require "src.data.palette"
local Project = require "src.data.project"
local Resources = require "src.global.resources"
local State = require "src.global.state"

---@class ProjectFormat: Format
local ProjectFormat = Format:extend()
ProjectFormat.FORMAT_NAME = "ProjectFormat"
ProjectFormat.IMPORT_EXTENSIONS = {"wproj"}
ProjectFormat.EXPORT_FOR_TYPES = {Palette}

---@param path string
---@param file love.File
---@return boolean success
---@return Project | string projectOrError
function ProjectFormat:import(path, file)
	local dir = Path.parentdirsep(path)
	if not dir then return false, "Path invalid" end

	local data = json.decode(file:read("string", "all"))

	---@type Project
	local newProject = Project()
	newProject.root = Path.parentdirsep(path)

	if data.name then
		newProject.name:set(data.name)
	end

	if data.assetDirectory then
		newProject.assetDirectory = data.assetDirectory
	end

	return true, newProject
end

---@param project Project
---@param path string
---@param file love.File
function ProjectFormat:export(project, path, file)
	local data = {
		name = project.name:get(),
		assetDirectory = project.assetDirectory,
	}

	file:write(json.encode(data))
	return true
end

---@param path string
---@param project Project
function ProjectFormat:handleImportSuccess(path, project)
	State.loadProject(project)
	if not GlobalConfig then
		GlobalConfig = require "src.global.config"
	end
	GlobalConfig.addProjectToRecents(path)
	Resources.selectResourceId(Resources.addResource(project))
end

return ProjectFormat
