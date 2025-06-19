---@type Keybinds.KeyCombinations
local defaultKeybinds = {
	normal = {
		["1"] = "select_tool_1",
		["2"] = "select_tool_2",
		["3"] = "select_tool_3",
		["4"] = "select_tool_4",
		["5"] = "select_tool_5",
		["6"] = "select_tool_6",
		[","] = "shrink_brush",
		["."] = "grow_brush",
		left = "select_previous_frame",
		right = "select_next_frame",
		up = "select_higher_layer",
		down = "select_lower_layer",
		delete = "delete_inside_selection",
		escape = "clear_selection",
		x = "swap_primary_with_secondary_color",
		["["] = "select_previous_primary_color",
		["]"] = "select_next_primary_color",
	},
	alt = {
		n = "new_frame",
		d = "clone_frame",
	},
	ctrl = {
		z = "undo",
		y = "redo",
		c = "copy_selection",
		x = "cut_selection",
		v = "paste_selection",
		a = "select_all",
		i = "invert_selection",
		left = "select_first_frame",
		right = "select_last_frame",
		space = "toggle_animation",
	},
	shift = {
		n = "new_layer",
		["["] = "select_previous_secondary_color",
		["]"] = "select_next_secondary_color",
	},
	altshift = {
		left = "move_frame_left",
		right = "move_frame_right",
		up = "move_layer_up",
		down = "move_layer_down",
		s = "set_brush_to_selection_color",
	},
	ctrlshift = {
		z = "redo",
	},
	altctrlshift = {
		s = "set_brush_to_selection_mask"
	}
}

return defaultKeybinds
