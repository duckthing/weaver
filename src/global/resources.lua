local Luvent = require "lib.luvent"
local ResourceModule = {}

local newResourceId = 0
---@type Resource[]
ResourceModule.activeResources = {}

---@type Resource?
ResourceModule.currentResource = nil
---@type integer
local currentResourceId = 0

ResourceModule.onNewResource = Luvent.newEvent()
ResourceModule.onResourceSelected = Luvent.newEvent()
ResourceModule.onResourceDeselected = Luvent.newEvent()
ResourceModule.onResourceRemoved = Luvent.newEvent()

---Adds the Resource and then calls the new resource callbacks
---@param resource Resource
---@return integer resourceId
function ResourceModule.addResource(resource)
	newResourceId = newResourceId + 1
	resource.id = newResourceId

	local newIndex = #ResourceModule.activeResources + 1
	ResourceModule.activeResources[newIndex] = resource
	ResourceModule.onNewResource:trigger(resource)
	return newResourceId
end

---Removes the Resource
---@param resourceId integer
function ResourceModule.removeResource(resourceId)
	local resourceIndex = 0
	local removedResource = nil
	for i, resource in ipairs(ResourceModule.activeResources) do
		if resourceId == resource.id then
			removedResource = resource
			resourceIndex = i
			break
		end
	end

	if resourceIndex ~= 0 then
		table.remove(ResourceModule.activeResources, resourceIndex)
		ResourceModule.onResourceRemoved:trigger(removedResource)
	end

	if removedResource and currentResourceId == removedResource.id then
		-- Get the next Resource to select
		-- Goes the next -> the previous -> the first
		local nextResource = ResourceModule.activeResources[resourceIndex] or ResourceModule.activeResources[resourceIndex - 1] or ResourceModule.activeResources[1]

		if nextResource then
			ResourceModule.selectResourceId(nextResource.id)
		else
			-- No more resources left, close
			love.event.quit()
		end
	end
end

---Selected the Resource with the ID
---@param resourceId integer
function ResourceModule.selectResourceId(resourceId)
	if resourceId ~= currentResourceId then
		-- Deselect the old one
		local oldResource = ResourceModule.currentResource
		if oldResource then
			ResourceModule.onResourceDeselected:trigger(oldResource)
		end

		-- Find the new Resource
		---@type Resource?
		local selectedResource
		for _, resource in ipairs(ResourceModule.activeResources) do
			if resource.id == resourceId then
				selectedResource = resource
				break
			end
		end

		-- If the new Resource exists, select it
		ResourceModule.currentResource = selectedResource
		if selectedResource then
			currentResourceId = selectedResource.id
		else
			currentResourceId = 0
		end

		ResourceModule.onResourceSelected:trigger(selectedResource)
	end
end

---Returns the current Resource. Remember to not keep it in memory.
---@return Resource?
function ResourceModule.getCurrentResource()
	return ResourceModule.currentResource
end

return ResourceModule
