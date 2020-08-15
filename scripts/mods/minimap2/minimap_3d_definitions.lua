local scenegraph_definition = {
    sg_root = {
      size = {1920, 1080},
      position = {0, 0, UILayer.default},
  
      is_root = true,
    },
  
	minimap_3d_viewport = {
		scale = "fit",
		size = {
			920,
			540
		},
		position = {
			0,
			0,
			0
		}
	},
  }
  
  local widgets_definition = {
	viewport = {
		scenegraph_id = "minimap_3d_viewport",
		element = {
			passes = {
				{
					style_id = "viewport",
					pass_type = "viewport",
					content_id = "viewport"
				}
			}
		},
		style = {
			viewport = {
				scenegraph_id = "minimap_3d_viewport",
                viewport_name = "minimap_3d_viewport",
                layer = 990,
                viewport_type = "default_forward",
				level_name = "levels/ui_character_selection/world",
				enable_sub_gui = false,
				fov = 120,
				world_name = "minimap_3d_world",
				world_flags = {
					Application.DISABLE_SOUND,
                    Application.DISABLE_ESRAM,
					Application.ENABLE_VOLUMETRICS
                },
				camera_position = {
					0,
					0,
					0
				},
				camera_lookat = {
					0,
					0,
					-0.1
				}
			}
		},
        content = {}
    },
    background = UIWidgets.create_simple_texture("large_frame_01", "dead_space_filler")
  }
  
  return {
    scenegraph_definition = scenegraph_definition,
    widgets_definition = widgets_definition
  }