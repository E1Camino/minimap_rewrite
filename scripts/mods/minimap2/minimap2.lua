local mod = get_mod("minimap2")


local pl = require'pl.import_into'()
fassert(pl, "Minimap must be lower than Penlight Lua Libraries in your launcher's load order.")

mod:dofile("scripts/mods/minimap2/MiniMapUIPass")

mod.active = false
mod._level_settings = {}
mod._level_key = nil
local input_service_name = "minimap_3d_input"

local DEFINITIONS = mod:dofile("scripts/mods/minimap2/minimap_3d_definitions")

-- A view by itself is just a table with several callbacks required by ingame_ui. How it will behave is completely up to
-- you. In this example I'm going to create a simple view which can be toggled with a keybind. It will draw 2 rectangles
-- which are highlighted when hovered. I won't explain anything related to widget definitions, their creating, and
-- drawing because this is a different topic.

-- We're going to use Fatshark's class system to instantiate this view ('foundation/scripts/util/class.lua').
-- This means every time you execute `CustomView:new(...)`, it returns a new table which has all the
-- CustomView methods defined below and also executes `CustomView:init(...)`.


-- MOD STATE AND LOGIC
local Minimap3DView = class()

--[[
  This method is executed every time we create a new instance of 'Minimap3DView'. The passed 'ingame_ui_context'
  parameter is a table, which contains everything that is needed for operating this view: renderer, input manager,
  world information, etc.
  Every time the level changes, the 'ingame_ui_context's contents are changed as well, so we want some callback to grab the
  latest 'ingame_ui_context' every time this happens. There's 'init_view_function' inside 'view_data' which does
  exactly that.
  In this example we don't update ingame UI context inside view. We just create a new instance of view every time
  'init_view_function' is called.
--]]
function Minimap3DView:init(ingame_ui_context)
    -- mod:echo("init")
    self.data = {}
    self:_setup_data(self.data)
    
    self._world_name = "minimap_3d_world"
    self._viewport_name = "minimap_3d_viewport"
    self._has_terrain = not not rawget(_G, "TerrainDecoration")

    self._input_service_name = input_service_name
	self.ui_renderer = ingame_ui_context.ui_renderer
    self.ui_top_renderer = ingame_ui_context.ui_top_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.statistics_db = ingame_ui_context.statistics_db
	self.stats_id = ingame_ui_context.stats_id
    self.input_manager = ingame_ui_context.input_manager
    self.world_manager = ingame_ui_context.world_manager
	self._render_settings = {
	    snap_pixel_positions = true
    }

    self.current_location_inside = nil
    
    -- used for map view animations (e.g. zoom animations)
    self._animations = {}
    -- used for general widget animations (e.g. button hover or smooth transitions of 2d ui elements)
    self._ui_animations = {}

    -- Create input service named 'minimap_3d_view', listening to keyboard, mouse and gamepad inputs,
    -- and set its keymaps and filters as 'IngameMenuKeymaps' and 'IngameMenuFilters'
    -- (which are defined inside scripts/settings/controller_settings.lua)
    --
    -- In this example we'll need input service for several things:
    --
    -- 1. Listen to 'toggle_menu' event to close this view. We're using input service and not directly listening to key
    --    presses, because user may want to rebind it. For example, default buttons to trigger 'toggle_menu' event are
    --    'Esc' for keyboard, 'Start' for xb1 controller, and 'Options' for ps4 controller.
    -- 2. Return it in `Minimap3DView:input_service()` call, which is used by ingame_ui to do its magic related to
    --    chat window, popup windows and what else.
    -- 3. Use it in UIRenderer passes when drawing widgets to detect and process mouse clicks.
    local input_manager = ingame_ui_context.input_manager
	input_manager:create_input_service(self._input_service_name, "IngameMenuKeymaps", "IngameMenuFilters")
	input_manager:map_device_to_service(self._input_service_name, "keyboard")
	input_manager:map_device_to_service(self._input_service_name, "mouse")
	input_manager:map_device_to_service(self._input_service_name, "gamepad")
    self.input_manager = input_manager

    -- -- Create wwise_world which is used for making sounds (for opening view, closing view, etc.)
    local world = self.world_manager:world("level_world")
    self._wwise_world_sound = self.world_manager:wwise_world(world)
    mod.view = self

    rawset(_G, "minimap_ui", self)
end

function Minimap3DView:exit()
    mod:handle_transition("minimap_3d_view_close", true, false, "optional_transition_params_string")
end

local default_viewport_settings = {
    near = 100,
    far = 10000,
    area = 12,
    height = 110,
}

Minimap3DView._setup_data = function(self, data)
    -- should change when user clicks stuff in the ui
    data.viewport = default_viewport_settings
    data.shading_env_settings = {
        fog_enabled = 0,
        dof_enabled = 0,
        motion_bur_enabled = 0,
        outline_enabled = 0,
        sun_shadows_enabled = 0,
        ssm_enabled = 0,
        exposure = 0.04,
        exposure_auto_enabled = 0,
        bloom_enabled = 0,
        ssm_constant_update_enabled = 0,
        reset_luminance_adaption = 0,
        eye_adaption_enabled = 0
    }
    data.use_custom_shading = false
    -- should change when player is in certain map / area with label
    data.level_settings = {
        map_name = "",
        location_ = "location_keep_armoury",
        location_key = ""
    }
    data.location = {
        name = "",
        key = "",
        settings = {}
    }
end


-- #####################################################################################################################
-- ##### Methods required by ingame_ui #################################################################################
-- #####################################################################################################################

--[[
  This method is called every frame when this view is active (has player's focus). You should use it to draw widgets,
  manage view's state, listen to some events, etc.
--]]
function Minimap3DView:update(dt)
    if not mod.player then
        mod.player = Managers.player:local_player()
    end

    -- Draw ui elements.
    if not self.widgets then
        return
    end
 
    self:_update_map_settings()
    self:_update_labels()
    self:draw(dt)
    self:_update_transition_timer(dt)
end

function Minimap3DView:_update_labels()
    local key = "V2"
    local display_name = "V2"
    if mod._level_key then
        key = mod._level_key
        display_name = key
        local settings = LevelSettings[key]
        if settings then
            display_name = settings.display_name
        end
    end
    if self._widgets_by_name.title_text then
        self._widgets_by_name.title_text.content.text = Localize(display_name)
    end
    if self._widgets_by_name.poi_panel_text then
        if self.data.location.name then
           self._widgets_by_name.poi_panel_text.content.text = self.data.location.name
        end
    end
    if self._widgets_by_name.viewport_setting_tooltip then
        local player = Managers.player:local_player()
        local local_player_unit = player.player_unit
        local player_position = Unit.local_position(local_player_unit, 0)
        local pos_string = "pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos
        local v = self.data.viewport
        local setting_string = "h: " .. v.height .. ", a: " .. v.area .. ", n:" .. v.near .. ", f:" .. v.far .. " " .. pos_string
        if mod.shading_env_name then
            setting_string = setting_string .. " " .. mod.shading_env_name
        end
        if mod.mood_setting then
            setting_string = setting_string .. " " .. mod.mood_setting
        end
        if self._widgets_by_name.viewport_setting_tooltip.content.tooltip then    
            self._widgets_by_name.viewport_setting_tooltip.content.tooltip.description = setting_string
        else 
            self._widgets_by_name.viewport_setting_tooltip.content.tooltip_text = setting_string
        end
    end

end

function Minimap3DView:_update_map_settings()
    local map_viewport = self._viewport_widget
    if not map_viewport then
        return
    end

    local level_specific_settings = mod:_load_level_settings()

    if not level_specific_settings then
        return
    end
    self:_check_player_location()

    if map_viewport then
        map_viewport.content.settings = self.data.viewport
    end
end

function Minimap3DView:post_update(dt, t)
    if self._ui_animator then
        self._ui_animator:update(dt)
        self:_update_animations(dt)
    end

    if not self._transition_timer then
        self:_handle_input(dt, t)
    end
end

-- location checks (so we can apply camera settings based on the position of the player)
function Minimap3DView:_check_player_location()
    -- get old data
    local current_viewport_settings = default_viewport_settings
    local current_location = self.data.location
    local level_settings = mod:_load_level_settings()

    -- player position
	local local_player_unit = Managers.player:local_player().player_unit
    local position = Unit.local_position(local_player_unit, 0)
    
    -- list of child locations for loaded level settings
    local location_list = level_settings.children

    local hasChildren = location_list

    while (hasChildren) do
		hasChildren = false
		for location_name, location in pairs(location_list) do
			if location_name == "name" or location_name == "settings" then -- ignore the name attribute
			else
				local inside = self:_area_intersection(location, position)
                if inside then
					-- remember this location
					current_location = location
					-- overwrite level settings with more specific ones (declared within this location)
					for setting_key, setting in pairs(location.settings) do
                        current_viewport_settings[setting_key] = setting
                    end
					-- check if this location has child locations and proceed with them
					if location.children then
						hasChildren = true
						location_list = location.children
                    end
				end
			end
		end
    end
    self.data.viewport = current_viewport_settings
    self.data.location = current_location
end

function Minimap3DView:_area_intersection(location, point)
	if location == nil then
		return false
	end
	if location.name == nil then
		-- mod:dump(location, "loc", 3)
	else
		-- check if player is inside polygon
		local type = location.check.type
		if type == "polygon" then
			local pre = self:_pre_calc(location)
			return self:_is_point_in_polygon(point, location.check.features, pre)
		end
		-- check if players is above given height
		if type == "above" then
			return point.z > location.check.height
		end
		-- check if players is above given height
		if type == "below" then
			return point.z < location.check.height
		end
	end

	return false
end

function Minimap3DView:_pre_calc(location)
	-- http://alienryderflex.com/polygon/
	-- only precalc once
	if location._pre then
		return location._pre
	end
	-- we need points to pre calc
	if not location.check.type == "polygon" then
		return
	end
	local points = location.check.features

	--bbox for fast forward checks
	local minX = 10000
	local maxX = -10000
	local minY = 10000
	local maxY = -10000

	-- more advanced preps
	local corners = #points
	local polyX = {}
	local polyY = {}
	local polyZ = {}

	for i, p in pairs(points) do
		polyX[i] = p[1]
		polyY[i] = p[2]
		polyZ[i] = p[3]

		-- bbox
		maxX = math.max(maxX, p[1])
		minX = math.min(minX, p[1])
		maxY = math.max(maxY, p[2])
		minY = math.min(minY, p[2])
	end

	local constant = {}
	local multiple = {}

	local j = corners
	for i = 1, corners do
		if (polyY[j] == polyY[i]) then
			constant[i] = polyX[i]
			multiple[i] = 0
		else
			constant[i] =
				polyX[i] - (polyY[i] * polyX[j]) / (polyY[j] - polyY[i]) + (polyY[i] * polyX[i]) / (polyY[j] - polyY[i])
			multiple[i] = (polyX[j] - polyX[i]) / (polyY[j] - polyY[i])
			j = i
		end
	end

	local pre = {
		corners = corners,
		polyX = polyX,
		polyY = polyY,
		multiple = multiple,
		constant = constant,
		polyX = polyX,
		polyY = polyY,
		bbox = {
			maxX = maxX,
			minX = minX,
			maxY = maxY,
			minY = minY
		}
	}
	location._pre = pre
	return pre
end
function Minimap3DView:_is_point_in_polygon(point, vertices, pre)
	if not pre.corners then
		return false
	end
	-- http://alienryderflex.com/polygon/
	local corners = pre.corners
	local polyX = pre.polyX
	local polyY = pre.polyY
	local multiple = pre.multiple
	local constant = pre.constant
	local x = point.x
	local y = point.y
	local oddNodes = false

	local j = corners
	for i = 1, corners do
		local c1 = (polyY[i] < y and polyY[j] >= y)
		local c2 = (polyY[j] < y and polyY[i] >= y)
		local betweenY = c1 or c2
		if (c1 or c2) then
			local c3 = (y * multiple[i] + constant[i] < x)
			oddNodes = oddNodes ~= c3
		end
		j = i
	end
	return oddNodes
end

function Minimap3DView:_get_pos_above_player()
	-- get the player
	local player_unit = Managers.player:local_player().player_unit
	local player_position = Unit.local_position(player_unit, 0)

	local hitpos_above_player = player_position.z + 6
	return hitpos_above_player
end

--[[
  This method is called when ingame_ui performs a transition which results in this view becoming active.
  'transition_params' is an optional argument. You'll get one if you pass it to `mod:handle_transition(...)`. It will
  also be passed to a transition function.
--]]
function Minimap3DView:on_enter(transition_params)
    -- mod:echo("on_enter")
    if transition_params.wwise_world then
        self._wwise_world = transition_params.wwise_world
    end
    -- used for map view animations (e.g. zoom animations)
    self._animations = {}
    -- used for general widget animations (e.g. button hover or smooth transitions of 2d ui elements)
    self._ui_animations = {}
    local status, result = pcall(Managers.world:world("level_world"))
    if not status then
        local world = Managers.world:world("level_world")
		mod.world = world
        self:create_ui_elements(mod.world, "minimap", "default", 2)
	end
    self:_play_sound("Play_hud_trophy_open")
    if not mod.active then
        --self:_start_transition_animation("on_enter", "on_enter")
    end
    mod.active = true
end



--[[
  Everything is the same as for `Minimap3DView:on_enter(...)`. But this method is called if a transition resulted in
  this view becoming inactive.
--]]
function Minimap3DView:on_exit(transition_params)
    -- mod:echo("on_exit")
    self:destroy_ui_elements()
    self:_play_sound("Play_hud_button_close")
end
  
  
--[[ (OPTIONAL)
  This method is called when ingame_ui wants to destroy your view. It's always called when ingame_ui is destroyed at
  the end of the level and in some exotic situations.
--]]
function Minimap3DView:destroy()
    -- mod:echo("destroy")
end

--[[
  It is used by ingame_ui to grab view's input service to perform some necessary actions under the hood.
--]]
function Minimap3DView:input_service()
    return self.input_manager:get_service(self._input_service_name)
end

function Minimap3DView:create_ui_elements()
    -- mod:echo("create_ui_elements")
    self.scenegraph = UISceneGraph.init_scenegraph(DEFINITIONS.scenegraph_definition)

    if self._viewport_widget then
        UIWidget.destroy(self.ui_renderer, self._viewport_widget)
        self._viewport_widget = nil
    end

    local widgets = {}
    local widgets_by_name = {}
    for widget_name, widget_definition in pairs(DEFINITIONS.widgets_definition) do
        local widget = UIWidget.init(widget_definition)
        widgets[#widgets + 1] = widget
        widgets_by_name[widget_name] = widget
    end

    self.widgets = widgets_by_name
    self._widgets_by_name = widgets_by_name
    self._widgets = widgets

    self._viewport_widget = UIWidget.init(DEFINITIONS.map_viewport)

    self._ui_animator = UIAnimator:new(self._ui_scenegraph, DEFINITIONS.animation_definitions)

    -- slider widget
    -- self:build_slider_widget()

    UIRenderer.clear_scenegraph_queue(self.ui_renderer)
	--return widget


    local gamepad_active = Managers.input:is_device_active("gamepad")
    local widget_name = "map_checkbox"
    local widget = widgets_by_name[widget_name]
    if widget then
        local content = widget.content
        local offset = widget.offset
        local style = widget.style
        local hotspot_content = content.button_hotspot
        local hotspot_style = style.button_hotspot
        local hotspot_size = hotspot_style.size
        local text_style = style.text
        local text_offset = text_style.offset
        local text_width_offset = text_offset[1]
        local ui_renderer = self.ui_renderer
        local text_width = UIUtils.get_text_width(ui_renderer, text_style, hotspot_content.text)
        local total_width = text_width_offset + text_width
        offset[1] = -total_width / 2
        offset[2] = (gamepad_active and 40) or 0
        local tooltip_style = style.additional_option_info
        local tooltip_width = tooltip_style.max_width
        local tooltip_offset = tooltip_style.offset
        tooltip_offset[1] = -(tooltip_width / 2 - total_width / 2)
        hotspot_size[1] = total_width

    end
end

function Minimap3DView:destroy_ui_elements()
    -- mod:echo("destroy_ui_elements")
	rawset(_G, "minimap_ui", nil)
    GarbageLeakDetector.register_object(self, "minimap_ui")

    if self._viewport_widget then
        UIWidget.destroy(self.ui_renderer, self._viewport_widget)
        self._viewport_widget = nil
    end
    if self._widgets_by_name.window then
        UIWidget.destroy(self.ui_renderer, self._widgets_by_name.window)
    end
end 

function Minimap3DView:draw(dt)
    if not mod.active then
        return
    end
    local widgets = self.widgets
    local map_viewport = self._viewport_widget
    local ui_renderer = self.ui_renderer
    local ui_top_renderer = mod._map_ui_renderer or self.ui_top_renderer
    local render_settings = self._render_settings
    local scenegraph      = self.scenegraph
    local input_service   = self:input_service()
    
    UIRenderer.begin_pass(ui_top_renderer, scenegraph, input_service, dt, nil, render_settings)
    for _, widget in pairs(widgets) do
        UIRenderer.draw_widget(ui_top_renderer, widget)
    end
    UIRenderer.end_pass(ui_top_renderer)

    if map_viewport then
        UIRenderer.begin_pass(ui_renderer, scenegraph, input_service, dt, nil, render_settings)
        UIRenderer.draw_widget(ui_renderer, map_viewport)
        UIRenderer.end_pass(ui_renderer)
    end
end

function Minimap3DView:_update_animations(dt)
    for name, animation in pairs(self._ui_animations) do
        mod:echo(name)
		-- UIAnimation.update(animation, dt)

		-- if UIAnimation.completed(animation) then
		-- 	self._ui_animations[name] = nil
		-- end
	end

	local animations = self._animations
	local ui_animator = self._ui_animator

	for animation_name, animation_id in pairs(animations) do
		-- if ui_animator:is_animation_completed(animation_id) then
		-- 	ui_animator:stop_animation(animation_id)

		-- 	animations[animation_name] = nil
		-- end
	end

    local widgets_by_name = self._widgets_by_name
    if not widgets_by_name then
        return
    end
--    mod:echo("exit button")
	local exit_button = widgets_by_name.exit_button
	local map_checkbox = widgets_by_name.map_checkbox

    if exit_button then
        UIWidgetUtils.animate_default_button(exit_button, dt)
    end
    if map_checkbox then
        UIWidgetUtils.animate_default_button(map_checkbox, dt)
    end
end

function Minimap3DView:_handle_input(dt, t)
    local widgets_by_name = self._widgets_by_name
    if not widgets_by_name then
        mod:echo("missing widgets_by_name")
        return
    end
	local input_service = self:input_service()
	local input_pressed = input_service:get("toggle_menu", true)
	local gamepad_active = Managers.input:is_device_active("gamepad")
	local back_pressed = gamepad_active and input_service:get("back_menu", true)
	local exit_button = widgets_by_name.exit_button

	UIWidgetUtils.animate_default_button(exit_button, dt)

    if self:_is_button_hover_enter(exit_button) then
        self:_play_sound("play_gui_equipment_button_hover")
	end

	if input_pressed or self:_is_button_pressed(exit_button) then
		self:exit()
    end
    

    local map_checkbox = widgets_by_name.map_checkbox
    if map_checkbox then
        if self:_is_button_released(map_checkbox) or lock_party_size_pressed then
            local content = map_checkbox.content
            content.button_hotspot.is_selected = not content.button_hotspot.is_selected
            self.data.use_custom_shading = content.button_hotspot.is_selected
            self:_play_sound("play_gui_lobby_button_play")
        end
    end
end

function Minimap3DView:_play_sound(event)
	WwiseWorld.trigger_event(self._wwise_world_sound, event)
end

function Minimap3DView:_update_transition_timer(dt)
    if not self._transition_timer then
		return
	end

	if self._transition_timer == 0 then
		self._transition_timer = nil
	else
		self._transition_timer = math.max(self._transition_timer - dt, 0)
	end
end

function Minimap3DView:_start_transition_animation(key, animation_name)
	local params = {
		wwise_world = self._wwise_world,
		render_settings = self._render_settings
	}
	local widgets = {}
    local anim_id = self._ui_animator:start_animation(animation_name, widgets, scenegraph_definition, params)
	self._ui_animations[key] = anim_id
end

function Minimap3DView:_is_button_pressed(widget)
	local button_hotspot = widget.content.button_hotspot

	if button_hotspot.on_release then
		button_hotspot.on_release = false

		return true
	end
end
function Minimap3DView:_is_button_released(widget)
    local content = widget.content
    local hotspot = content.button_hotspot

    if hotspot.on_release then
        hotspot.on_release = false

        return true
    end
end

function Minimap3DView:_is_button_selected(widget)
	local content = widget.content
	local hotspot = content.button_hotspot

	return hotspot.is_selected
end

function Minimap3DView:_is_button_hover_enter(widget)
	local content = widget.content
	local hotspot = content.button_hotspot

	return hotspot.on_hover_enter
end
-- Your mod code goes here.
-- https://vmf-docs.verminti.de
local view_data = {
    view_name = "minimap_3d_view",
    view_settings = {
        -- This function should return view instance. It is called when Ingame UI creates other views
        -- (every time a level is loaded). You don't have to recreate a view instance every time this function is called,
        -- like in this example. You can just create it once somewhere outside of this function and just pass new
        -- `ingame_ui_context` to it. The advantage of not recreating your view every time is it will always remember
        -- its state between levels.
        init_view_function = function (ingame_ui_context)
            return Minimap3DView:new(ingame_ui_context)
        end,
        -- Defines when players will be able to use this view (also, when init_view_function will be called)
        active = {
            inn = true,
            ingame = true
        },
        blocked_transitions = {
            inn = {},
            ingame = {}
        },
        hotkey_name = "minimap_3d_view_open",
        hotkey_action_name = "minimap_3d_view_open",
        hotkey_transition_name = "minimap_3d_view",
        transition_fade = true
    },
    -- You can define different transitions for your view in here, so later you will be able to call
    -- `mod:handle_transition(transition_name, ...)` for different occasions and also use them for your
    -- 'view_toggle' keybinds.
    view_transitions = {

        -- This transition shows mouse cursor if it's not shown already, blocks all input services except the one
        -- named 'minimap_3d_viewminimap_3d_view' and switches current view to 'custom_view'.
        minimap_3d_view_open = function(ingame_ui, transition_params)
            if ShowCursorStack.stack_depth == 0 then
                ShowCursorStack.push()
            end

            ingame_ui.input_manager:block_device_except_service(input_service_name, "keyboard", 1)
            ingame_ui.input_manager:block_device_except_service(input_service_name, "mouse", 1)
            -- ingame_ui.input_manager:block_device_except_service(input_service_name, "gamepad", 1)

            ingame_ui.menu_active = true
            ingame_ui.current_view = "minimap_3d_view"
        end,

        -- This transition hides mouse cursor, unblocks all input services and sets current view to nil.
        minimap_3d_view_close = function(ingame_ui, transition_params)
            ShowCursorStack.pop()

            ingame_ui.input_manager:device_unblock_all_services("keyboard", 1)
            ingame_ui.input_manager:device_unblock_all_services("mouse", 1)
            -- ingame_ui.input_manager:device_unblock_all_services("gamepad", 1)

            ingame_ui.menu_active = false
            ingame_ui.current_view = nil
        end
    }
}
mod:register_view(view_data)

mod.register_manually = function()
    if not mod.view then
        mod:register_view(view_data)
    end
end

mod.toggle_debug_mode = function()
    if not mod.view then
        return
    end

    if mod.view.debug then
        mod.view.debug = false
    else
        mod.view.debug = true
    end
end

mod.on_unload = function(exit_game)
    if not mod.view then
        return
    end
	if mod.view.active then
		mod:destroy_ui_elements()
	end
end

mod.on_disabled = function(is_first_call)
    if not mod.view then
        return
    end
    if mod.view.active then
		mod:destroy_ui_elements()
	end
end

mod.print_debug = function(dt)
    local player = Managers.player:local_player()
	local local_player_unit = player.player_unit
    local player_position = Unit.local_position(local_player_unit, 0)
    if mod.view then
        mod.view:_show_text(player.viewport_world_name)
    end
end


-- loads custom settings (such as specific camera preferences) for currently loaded level
mod._load_level_settings = function(self)
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
    local level_key = level_transition_handler:get_current_level_keys()
    if level_key == "inn_level_sonnstill" then
        level_key = "inn_level"
    end
    if mod._level_key == level_key then
        return mod._level_settings[level_key]
    end
    
    -- level key has changed so we should apply proper map view settings now
    mod._level_key = level_key

    if not mod._level_settings[level_key] then
        mod._level_settings[level_key] = dofile("scripts/mods/minimap2/level_settings")[level_key]
    end
    return mod._level_settings[level_key]
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)