local mod = get_mod("minimap2")
mod:dofile("scripts/mods/minimap2/OrtoCam")
-- Pass definition slightly changed from original UIPasses.viewport from scripts/ui/ui_passes

UIPasses.map_viewport = {
	init = function (pass_definition, content, style)
		-- viewport including camera
		local world = mod.world
		local viewport_name = style.viewport_name or "minimap_viewport"
		local viewports = World.get_data(world, "viewports")
		local player = Managers.player:local_player()

		local viewport = mod.viewport or  viewports[viewport_name]
		if not viewport then
			viewport = ScriptWorld.create_viewport(world, viewport_name, "default")
			mod.viewport = viewport
		end
		
		if not mod.camera then
			mod.camera = MinimapOrtoCam:new(mod.world, mod.viewport, mod.player)
		end

		Viewport.set_data(viewport, "layer", layer or 2)
		Viewport.set_data(viewport, "active", true)
		Viewport.set_data(viewport, "name", viewport_name)
	
		viewports[viewport_name] = viewport
	
		Viewport.set_data(viewport, "avoid_shading_callback", false)
		Viewport.set_data(viewport, "no_scaling", true)
	
		mod.camera:sync()
		
		-- sub gui
		if style.enable_sub_gui then
			ui_renderer = UIRenderer.create(world, "material", "materials/ui/ui_1080p_hud_atlas_textures", "material", "materials/ui/ui_1080p_hud_single_textures", "material", "materials/ui/ui_1080p_menu_atlas_textures", "material", "materials/ui/ui_1080p_menu_single_textures", "material", "materials/ui/ui_1080p_common", "material", "materials/fonts/gw_fonts")
		end
		return {
			deactivated = deactivated,
			world = world,
			world_name = style.world_name,
			viewport = viewport,
			viewport_name = viewport_name,
			ui_renderer = mod.ui_top_renderer,
			camera = camera
		}
	end,
	destroy = function (ui_renderer, pass_data, pass_definition)
		local world = mod.world
		local ui_renderer = mod.ui_renderer
		local viewport_name = "minimap_viewport"

		mod.camera = nil
		if world then
			ScriptWorld.destroy_viewport(world, viewport_name)
		end

		mod.viewport = nil

		mod.active = false
		mod._character_offset = 0
		if pass_data.ui_renderer then
			UIRenderer.destroy(ui_renderer, world)
		end
	end,
	draw = function (ui_renderer, pass_data, ui_scenegraph, pass_definition, ui_style, ui_content, position, size, input_service, dt)
		-- sync cam
		if not mod.active then
			mod:echo("not active, bye")
			return
		end
		if not mod.camera then
			mod:echo("not cam, baby")
			return
		end
		mod.camera:sync(dt)
	end,
	raycast_at_screen_position = function (pass_data, screen_position, result_type, range, collision_filter)
		mod:echo("should re implement raycasting here")
		-- if pass_data.viewport_rect_pos_x == nil then
		-- 	return nil
		-- end

		-- local resx = RESOLUTION_LOOKUP.res_w
		-- local resy = RESOLUTION_LOOKUP.res_h
		-- local camera_space_position = Vector3.zero()
		-- local aspect_ratio = resx / resy
		-- local default_aspect = 1.7777777777777777

		-- if aspect_ratio < default_aspect then
		-- 	local scale_x = screen_position.x / resx
		-- 	local width = resy / 9 * 16
		-- 	camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
		-- 	local scale_y = screen_position.y / resy
		-- 	local height = pass_data.size_scale_x * resy
		-- 	camera_space_position.y = resy * 0.5 - height * 0.5 + height * scale_y
		-- elseif default_aspect < aspect_ratio then
		-- 	local scale_x = screen_position.x / resx
		-- 	local width = pass_data.size_scale_y * resx
		-- 	camera_space_position.x = resx * 0.5 - width * 0.5 + width * scale_x
		-- 	camera_space_position.y = screen_position.y
		-- else
		-- 	camera_space_position.x = screen_position.x
		-- 	camera_space_position.y = screen_position.y
		-- end

		-- local position = Camera.screen_to_world(pass_data.camera, camera_space_position, 0)
		-- local direction = Camera.screen_to_world(pass_data.camera, camera_space_position + Vector3(0, 0, 0), 1) - position
		-- local raycast_dir = Vector3.normalize(direction)
		-- local physics_world = World.get_data(pass_data.world, "physics_world")

		-- return PhysicsWorld.immediate_raycast(physics_world, position, raycast_dir, range, result_type, "collision_filter", collision_filter)
	end
}