local mod = get_mod("minimap2")
mod:dofile("scripts/mods/minimap2/OrtoCam")
-- Pass definition slightly changed from original UIPasses.viewport from scripts/ui/ui_passes

local VIEWPORT_NAME = "minimap_viewport"
local _original_layer = 0

-- hook that uses existing code from scripts/util/script_world.lua and adds special case for minimap_viewport
-- mod:hook(
-- 	ScriptWorld,
-- 	"render",
-- 	function(func, world)
-- 		local shading_env = World.get_data(world, "shading_environment")

-- 		if not shading_env then
-- 			return
-- 		end
	
-- 		local global_free_flight_viewport = World.get_data(world, "global_free_flight_viewport")
	
-- 		if global_free_flight_viewport then
-- 			ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"))
-- 			ShadingEnvironment.apply(shading_env)
	
-- 			if World.has_data(world, "shading_callback") and not Viewport.get_data(global_free_flight_viewport, "avoid_shading_callback") then
-- 				local callback = World.get_data(world, "shading_callback")
	
-- 				callback(world, shading_env, World.get_data(world, "render_queue")[1])
-- 			end
	
-- 			local camera = ScriptViewport.camera(global_free_flight_viewport)
	
-- 			Application.render_world(world, camera, global_free_flight_viewport, shading_env)
-- 		else
-- 			local render_queue = World.get_data(world, "render_queue")
	
-- 			if table.is_empty(render_queue) then
-- 				Application.update_render_world(world)
	
-- 				return
-- 			end
	
-- 			for _, viewport in ipairs(render_queue) do
-- 				if not World.get_data(world, "avoid_blend") then
-- 					ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"), World.get_data(world, "override_shading_settings"))
-- 				end
	
-- 				if World.has_data(world, "shading_callback") and not Viewport.get_data(viewport, "avoid_shading_callback") then
-- 					local callback = World.get_data(world, "shading_callback")
	
-- 					callback(world, shading_env, viewport)
-- 				end
	
-- 				if not World.get_data(world, "avoid_blend") then
-- 					ShadingEnvironment.apply(shading_env)
-- 				end
	
-- 				local camera = ScriptViewport.camera(viewport)
	
-- 				Application.render_world(world, camera, viewport, shading_env)
-- 			end
-- 		end
-- 	end
-- )
-- local minimap_shading_callback = function (self, world, shading_env, viewport)
-- 	if self._world == world then
-- 		mod:echo("shading callback")
-- 		local shading_env_settings = self._shading_environment[viewport] or self._shading_environment[Viewport.get_data(viewport, "overridden_viewport")] or EMPTY_TABLE

-- 		if shading_env_settings.dof_enabled then
-- 			local dof_enabled = shading_env_settings.dof_enabled

-- 			ShadingEnvironment.set_scalar(shading_env, "dof_enabled", dof_enabled)

-- 			if dof_enabled > 0 then
-- 				local focal_distance = shading_env_settings.focal_distance
-- 				local focal_region = shading_env_settings.focal_region
-- 				local focal_padding = shading_env_settings.focal_padding
-- 				local focal_scale = shading_env_settings.focal_scale

-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_distance", focal_distance)
-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_region", focal_region)
-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_region_start", focal_padding)
-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_region_end", focal_padding)
-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_near_scale", focal_scale)
-- 				ShadingEnvironment.set_scalar(shading_env, "dof_focal_far_scale", focal_scale)
-- 			end
-- 		end

-- 		local colors = nil
-- 		local local_player = Managers.player:local_player()

-- 		if local_player then
-- 			local peer_id = local_player:network_id()
-- 			local local_player_id = local_player:local_player_id()
-- 			local party = Managers.party:get_party_from_player_id(peer_id, local_player_id)
-- 			local side = Managers.state.side.side_by_party[party]

-- 			if side then
-- 				local side_name = side:name()

-- 				if side_name == "heroes" then
-- 					colors = OutlineSettings.colors
-- 				elseif side_name == "dark_pact" then
-- 					colors = OutlineSettingsVS.colors
-- 				end
-- 			end
-- 		end

-- 		if colors then
-- 			for name, settings in pairs(colors) do
-- 				local c = settings.color
-- 				local color = Vector3(c[2] / 255, c[3] / 255, c[4] / 255)
-- 				local multiplier = settings.outline_multiplier

-- 				if settings.pulsate then
-- 					multiplier = settings.outline_multiplier * 0.5 + math.sin(Application.time_since_launch() * settings.pulse_multiplier) * settings.outline_multiplier * 0.5
-- 				end

-- 				ShadingEnvironment.set_vector3(shading_env, settings.variable, color)
-- 				ShadingEnvironment.set_scalar(shading_env, settings.outline_multiplier_variable, multiplier)
-- 			end
-- 		end

-- 		if self._frame == 0 then
-- 			self._frame = 1

-- 			ShadingEnvironment.set_scalar(shading_env, "reset_luminance_adaption", 1)
-- 		elseif self._frame == 1 then
-- 			self._frame = 2

-- 			ShadingEnvironment.set_scalar(shading_env, "reset_luminance_adaption", 0)
-- 		end

-- 		for interaction_type, interaction_settings in pairs(WorldInteractionSettings) do
-- 			ShadingEnvironment.set_scalar(shading_env, interaction_settings.shading_env_variable, math.clamp(interaction_settings.window_size, 1, 50))
-- 		end

-- 		if self._vignette_falloff_opacity and self._vignette_color then
-- 			mod:echo("vignette")
-- 			local env_vignette_color = ShadingEnvironment.vector3(shading_env, "vignette_color")
-- 			local env_vignette_scale_falloff_opacity = ShadingEnvironment.vector3(shading_env, "vignette_scale_falloff_opacity")
-- 			local vignette_t = self._vignette_t
-- 			local vignette_s_f_o = self._vignette_falloff_opacity:unbox()
-- 			local max_scale_falloff_opacity = Vector3(math.min(vignette_s_f_o.x, env_vignette_scale_falloff_opacity.x), math.max(vignette_s_f_o.y, env_vignette_scale_falloff_opacity.y), math.max(vignette_s_f_o.z, env_vignette_scale_falloff_opacity.z))
-- 			local new_scale_falloff_opacity = Vector3.smoothstep(vignette_t, env_vignette_scale_falloff_opacity, max_scale_falloff_opacity)

-- 			ShadingEnvironment.set_vector3(shading_env, "vignette_color", self._vignette_color:unbox())
-- 			ShadingEnvironment.set_vector3(shading_env, "vignette_scale_falloff_opacity", new_scale_falloff_opacity)
-- 		end

-- 		local gamma = Application.user_setting("gamma") or 1

-- 		ShadingEnvironment.set_scalar(shading_env, "exposure", ShadingEnvironment.scalar(shading_env, "exposure") * gamma)

-- 		if Application.user_setting("render_settings", "particles_receive_shadows") then
-- 			local last_slice_idx = ShadingEnvironment.array_elements(shading_env, "sun_shadow_slice_depth_ranges") - 1
-- 			local last_slice_depths = ShadingEnvironment.array_vector2(shading_env, "sun_shadow_slice_depth_ranges", last_slice_idx)
-- 			last_slice_depths.x = 0

-- 			ShadingEnvironment.set_array_vector2(shading_env, "sun_shadow_slice_depth_ranges", last_slice_idx, last_slice_depths)
-- 		end

-- 		self.mood_handler:apply_environment_variables(shading_env)

-- 		local blur_value = World.get_data(world, "fullscreen_blur") or 0

-- 		if blur_value > 0 then
-- 			ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
-- 			ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", math.clamp(blur_value, 0, 1))
-- 		else
-- 			World.set_data(world, "fullscreen_blur", nil)
-- 			ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 0)
-- 		end

-- 		local greyscale_value = World.get_data(world, "greyscale") or 0

-- 		if greyscale_value > 0 then
-- 			ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
-- 			ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", math.clamp(greyscale_value, 0, 1))
-- 			ShadingEnvironment.set_vector3(shading_env, "grey_scale_weights", Vector3(0.33, 0.33, 0.33))
-- 		else
-- 			World.set_data(world, "greyscale", nil)
-- 			ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 0)
-- 		end
-- 	end
-- end

mod:hook(ScriptWorld, "create_shading_environment", function (func, world, shading_environment_name, shading_callback, mood_setting)
	local shading_env = World.create_shading_environment(world, shading_environment_name)

	mod.shading_env = shading_env
	-- mod:dump(shading_env, "shading_env", 3)
	mod.shading_callback = shading_callback
	mod.mood_setting = mood_setting

	World.set_data(world, "shading_environment", shading_env)
	World.set_data(world, "shading_callback", shading_callback)
	World.set_data(world, "shading_settings", {
		mood_setting,
		1
	})

	return shading_env
end
)

UIPasses.map_viewport = {
	init = function (pass_definition, content, style)

		-- copy of shading environment so we can adjust things without touching the original settings of 3d viewport


		-- viewport including camera
		local world = mod.world
		local viewport_name = style.viewport_name or VIEWPORT_NAME
		local viewports = World.get_data(world, "viewports")
		local player = Managers.player:local_player()
		local element_layer = style.layer or 999
-- 		mod:echo(element_layer)
		local viewport = mod.viewport or  viewports[viewport_name]
		if not viewport then
			viewport = ScriptWorld.create_viewport(world, viewport_name, "default", element_layer)
			mod.viewport = viewport
		end
		
		if not mod.camera then
			mod.camera = MinimapOrtoCam:new(mod.world, mod.viewport, mod.player)
		end

		-- Viewport.set_data(viewport, "layer", element_layer)
		-- _original_layer = World.get_data(world, "layer")

		-- World.set_data(world, "layer", element_layer)
		-- Application.update_render_world(world)

		Viewport.set_data(viewport, "active", true)
		Viewport.set_data(viewport, "name", viewport_name)
	
		viewports[viewport_name] = viewport
		ScriptWorld._update_render_queue(world)
		-- Viewport.set_data(viewport, "avoid_shading_callback", true)
		Viewport.set_data(viewport, "no_scaling", false)
			
		-- sub gui
		if style.enable_sub_gui then
			ui_renderer = UIRenderer.create(world, "material", "materials/ui/ui_1080p_hud_atlas_textures", "material", "materials/ui/ui_1080p_hud_single_textures", "material", "materials/ui/ui_1080p_menu_atlas_textures", "material", "materials/ui/ui_1080p_menu_single_textures", "material", "materials/ui/ui_1080p_common", "material", "materials/fonts/gw_fonts")
			mod._map_ui_renderer = ui_renderer
		end
		return {
			deactivated = deactivated,
			world = world,
			world_name = style.world_name,
			viewport = viewport,
			viewport_name = viewport_name,
			ui_renderer = ui_renderer,
			camera = camera
		}
	end,
	destroy = function (ui_renderer, pass_data, pass_definition)
		local world = pass_data.world
		local ui_renderer = mod.ui_renderer
		local viewport_name = pass_data.viewport_name

		World.set_data(world, "layer", _original_layer)

		mod.camera = nil
		if world then
			ScriptWorld.destroy_viewport(world, viewport_name)
		end
		Application.update_render_world(world)


		mod.viewport = nil

		mod.active = false
		mod._character_offset = 0
		if pass_data.ui_renderer then
			UIRenderer.destroy(ui_renderer, world)
		end
	end,
	draw = function (ui_renderer, pass_data, ui_scenegraph, pass_definition, ui_style, ui_content, position, size, input_service, dt)
		local viewport = mod.viewport
		-- sync cam
		if not mod.active then
			mod:echo("not active, bye")
			return
		end
		if not mod.camera then
			mod:echo("not cam, baby")
			return
		end

		local far = 10000
		local near = 100
		local height = 200
		local area = 12

		-- mod:dump(pass_data, "pass_data", 2)
		
		if ui_content.settings then
			-- mod:dump(ui_content, "ui_content", 2)
			far = ui_content.settings.far
			near = ui_content.settings.near
			height = ui_content.settings.height
			area = ui_content.settings.area
		end
		mod.camera:sync(nil, far, near, height, area, dt)
		-- alignment for viewport
		local resx = RESOLUTION_LOOKUP.res_w
		local resy = RESOLUTION_LOOKUP.res_h
		local inv_scale = RESOLUTION_LOOKUP.inv_scale
		local w = resx * inv_scale
		local h = resy * inv_scale

		Viewport.set_data(
			viewport,
			"rect",
			{
				position.x / w,
				position.y / h,
				size.x / w,
				size.y / h
			}
		)
		Viewport.set_rect(viewport, unpack(Viewport.get_data(viewport, "rect")))
		Viewport.set_data(viewport, "layer", 999)
		pass_data.viewport_rect_pos_x = position.x
		pass_data.viewport_rect_pos_y = position.y
		pass_data.viewport_rect_size_x = size.x
		pass_data.viewport_rect_size_y = size.y

		-- shading env adjustements
		local shading_env = World.get_data(pass_data.world, "shading_environment")
		ShadingEnvironment.set_scalar(shading_env, "fog_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "dof_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "motion_bur_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "outline_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "sun_shadows_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "ssm_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "exposure", 0.04)
		ShadingEnvironment.set_scalar(shading_env, "exposure_auto_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "bloom_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "ssm_constant_update_enabled", 0)
		ShadingEnvironment.set_scalar(shading_env, "reset_luminance_adaption", 0)

		local exp = ShadingEnvironment.scalar(shading_env, "exposure")
		-- mod:echo(exp)
		ShadingEnvironment.apply(shading_env)
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