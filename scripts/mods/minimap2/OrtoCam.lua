local mod = get_mod("minimap2")

-- HELPER CLASS FOR THE CAMERA AND VIEWPORT
local MinimapOrtoCam = class()
function MinimapOrtoCam:init(world, viewport)
    camera_unit = World.spawn_unit(world, "core/units/camera")

    local camera = Unit.camera(camera_unit, "camera")
    Camera.set_data(camera, "unit", camera_unit)

    local shadow_cull_camera = Unit.camera(camera_unit, "shadow_cull_camera")
    Camera.set_data(shadow_cull_camera, "unit", camera_unit)

    if viewport then
        self.viewport = viewport
        Viewport.set_data(viewport, "camera", camera)
        Viewport.set_data(viewport, "shadow_cull_camera", shadow_cull_camera)
    end

    ScriptWorld._update_render_queue(world)

    self.world = world
    self.camera = camera
    self.shadow_cull_camera = shadow_cull_camera
    self.height = 1
    self.far = 100
    self.near = 2
    self.area = 30

    return {
        camera = camera,
        shadow_cull_camera = shadow_cull_camera
    }
end


-- moves the orto cam above the current player position
function MinimapOrtoCam:sync(dt)
    mod:echo("sync")
    local world = self.world
    local viewport = self.viewport
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
    
    -- sync position with player character
	local player_position = Unit.local_position(local_player_unit, 0)
	local camera_position_new = Vector3.zero()
	camera_position_new.x = player_position.x
	camera_position_new.y = player_position.y

    -- we also need the position of the original camera


	camera_position_new.z = height
	local direction = Vector3.normalize(Vector3(0, 0, -1))
	local rotation = Quaternion.look(direction)

	ScriptCamera.set_local_position(camera, camera_position_new)
	ScriptCamera.set_local_rotation(camera, rotation)
	ScriptCamera.set_local_position(shadow_cull_camera, camera_position_new)
	ScriptCamera.set_local_rotation(shadow_cull_camera, rotation)

	Camera.set_projection_type(camera, Camera.ORTHOGRAPHIC)
	Camera.set_projection_type(shadow_cull_camera, Camera.ORTHOGRAPHIC)

	local cfar = height + far
	local cnear = height - near
	Camera.set_far_range(camera, cfar)
	Camera.set_near_range(camera, cnear)
	Camera.set_far_range(shadow_cull_camera, cfar)
	Camera.set_near_range(shadow_cull_camera, cnear)

	local scroll = math.min(math.max(0.2, 1), 10.0) -- at least 1/5 of setting and max 10x setting
	local min = area * -1 * scroll
	local max = area * scroll
	Camera.set_orthographic_view(camera, min, max, min, max)
	Camera.set_orthographic_view(shadow_cull_camera, min, max, min, max)

	local s = 20 / 100 -- mod:get("size")
	local xmin = 1 - s
	Viewport.set_data(
		viewport,
		"rect",
		{
			xmin,
			0,
			s,
			s
		}
	)
	Viewport.set_rect(viewport, unpack(Viewport.get_data(viewport, "rect")))
end