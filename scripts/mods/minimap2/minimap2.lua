local mod = get_mod("minimap2")

mod:dofile("scripts/mods/minimap2/MiniMapUIPass")

mod.active = false
mod._level_settings = {}
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

Minimap3DView._setup_data = function(self, data)
    data.global = {
        debug = false,
        active = false,
        projection_type = Camera.PERSPECTIVE,
        orthographic_data = {
            size = 100
        }
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
    self:draw(dt)
    self:_update_transition_timer(dt)
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

--[[
  This method is called when ingame_ui performs a transition which results in this view becoming active.
  'transition_params' is an optional argument. You'll get one if you pass it to `mod:handle_transition(...)`. It will
  also be passed to a transition function.
--]]
function Minimap3DView:on_enter(transition_params)
    mod:echo("on_enter")
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
    WwiseWorld.trigger_event(self._wwise_world_sound, "Play_hud_trophy_open")
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
    mod:echo("on_exit")
    self:destroy_ui_elements()
    WwiseWorld.trigger_event(self._wwise_world_sound, "Play_hud_button_close")
end
  
  
--[[ (OPTIONAL)
  This method is called when ingame_ui wants to destroy your view. It's always called when ingame_ui is destroyed at
  the end of the level and in some exotic situations.
--]]
function Minimap3DView:destroy()
    mod:echo("destroy")
end

--[[
  It is used by ingame_ui to grab view's input service to perform some necessary actions under the hood.
--]]
function Minimap3DView:input_service()
    return self.input_manager:get_service(self._input_service_name)
end

function Minimap3DView:create_ui_elements()
    mod:echo("create_ui_elements")
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

    UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

function Minimap3DView:destroy_ui_elements()
    mod:echo("destroy_ui_elements")
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
  	-- local confirm_button = widgets_by_name.confirm_button

	UIWidgetUtils.animate_default_button(exit_button, dt)
	--UIWidgetUtils.animate_default_button(confirm_button, dt)
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
        WwiseWorld.trigger_event(self._wwise_world_sound, "play_gui_equipment_button_hover")
	end

	if input_pressed or self:_is_button_pressed(exit_button) then
		self:exit()
	end
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
    mod:echo(anim_id)
	self._ui_animations[key] = anim_id
end

function Minimap3DView:_is_button_pressed(widget)
	local button_hotspot = widget.content.button_hotspot

	if button_hotspot.on_release then
		button_hotspot.on_release = false

		return true
	end
end

function Minimap3DView:_is_button_hover_enter(widget)
	local content = widget.content
	local hotspot = content.button_hotspot

	return hotspot.on_hover_enter
end





-- function Minimap3DView:print_game_location()
--     local ingame_ui = self.ingame_ui

--     -- on screen text
--     local player = Managers.player:local_player()
--     local local_player_unit = player.player_unit
--     local player_position = Unit.local_position(local_player_unit, 0)
--     local w, h = Application.resolution()
--     local pos = Vector3(20, h - 25, 5)
--     local pos_string = "pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos
--     if self.widgets and self.widgets.debug_text then
--         mod:echo(pos_string)
--         self.widgets.debug_text.content.text = pos_string
--     end
--     --self:_show_text("viewport_world_name" .. player.viewport_world_name, pos)
-- end

-- function Minimap3DView:_show_text(text, pos)
-- 	Gui.text(self.ui_top_renderer.gui, text, "materials/fonts/gw_head", 20, "gw_head", pos, Color(0, 255, 0))
-- 	return Vector3(pos[1], pos[2] - 30, pos[3])
-- end
  
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

mod.ee = function(dt) 

    if not mod.view then
        return
    end

    local debug = mod.view.debug
    local active = mod.view.active

    if debug then
        -- mod.view:print_game_location()
    end

	if not mod._level_settings then
		mod:_get_level_settings()
	end

	if not active then
		return
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
mod._get_level_settings = function(self)
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
    local level_key = level_transition_handler:get_current_level_keys()
    if level_key == "inn_level_sonnstill" then
        level_key = "inn_level"
    end
    mod._level_key = level_key
    -- mod:echo(level_key)
    if not mod._level_settings[level_key] then
        mod._level_settings[level_key] = dofile("scripts/mods/minimap2/level_settings")[level_key]
    end 
	return mod._level_settings[level_key]
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)