local Luvent = require "lib.luvent"

local State = {}

---@type Project?
State.project = nil

State.onProjectLoaded = Luvent.newEvent()

---@param project Project
function State.loadProject(project)
	if State.project ~= project then
		State.project = project
		State.onProjectLoaded:trigger(project)
	end
end

return State
