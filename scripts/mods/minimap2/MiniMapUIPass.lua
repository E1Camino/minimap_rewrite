local mod = get_mod("minimap2")
-- Pass definition slightly changed from original UIPasses.viewport from scripts/ui/ui_passes

UIPasses.map_viewport = {
    init = function (pass_definition, content, style)
        mod:echo("My own ui pass yay")
		local style = style[pass_definition.style_id]
		local content = content[pass_definition.content_id]

		if not style.world_flags then
			local world_flags = {
				Application.DISABLE_SOUND,
				Application.DISABLE_ESRAM
			}
		end

        local shading_environment = style.shading_environment
        mod:echo("world name")
        mod:echo(style.world_name)
        local world =  Managers.world:world(style.world_name)
        if not worldd then
            world = Managers.world:create_world(style.world_name, shading_environment, nil, style.layer, unpack(world_flags))
        end
		local viewport_type = style.viewport_type or "default"
		local viewport = ScriptWorld.create_viewport(world, style.viewport_name, viewport_type, style.layer)
		local level_name = style.level_name
		local object_sets = style.object_sets
		local level = nil

		if level_name then
			local position, rotation, shading_callback, mood_setting = nil
			local time_sliced_spawn = false
			level = ScriptWorld.spawn_level(world, level_name, object_sets, position, rotation, shading_callback, mood_setting, time_sliced_spawn)

			Level.spawn_background(level)
		end

		local deactivated = true

		ScriptWorld.deactivate_viewport(world, viewport)

		local camera_pos = Vector3Aux.unbox(style.camera_position)
		local camera_lookat = Vector3Aux.unbox(style.camera_lookat)
		local camera_direction = Vector3.normalize(camera_lookat - camera_pos)
		local camera = ScriptViewport.camera(viewport)

		ScriptCamera.set_local_position(camera, camera_pos)
		ScriptCamera.set_local_rotation(camera, Quaternion.look(camera_direction))

		local fov = style.fov or 65

		Camera.set_vertical_fov(camera, (math.pi * fov) / 180)

		local ui_renderer = nil

		if style.enable_sub_gui then
			ui_renderer = UIRenderer.create(world, "material", "materials/ui/ui_1080p_hud_atlas_textures", "material", "materials/ui/ui_1080p_hud_single_textures", "material", "materials/ui/ui_1080p_menu_atlas_textures", "material", "materials/ui/ui_1080p_menu_single_textures", "material", "materials/ui/ui_1080p_common", "material", "materials/fonts/gw_fonts")
		end

		return {
			deactivated = deactivated,
			world = world,
			world_name = style.world_name,
			level = level,
			viewport = viewport,
			viewport_name = style.viewport_name,
			ui_renderer = ui_renderer,
			camera = camera
		}
	end,
	destroy = function (ui_renderer, pass_data, pass_definition)
		if pass_data.ui_renderer then
			UIRenderer.destroy(pass_data.ui_renderer, pass_data.world)

			pass_data.ui_renderer = nil
		end

		ScriptWorld.destroy_viewport(pass_data.world, pass_data.viewport_name)
		Managers.world:destroy_world(pass_data.world)
	end,
	draw = function (ui_renderer, pass_data, ui_scenegraph, pass_definition, ui_style, ui_content, position, size, input_service, dt)
		local scaled_position = UIScaleVectorToResolution(position)
		local scaled_size = UIScaleVectorToResolution(size)
		local resx = RESOLUTION_LOOKUP.res_w
		local resy = RESOLUTION_LOOKUP.res_h
		local viewport_size = Vector3.zero()
		viewport_size.x = math.clamp(scaled_size.x / resx, 0, 1)
		viewport_size.y = math.clamp(scaled_size.y / resy, 0, 1)
		local viewport_position = Vector3.zero()
		viewport_position.x = math.clamp(scaled_position.x / resx, 0, 1)
		viewport_position.y = math.clamp(1 - scaled_position.y / resy - viewport_size.y, 0, 1)
		local viewport = pass_data.viewport
		local world = pass_data.world

		if pass_data.deactivated then
			ScriptWorld.activate_viewport(world, viewport)

			pass_data.deactivated = false
		end

		local splitscreen = false

		if Managers.splitscreen then
			splitscreen = Managers.splitscreen:active()
		end

		local multiplier = (splitscreen and 0.5) or 1

		Viewport.set_rect(viewport, viewport_position.x * multiplier, viewport_position.y * multiplier, viewport_size.x * multiplier, viewport_size.y * multiplier)

		pass_data.viewport_rect_pos_x = viewport_position.x
		pass_data.viewport_rect_pos_y = viewport_position.y
		pass_data.viewport_rect_size_x = scaled_size.x
		pass_data.viewport_rect_size_y = scaled_size.y
		pass_data.size_scale_x = viewport_size.x
		pass_data.size_scale_y = viewport_size.y
	end,
	raycast_at_screen_position = function (pass_data, screen_position, result_type, range, collision_filter)
		if pass_data.viewport_rect_pos_x == nil then
			return nil
		end

		local resx = RESOLUTION_LOOKUP.res_w
		local resy = RESOLUTION_LOOKUP.res_h
		local camera_space_position = Vector3.zero()
		local aspect_ratio = resx / resy
		local default_aspect = 1.7777777777777777

		if aspect_ratio < default_aspect then
			local scale_x = screen_position.x / resx
			local width = resy / 9 * 16
			camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
			local scale_y = screen_position.y / resy
			local height = pass_data.size_scale_x * resy
			camera_space_position.y = resy * 0.5 - height * 0.5 + height * scale_y
		elseif default_aspect < aspect_ratio then
			local scale_x = screen_position.x / resx
			local width = pass_data.size_scale_y * resx
			camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
			camera_space_position.y = screen_position.y
		else
			camera_space_position.x = screen_position.x
			camera_space_position.y = screen_position.y
		end

		local position = Camera.screen_to_world(pass_data.camera, camera_space_position, 0)
		local direction = Camera.screen_to_world(pass_data.camera, camera_space_position + Vector3(0, 0, 0), 1) - position
		local raycast_dir = Vector3.normalize(direction)
		local physics_world = World.get_data(pass_data.world, "physics_world")

		return PhysicsWorld.immediate_raycast(physics_world, position, raycast_dir, range, result_type, "collision_filter", collision_filter)
	end
}