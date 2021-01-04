local SIZE_X = 1920
local SIZE_Y = 1080
local ITEM_SIZE = {
	124,
	124
}
local ITEM_SPACING = 30
local NUM_ITEM_SLOTS = 7
local WINDOW_WIDTH_SPACING = 50
local WINDOW_SIZE = {
	ITEM_SIZE[1] * NUM_ITEM_SLOTS + (NUM_ITEM_SLOTS - 1) * ITEM_SPACING + WINDOW_WIDTH_SPACING * 2,
	550
}
local video_window_width = 426
local video_window_height = 400

-- hero_window_character_preview_definitions.lua
local window_default_settings = UISettings.game_start_windows
local window_background = window_default_settings.background
local window_frame = window_default_settings.frame
local window_size = window_default_settings.size
local window_frame_width = UIFrameSettings[window_frame].texture_sizes.vertical[1]
local window_frame_height = UIFrameSettings[window_frame].texture_sizes.horizontal[2]
local window_text_width = window_size[1] - (window_frame_width * 2 + 60)
-- 

local scenegraph_definition = {
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
	root_fit = {
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
	window = {
		vertical_alignment = "center",
		parent = "menu_root",
		horizontal_alignment = "center",
		size = window_size,
		position = {
			0,
			0,
			1
		}
	},
    screen = {
		vertical_alignment = "center",
		parent = "root",
		horizontal_alignment = "center",
		size = {
			SIZE_X,
			SIZE_Y
		},
		position = {
			0,
			0,
			1
		},
	},
	rect = {
		vertical_alignment = "bottom",
		parent = "screen",
		horizontal_alignment = "center",
		position = {
			0,
			160,
			1
		},
		size = {
			SIZE_X,
			SIZE_Y - 360
		}
	},
	background = {
		vertical_alignment = "center",
		parent = "window",
		horizontal_alignment = "center",
		position = {
			0,
			0,
			1
		},
		size = {
			SIZE_X -20,
			SIZE_Y - 380,
		}
	},
	item_title = {
		vertical_alignment = "top",
		parent = "map",
		horizontal_alignment = "center",
		position = {
			0,
			-22,
			21
		},
		size = {
			WINDOW_SIZE[1],
			1
		}
	},
	map = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			window_size[1],
			window_size[2]
		},
		position = {
			0,
			0,
			5
		}
	},
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
		parent = "window",
		size = {
			window_size[1],
			window_size[2]
		},
		horizontal_alignment = "center",
		vertical_alignment = "top",
		position = {
			0,
			0,
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
local widgets_definition = {
	-- window = UIWidgets.create_frame("window", window_size, "", 1),
	window = UIWidgets.create_frame("window", scenegraph_definition.window.size, "menu_frame_06"),
	item_title = UIWidgets.create_title_text("n/a", "item_title"),
	-- rect = UIWidgets.create_simple_rect("rect", rect_color),
	--background = UIWidgets.create_background_with_frame("background", scenegraph_definition.background.size, "menu_frame_bg_01"," menu_frame_02"),
	-- info_window_video = UIWidgets.create_frame("info_window_video", scenegraph_definition.info_window_video.size, "menu_frame_06"),
	info_video_edge_left = UIWidgets.create_simple_texture("frame_detail_03", "info_video_edge_left"),
	info_video_edge_right = UIWidgets.create_simple_uv_texture("frame_detail_03", {
		{
			1,
			0
		},
		{
			0,
			1
		}
	}, "info_video_edge_right"),
	-- window_background = UIWidgets.create_tiled_texture("window", "menu_frame_bg_01", {
	-- 	960,
	-- 	1080
	-- }, nil, nil, {
	-- 	255,
	-- 	100,
	-- 	100,
	-- 	100
	-- }),
	-- viewport_background = UIWidgets.create_rect_with_frame("viewport_background", scenegraph_definition.viewport_background.size, background_color, "menu_frame_06"),
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
			layer = 999,
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
		debug_text = "n/a",
	}
}
  
return {
    scenegraph_definition = scenegraph_definition,
	widgets_definition = widgets_definition,
	map_viewport = map_viewport
}