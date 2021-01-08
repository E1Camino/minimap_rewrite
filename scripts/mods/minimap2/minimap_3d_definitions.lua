local window_default_settings = UISettings.game_start_windows
local small_window_background = window_default_settings.background
local small_window_frame = window_default_settings.frame
local small_window_size = window_default_settings.size
local small_window_spacing = window_default_settings.spacing
local large_window_frame = window_default_settings.large_window_frame
local large_window_frame_width = 22
local inner_window_size = {
	small_window_size[1] * 3 + small_window_spacing * 2 + large_window_frame_width * 2,
	small_window_size[2] + 80
}
local window_size = {
	inner_window_size[1] + 50,
	inner_window_size[2]
}
local window_frame_width = large_window_frame_width
local INPUT_FIELD_WIDTH = 400

local SLIDER_SIZE = {
	INPUT_FIELD_WIDTH,
	10
}
local SLIDER_WIDGET_SIZE = {
	300,
	30
}


local scenegraph_definition = {
	--- start_game_state_settings_overview_definitions.lua
	root = {
		is_root = true,
		size = {
			1920,
			1080
		},
		position = {
			0,
			0,
			UILayer.default
		}
	},
	menu_root = {
		vertical_alignment = "center",
		parent = "root",
		horizontal_alignment = "center",
		size = {
			1920,
			1080
		},
		position = {
			0,
			0,
			0
		}
	},
	screen = {
		scale = "fit",
		size = {
			1920,
			1080
		},
		position = {
			0,
			0,
			UILayer.default
		}
	},
	header = {
		vertical_alignment = "top",
		parent = "menu_root",
		horizontal_alignment = "center",
		size = {
			1920,
			50
		},
		position = {
			0,
			-20,
			100
		}
	},
	window = {
		vertical_alignment = "center",
		parent = "screen",
		horizontal_alignment = "center",
		size = window_size,
		position = {
			0,
			0,
			0
		}
	},
	window_background = {
		vertical_alignment = "center",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			window_size[1] - 5,
			window_size[2] - 5
		},
		position = {
			0,
			0,
			0
		}
	},
	window_background_mask = {
		vertical_alignment = "center",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			window_size[1] - 5,
			window_size[2] - 5
		},
		position = {
			0,
			0,
			1
		}
	},
	inner_window = {
		vertical_alignment = "center",
		parent = "window",
		horizontal_alignment = "center",
		size = inner_window_size,
		position = {
			0,
			0,
			1
		}
	},
	inner_window_header = {
		vertical_alignment = "top",
		parent = "inner_window",
		horizontal_alignment = "center",
		size = {
			inner_window_size[1],
			50
		},
		position = {
			0,
			0,
			1
		}
	},
	exit_button = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			380,
			42
		},
		position = {
			0,
			-16,
			10
		}
	},
	title = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			658,
			60
		},
		position = {
			0,
			34,
			10
		}
	},
	title_bg = {
		vertical_alignment = "top",
		parent = "title",
		horizontal_alignment = "center",
		size = {
			410,
			40
		},
		position = {
			0,
			-15,
			-1
		}
	},
	title_text = {
		vertical_alignment = "center",
		parent = "title",
		horizontal_alignment = "center",
		size = {
			350,
			50
		},
		position = {
			0,
			-3,
			2
		}
	},
------- hero_window_weave_forge_panel_definitions.lua

	top_corner_left = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "left",
		size = {
			110,
			110
		},
		position = {
			22,
			-22,
			12
		}
	},
	top_corner_right = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "right",
		size = {
			110,
			110
		},
		position = {
			-large_window_frame_width,
			-large_window_frame_width,
			12
		}
	},
	bottom_corner_left = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "left",
		size = {
			110,
			110
		},
		position = {
			large_window_frame_width,
			large_window_frame_width,
			12
		}
	},
	bottom_corner_right = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "right",
		size = {
			110,
			110
		},
		position = {
			-large_window_frame_width,
			large_window_frame_width,
			12
		}
	},

	bottom_panel_left = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			634,
			80
		},
		position = {
			-317,
			large_window_frame_width,
			9
		}
	},
	bottom_panel_right = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			634,
			80
		},
		position = {
			317,
			large_window_frame_width,
			9
		}
	},
	essence_panel = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "left",
		size = {
			327,
			48
		},
		position = {
			large_window_frame_width,
			large_window_frame_width + 110,
			8
		}
	},
	loadout_power_title = {
		vertical_alignment = "bottom",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			300,
			20
		},
		position = {
			0,
			window_frame_width + 33,
			12
		}
	},
	poi_panel_text = {
		vertical_alignment = "bottom",
		parent = "loadout_power_title",
		horizontal_alignment = "center",
		size = {
			510,
			56
		},
		position = {
			0,
			-32,
			0
		}
	},
-------- start_game_window_weave_info_definitions
	settings_panel = {
		vertical_alignment = "bottom",
		parent = "inner_window",
		horizontal_alignment = "center",
		size = {
			400,
			72
		},
		position = {
			0,
			18,
			20
		}
	},
	map_checkbox = {
		vertical_alignment = "top",
		parent = "settings_panel",
		horizontal_alignment = "left",
		size = {
			400,
			40
		},
		position = {
			340,
			-24,
			0
		}
	},

-------- custom stuff added by me


	info_video_edge_left = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "right",
		size = {
			-window_size[1] / 2,
			59
		},
		position = {
			-window_size[1] / 2 - 40,
			12,
			13
		}
	},
	info_video_edge_right = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "left",
		size = {
			-window_size[1] / 2,
			59
		},
		position = {
			window_size[1] / 2 + 40,
			12,
			13
		}
	},
	viewport = {
		parent = "inner_window",
		size = {
			window_size[1] - large_window_frame_width * 2 + 8,
			window_size[2] - large_window_frame_width * 2 + 6
		},
		horizontal_alignment = "center",
		vertical_alignment = "top",
		position = {
			1,
			- large_window_frame_width + 4,
			900
		}
	},
}
local debug_text_style = {
	font_size = 32,
	upper_case = true,
	localize = false,
	use_shadow = true,
	word_wrap = true,
	horizontal_alignment = "center",
	vertical_alignment = "center",
	font_type = "hell_shark_header",
	text_color = Colors.get_color_table_with_alpha("red", 255),
	offset = {
		10,
		-20,
		1
	}
}
local title_text_style = {
	word_wrap = true,
	upper_case = true,
	localize = true,
	font_size = 28,
	horizontal_alignment = "center",
	vertical_alignment = "top",
	font_type = "hell_shark_header",
	text_color = Colors.get_color_table_with_alpha("font_title", 255),
	offset = {
		0,
		0,
		2
	}
}
local rect_color = {
	240,
	5,
	5,
	5
}
local background_color = {
	200,
	10,
	10,
	10
}
local weave_title_text_style = {
	font_size = 36,
	upper_case = true,
	localize = false,
	use_shadow = true,
	word_wrap = true,
	horizontal_alignment = "center",
	vertical_alignment = "bottom",
	font_type = "hell_shark_header",
	text_color = Colors.get_color_table_with_alpha("font_default", 255),
	offset = {
		0,
		0,
		2
	}
}
local description_text_style = {
	word_wrap = true,
	font_size = 22,
	localize = false,
	use_shadow = true,
	horizontal_alignment = "center",
	vertical_alignment = "top",
	font_type = "hell_shark",
	text_color = Colors.get_color_table_with_alpha("font_default", 255),
	offset = {
		0,
		0,
		2
	}
}
local title_text_style = {
	use_shadow = true,
	upper_case = true,
	localize = false,
	font_size = 28,
	horizontal_alignment = "center",
	vertical_alignment = "center",
	dynamic_font_size = true,
	font_type = "hell_shark_header",
	text_color = Colors.get_color_table_with_alpha("font_title", 255),
	offset = {
		0,
		0,
		2
	}
}
local panel_value_text_style = {
	font_size = 32,
	upper_case = true,
	localize = false,
	use_shadow = true,
	word_wrap = true,
	horizontal_alignment = "center",
	vertical_alignment = "center",
	font_type = "hell_shark_header",
	text_color = Colors.get_color_table_with_alpha("white", 255),
	offset = {
		0,
		0,
		2
	}
}
local function create_checkbox_button(scenegraph_id, size, text, font_size, tooltip_info, disable_with_gamepad)
	local widget = {
		element = {}
	}
	local passes = {}
	local content = {}
	local style = {}
	local hotspot_name = "button_hotspot"
	passes[#passes + 1] = {
		pass_type = "hotspot",
		content_id = hotspot_name,
		style_id = hotspot_name
	}
	style[hotspot_name] = {
		size = size,
		offset = {
			0,
			0,
			0
		}
	}
	content.disable_with_gamepad = disable_with_gamepad
	content[hotspot_name] = {}
	local hotspot_content = content[hotspot_name]

	if tooltip_info then
		local tooltip_name = "additional_option_info"
		passes[#passes + 1] = {
			pass_type = "additional_option_tooltip",
			content_id = hotspot_name,
			style_id = tooltip_name,
			additional_option_id = tooltip_name,
			content_check_function = function (content)
				return content.is_hover
			end
		}
		style[tooltip_name] = {
			vertical_alignment = "top",
			max_width = 400,
			horizontal_alignment = "center",
			offset = {
				0,
				0,
				0
			}
		}
		hotspot_content[tooltip_name] = tooltip_info
	end

	local text_name = "text"
	passes[#passes + 1] = {
		pass_type = "text",
		content_id = hotspot_name,
		text_id = text_name,
		style_id = text_name,
		content_check_function = function (content)
			return not content.disable_button
		end
	}
	local text_offset_x = 40
	style[text_name] = {
		word_wrap = true,
		font_size = 22,
		horizontal_alignment = "left",
		vertical_alignment = "center",
		font_type = "hell_shark",
		text_color = Colors.get_color_table_with_alpha("font_button_normal", 255),
		default_text_color = Colors.get_color_table_with_alpha("font_button_normal", 255),
		select_text_color = Colors.get_color_table_with_alpha("white", 255),
		offset = {
			text_offset_x,
			3,
			4
		},
		size = size
	}
	hotspot_content[text_name] = text
	local text_disabled_name = "text_disabled"
	passes[#passes + 1] = {
		pass_type = "text",
		content_id = hotspot_name,
		text_id = text_name,
		style_id = text_disabled_name,
		content_check_function = function (content)
			return content.disable_button
		end
	}
	style[text_disabled_name] = {
		horizontal_alignment = "left",
		font_size = 22,
		word_wrap = true,
		vertical_alignment = "center",
		font_type = "hell_shark",
		text_color = Colors.get_color_table_with_alpha("gray", 255),
		default_text_color = Colors.get_color_table_with_alpha("gray", 255),
		offset = {
			text_offset_x,
			3,
			4
		},
		size = size
	}
	local text_shadow_name = "text_shadow"
	passes[#passes + 1] = {
		pass_type = "text",
		content_id = hotspot_name,
		text_id = text_name,
		style_id = text_shadow_name
	}
	style[text_shadow_name] = {
		vertical_alignment = "center",
		font_size = 22,
		horizontal_alignment = "left",
		word_wrap = true,
		font_type = "hell_shark",
		text_color = Colors.get_color_table_with_alpha("black", 255),
		offset = {
			text_offset_x + 3,
			2,
			3
		},
		size = size
	}
	local checkbox_background_name = "checkbox_background"
	passes[#passes + 1] = {
		pass_type = "rect",
		style_id = checkbox_background_name
	}
	local checkbox_size = {
		25,
		25
	}
	local checkbox_offset = {
		0,
		size[2] / 2 - checkbox_size[2] / 2 + 2,
		3
	}
	style[checkbox_background_name] = {
		size = {
			checkbox_size[1],
			checkbox_size[2]
		},
		offset = checkbox_offset,
		color = {
			255,
			0,
			0,
			0
		}
	}
	local checkbox_frame_name = "checkbox_frame"
	passes[#passes + 1] = {
		pass_type = "texture_frame",
		content_id = hotspot_name,
		texture_id = checkbox_frame_name,
		style_id = checkbox_frame_name,
		content_check_function = function (content)
			return not content.is_disabled
		end
	}
	local frame_settings = UIFrameSettings.menu_frame_06
	hotspot_content[checkbox_frame_name] = frame_settings.texture
	style[checkbox_frame_name] = {
		size = {
			checkbox_size[1],
			checkbox_size[2]
		},
		texture_size = frame_settings.texture_size,
		texture_sizes = frame_settings.texture_sizes,
		offset = {
			checkbox_offset[1],
			checkbox_offset[2],
			checkbox_offset[3] + 1
		},
		color = {
			255,
			255,
			255,
			255
		}
	}
	local checkbox_frame_disabled_name = "checkbox_frame_disabled"
	passes[#passes + 1] = {
		pass_type = "texture_frame",
		content_id = hotspot_name,
		texture_id = checkbox_frame_name,
		style_id = checkbox_frame_disabled_name,
		content_check_function = function (content)
			return not content.is_disabled
		end
	}
	style[checkbox_frame_disabled_name] = {
		size = {
			checkbox_size[1],
			checkbox_size[2]
		},
		texture_size = frame_settings.texture_size,
		texture_sizes = frame_settings.texture_sizes,
		offset = {
			checkbox_offset[1],
			checkbox_offset[2],
			checkbox_offset[3] + 1
		},
		color = {
			96,
			255,
			255,
			255
		}
	}
	local checkbox_marker_name = "checkbox_marker"
	passes[#passes + 1] = {
		pass_type = "texture",
		content_id = hotspot_name,
		texture_id = checkbox_marker_name,
		style_id = checkbox_marker_name,
		content_check_function = function (content)
			return content.is_selected and not content.disable_button
		end
	}
	hotspot_content[checkbox_marker_name] = "matchmaking_checkbox"
	local marker_size = {
		22,
		16
	}
	local marker_offset = {
		checkbox_offset[1] + 4,
		(checkbox_offset[2] + marker_size[2] / 2) - 1,
		checkbox_offset[3] + 2
	}
	style[checkbox_marker_name] = {
		size = marker_size,
		offset = marker_offset,
		color = Colors.get_color_table_with_alpha("white", 255)
	}
	local checkbox_marker_disabled_name = "checkbox_marker_disabled"
	passes[#passes + 1] = {
		pass_type = "texture",
		content_id = hotspot_name,
		texture_id = checkbox_marker_name,
		style_id = checkbox_marker_disabled_name,
		content_check_function = function (content)
			return content.is_selected and content.disable_button
		end
	}
	style[checkbox_marker_disabled_name] = {
		size = marker_size,
		offset = marker_offset,
		color = Colors.get_color_table_with_alpha("gray", 255)
	}
	widget.element.passes = passes
	widget.content = content
	widget.style = style
	widget.offset = {
		0,
		0,
		0
	}
	widget.scenegraph_id = scenegraph_id

	return widget
end

local disable_with_gamepad = true
local widgets_definition = {
	window = UIWidgets.create_frame("window", scenegraph_definition.window.size, "menu_frame_11"),

	exit_button = UIWidgets.create_default_button("exit_button", scenegraph_definition.exit_button.size, nil, nil, Localize("menu_close"), 24, nil, "button_detail_04", 34, disable_with_gamepad),
	title = UIWidgets.create_simple_texture("frame_title_bg", "title"),
	title_bg = UIWidgets.create_background("title_bg", scenegraph_definition.title_bg.size, "menu_frame_bg_02"),
	title_text = UIWidgets.create_simple_text(Localize("start_game_view_title"), "title_text", nil, nil, title_text_style),

	bottom_panel_left = UIWidgets.create_simple_texture("athanor_power_bg", "bottom_panel_left"),
	bottom_panel_right = UIWidgets.create_simple_uv_texture("athanor_power_bg", {
		{
			1,
			0
		},
		{
			0,
			1
		}
	}, "bottom_panel_right"),
	top_corner_left = UIWidgets.create_simple_texture("athanor_decoration_corner", "top_corner_left"),
	top_corner_right = UIWidgets.create_simple_uv_texture("athanor_decoration_corner", {
		{
			1,
			0
		},
		{
			0,
			1
		}
	}, "top_corner_right"),
	bottom_corner_left = UIWidgets.create_simple_uv_texture("athanor_decoration_corner", {
		{
			0,
			1
		},
		{
			1,
			0
		}
	}, "bottom_corner_left"),
	bottom_corner_right = UIWidgets.create_simple_uv_texture("athanor_decoration_corner", {
		{
			1,
			1
		},
		{
			0,
			0
		}
	}, "bottom_corner_right"),
	essence_panel = UIWidgets.create_simple_rotated_texture("athanor_panel_front",  math.pi * -0.5, {
		large_window_frame_width + 4,
		large_window_frame_width
	}, "essence_panel"),
	poi_panel_text = UIWidgets.create_simple_text("0", "poi_panel_text", nil, nil, panel_value_text_style),

	viewport_setting_tooltip = UIWidgets.create_simple_tooltip(
		"n/a",
		"poi_panel_text",
		400,
		nil
	),

	map_checkbox = create_checkbox_button("map_checkbox", scenegraph_definition.map_checkbox.size, "Original shading", 24, {
		title = "Original shading environment",
		description = "Use the shading environment from the current level instead of the map view overwrite"
	}),
	
}
local map_viewport = {
	scenegraph_id = "viewport",
	element = {
		passes = {
			{
				style_id = "map_viewport",
				pass_type = "map_viewport",
				content_id = "map_viewport"
			}
		}
	},
	style = {
		map_viewport = {
			scenegraph_id = "viewport",
			viewport_name = "minimap_viewport",
			layer = 1,
			viewport_type = "overlay",
			enable_sub_gui = true,
			fov = 120,
			camera_position = {
				0,
				0.7,
				1
			},
			camera_lookat = {
				0,
				0,
				-0.1
			}
		}
	},
	content = {
		settings = {
			near = 100,
			far = 10000,
			height = 200,
			area = 12
		},
	}
}
local animation_definitions = {
	on_enter = {
		{
			name = "fade_in",
			start_progress = 0,
			end_progress = 0.3,
			init = function (ui_scenegraph, scenegraph_definition, widgets, params)
				params.render_settings.alpha_multiplier = 0
			end,
			update = function (ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local anim_progress = math.easeOutCubic(progress)
				params.render_settings.alpha_multiplier = 1
			end,
			on_complete = function (ui_scenegraph, scenegraph_definition, widgets, params)
				return
			end
		}
	},
	on_exit = {
		{
			name = "fade_out",
			start_progress = 0,
			end_progress = 0.3,
			init = function (ui_scenegraph, scenegraph_definition, widgets, params)
				params.render_settings.alpha_multiplier = 1
			end,
			update = function (ui_scenegraph, scenegraph_definition, widgets, progress, params)
				local anim_progress = math.easeOutCubic(progress)
				params.render_settings.alpha_multiplier = 1
			end,
			on_complete = function (ui_scenegraph, scenegraph_definition, widgets, params)
				return
			end
		}
	}
}
  
return {
    scenegraph_definition = scenegraph_definition,
	widgets_definition = widgets_definition,
	map_viewport = map_viewport,
	animation_definitions = animation_definitions
}