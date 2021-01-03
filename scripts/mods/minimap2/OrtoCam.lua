local mod = get_mod("minimap2")

-- HELPER CLASS FOR THE CAMERA AND VIEWPORT
MinimapOrtoCam = class(MinimapOrtoCam)
MinimapOrtoCam.init = function(self, world, viewport, player)
	self.world = world
	self.viewport = viewport
	self.player = player
    camera_unit = World.spawn_unit(world, "core/units/camera")
    local camera = Unit.camera(camera_unit, "camera")
    Camera.set_data(camera, "unit", camera_unit)

    local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")
    Camera.set_data(shadow_cull_camera, "unit", camera_unit)
	
	-- remember old camera
	self.o_camera = Viewport.get_data(viewport, "camera")
	self.o_shadow = Viewport.get_data(viewport, "shadow_cull_camera")

	Viewport.set_data(viewport, "camera", camera)
	Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)
	ScriptWorld._update_render_queue(world)

	self.camera = camera
    self.shadow_cull_camera = shadow_cull_camera
    self.height = 2000
    self.far = 10000
    self.near = 100
    self.area = 12

    return {
        camera = camera,
        shadow_cull_camera = shadow_cull_camera
    }
end

MinimapOrtoCam.destroy = function(self)
	local camera = Viewport.get_data(self.viewport, "camera")
	local camera_unit = Camera.get_data(self.camera, "unit")
	World.destroy_unit(self.world, camera_unit)
	ScriptWorld._update_render_queue(world)
end


-- moves the orto cam above the current player position
MinimapOrtoCam.sync = function(self, lookAt, far, near, height, dt)
    local world = mod.world
    local viewport = mod.viewport
    local camera = self.camera
    local shadow_cull_camera = self.shadow_cull_camera
    local height = self.height
    local far = self.far
    local near = self.near
    local area = self.area

    -- only move the camera if a player unit exists
    local local_player_unit = Managers.player:local_player().player_unit
	if not local_player_unit then
		return
    end
	
	local settings = {
		height = 200,
		far = 10000,
		near = 100
	}
	local level = mod:_get_level_settings()
	if level then
		settings = level.settings
	end

    -- sync position with player character
	local player_position = Unit.local_position(local_player_unit, 0)
	local camera_position_new = Vector3.zero()
	camera_position_new.x = player_position.x
	camera_position_new.y = player_position.y

	local cameraHeight = height or settings.height or 200
	local zfar = far or settings.far or 10000
    local znear = near or settings.near or 100
    
	camera_position_new.z = height
	local dir = {
		x = 0,
		y = 0, 
		z = -1
	}
	if lookAt then
		dir = lookAt
	end
	local direction = Vector3.normalize(Vector3(dir.x, dir.y, dir.z))
	local rotation = Quaternion.look(direction)

	ScriptCamera.set_local_position(camera, camera_position_new)
	ScriptCamera.set_local_rotation(camera, rotation)
	ScriptCamera.set_local_position(shadow_cull_camera, camera_position_new)
	ScriptCamera.set_local_rotation(shadow_cull_camera, rotation)

	Camera.set_projection_type(camera, Camera.ORTHOGRAPHIC)
	Camera.set_projection_type(shadow_cull_camera, Camera.ORTHOGRAPHIC)

	local cfar = cameraHeight + zfar
	local cnear = cameraHeight - znear
	Camera.set_far_range(camera, cfar)
	Camera.set_near_range(camera, cnear)
	Camera.set_far_range(shadow_cull_camera, cfar)
	Camera.set_near_range(shadow_cull_camera, cnear)

	local scroll = math.min(math.max(0.2, 1), 10.0) -- at least 1/5 of setting and max 10x setting
	local min = area * -1 * scroll
	local max = area * scroll
	Camera.set_orthographic_view(camera, min, max, min, max)
	Camera.set_orthographic_view(shadow_cull_camera, min, max, min, max)

end

