local mod = get_mod("minimap2")
mod:dofile("scripts/mods/minimap2/OrtoCam")
-- Pass definition slightly changed from original UIPasses.viewport from scripts/ui/ui_passes

local VIEWPORT_NAME = "minimap_viewport"
local _original_layer = 0

-- hook that uses existing code from scripts/util/script_world.lua and adds special case for minimap_viewport
mod:hook(
	ScriptWorld,
	"render",
	function(func, world)
		local shading_env = World.get_data(world, "shading_environment")

		if not shading_env then
			return
		end
	
		local global_free_flight_viewport = World.get_data(world, "global_free_flight_viewport")
	
		if global_free_flight_viewport then
			ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"))
			ShadingEnvironment.apply(shading_env)
	
			if World.has_data(world, "shading_callback") and not Viewport.get_data(global_free_flight_viewport, "avoid_shading_callback") then
				local callback = World.get_data(world, "shading_callback")
	
				callback(world, shading_env, World.get_data(world, "render_queue")[1])
			end
	
			local camera = ScriptViewport.camera(global_free_flight_viewport)
	
			Application.render_world(world, camera, global_free_flight_viewport, shading_env)
		else
			local render_queue = World.get_data(world, "render_queue")
	
			if table.is_empty(render_queue) then
				Application.update_render_world(world)
	
				return
			end
	
			for _, viewport in ipairs(render_queue) do
				if not World.get_data(world, "avoid_blend") then
					ShadingEnvironment.blend(shading_env, World.get_data(world, "shading_settings"), World.get_data(world, "override_shading_settings"))
				end
	
				if World.has_data(world, "shading_callback") and not Viewport.get_data(viewport, "avoid_shading_callback") then
					local callback = World.get_data(world, "shading_callback")
	
					callback(world, shading_env, viewport)
				end
	
				if not World.get_data(world, "avoid_blend") then
					ShadingEnvironment.apply(shading_env)
				end
	
				local camera = ScriptViewport.camera(viewport)
	
				Application.render_world(world, camera, viewport, shading_env)
			end
		end
	end
)

mod:hook(ScriptWorld, "create_shading_environment", function (func, world, shading_environment_name, shading_callback, mood_setting)
	local shading_env = World.create_shading_environment(world, shading_environment_name)
	mod.shading_env = World.create_shading_environment(world, shading_environment_name)
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

		Viewport.set_data(viewport, "layer", element_layer)
		_original_layer = World.get_data(world, "layer")

		World.set_data(world, "layer", element_layer)
		Application.update_render_world(world)

		Viewport.set_data(viewport, "active", true)
		Viewport.set_data(viewport, "name", viewport_name)
	
		viewports[viewport_name] = viewport
	
		Viewport.set_data(viewport, "avoid_shading_callback", true)
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
--		local far = ui_content.far
		mod.camera:sync(nil, nil, nil, nil, dt)
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