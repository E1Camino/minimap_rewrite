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
                viewport_name = "minimaps_3d_viewport",
                layer = UILayer.default,
                viewport_type = "default_forward",
                shading_environment = "environment/blank_offscreen_chest_item",
				enable_sub_gui = false,
				fov = 120,
				world_flags = {
					Application.DISABLE_SOUND,
                    Application.DISABLE_ESRAM,
					Application.ENABLE_VOLUMETRICS
                },
                object_sets = {
                    "flow_victory"
                },
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
			},
			shading_environment = {
                fog_enabled = 0,
                dof_enabled = 0,
                motion_blur_enabled = 0,
                outline_enabled = 0,
                ssm_enabled = 1,
                ssm_constant_update_enabled = 1
            }
		},
        content = {}
    },
    background = UIWidgets.create_simple_texture("large_frame_01", "minimap_3d_viewport")
  }
  
  return {
    scenegraph_definition = scenegraph_definition,
    widgets_definition = widgets_definition
  }