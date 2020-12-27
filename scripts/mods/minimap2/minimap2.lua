local mod = get_mod("minimap2")

mod:dofile("scripts/mods/minimap2/MiniMapUIPass")
mod:dofile("scripts/mods/minimap2/OrtoCam")

mod.active = false
mod._level_settings = nil

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

function Minimap3DView:getViewport()
    mod:echo("getViewport")
    if not self.widgets then
        return
    end
    return self.widgets.map_viewport.element.pass_data[1]
end

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
    mod:echo("init")
    self._world_name = "minimap_3d_world"
    self._viewport_name = "minimap_3d_viewport"
    local level_settings = LevelHelper:current_level_settings()
    self._level_name = level_settings.level_name

    self._input_service_name = "minimap_3d_input"
    self.debug = false
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.ui_top_renderer = ingame_ui_context.ui_top_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.statistics_db = ingame_ui_context.statistics_db
	self.stats_id = ingame_ui_context.stats_id
    self.input_manager = ingame_ui_context.input_manager
    self.world_manager = ingame_ui_context.world_manager
	self.render_settings = {
		snap_pixel_positions = true
	}
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

    -- Create wwise_world which is used for making sounds (for opening view, closing view, etc.)
    self.world = self.world_manager:world("level_world")
    self.wwise_world = self.world_manager:wwise_world(self.world)
    
    if not mod.view then
        self:create_ui_elements()
    end
    mod.view = self

    -- safe some references to previous world and viewport
    self.o_world_name = Managers.player:local_player().viewport_world_name
    self.o_viewport_name = Managers.player:local_player().viewport_name
    self.world = self:getViewport().world
    self.viewport = self:getViewport().viewport

    mod:echo("Custom View initialized.")
end

-- #####################################################################################################################
-- ##### Methods required by ingame_ui #################################################################################
-- #####################################################################################################################

--[[
  This method is called every frame when this view is active (has player's focus). You should use it to draw widgets,
  manage view's state, listen to some events, etc.
--]]
function Minimap3DView:update(dt)
    -- Listen to 'toggle_menu' event and perform 'minimap_3d_view_close' transition when it's triggered.
    local input_service = self:input_service()
    if input_service:get("toggle_menu") then
        mod:handle_transition("minimap_3d_view_close", true, false, "optional_transition_params_string")
    end
  
    -- Draw ui elements.
    if not self.widgets then
        return
    end
    self:draw(dt)
end


--[[
  This method is called when ingame_ui performs a transition which results in this view becoming active.
  'transition_params' is an optional argument. You'll get one if you pass it to `mod:handle_transition(...)`. It will
  also be passed to a transition function.
--]]
function Minimap3DView:on_enter(transition_params)
    mod:echo("on_enter")
    local world_manager = self.world_manager
    local viewport_widget = self.widgets.map_viewport

    local status, result = pcall(world_manager:world(self.o_world_name))
    if not status then
        self.o_world = Managers.world:world(self.o_world_name)
        self.o_viewport = ScriptWorld.viewport(self.o_world, self.o_viewport_name)
    end

    if viewport_widget then
        mod:echo("switch to custom viewport")
        --ScriptWorld.deactivate_viewport(self.o_world, self.o_viewport)

        if not self.camera then
            mod:echo("creat ortho cam")
            self.camera = MinimapOrtoCam:new(self.world, self.viewport, self.o_viewport)
        end
        ScriptWorld.activate_viewport(self.world, self.viewport)
    end
    self.active = true

    mod:echo("Custom View opened. transition_params: %s", transition_params)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_open")
end



--[[
  Everything is the same as for `Minimap3DView:on_enter(...)`. But this method is called if a transition resulted in
  this view becoming inactive.
--]]
function Minimap3DView:on_exit(transition_params)
    mod:echo("on_exit")
    -- happily copied from character_selection_view.lua:suspend (l:573)
    local viewport_widget = self.widgets.map_viewport

    if viewport_widget then
        mod:echo("switch to original viewport")
        local previewer_pass_data = viewport_widget.element.pass_data[1]
        local viewport = previewer_pass_data.viewport
        local world = previewer_pass_data.world

        ScriptWorld.deactivate_viewport(self.world, self.viewport)
    
        --ScriptWorld.activate_viewport(self.o_world, self.o_viewport)

        self.active = false
    end

    mod:echo("Custom View closed. transition_params: %s", transition_params)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_close")
end
  
  
--[[ (OPTIONAL)
  This method is called when ingame_ui wants to destroy your view. It's always called when ingame_ui is destroyed at
  the end of the level and in some exotic situations.
--]]
function Minimap3DView:destroy()
    mod:echo("destroy")
    Managers.world:destroy_world(self._world_name)
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
    self.widgets = {}
    for widget_name, widget_definition in pairs(DEFINITIONS.widgets_definition) do
        mod:echo("init widget")
        mod:echo(widget_name)
        if widget_name == "viewport" then
            widget_definition.style.viewport.viewport_name = self._viewport_name
            widget_definition.style.viewport.world_name = self._world_name
            if not widget_definition.style.viewport.level_name then
                widget_definition.style.viewport.level_name = self._level_name
            end
        end
        mod:dump(widget_definition, "widget definition", 3)
        self.widgets[widget_name] = UIWidget.init(widget_definition)
    end
end

function Minimap3DView:destroy_ui_elements()
    mod:echo("destroy_ui_elements")
    self.scenegraph = UISceneGraph.init_scenegraph(DEFINITIONS.scenegraph_definition)
  
    self.widgets = {}
    for widget_name, widget_definition in pairs(DEFINITIONS.widgets_definition) do
        self.widgets[widget_name] = UIWidget.init(widget_definition)
    end
end

function Minimap3DView:draw(dt)
	local ui_top_renderer = self.ui_top_renderer
    local render_settings = self.render_settings
    local scenegraph      = self.scenegraph
    local input_service   = self:input_service()
    local camera = self.camera
    local active = self.active
    local viewport = self.widgets.map_viewport
    
    UIRenderer.begin_pass(ui_top_renderer, scenegraph, input_service, dt, nil, render_settings)
    
    if viewport then
		UIRenderer.draw_widget(ui_top_renderer, viewport)
	end
    
    UIRenderer.end_pass(ui_top_renderer)
    
    if active and camera then
        camera:sync(dt)
    end
end

function Minimap3DView:print_game_location()
    local ingame_ui = self.ingame_ui

    -- on screen text
    local local_player_unit = Managers.player:local_player().player_unit
    local player_position = Unit.local_position(local_player_unit, 0)
    local w, h = Application.resolution()
    local pos = Vector3(20, h - 25, 5) 
    pos = self:_show_text("pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos)
end

function Minimap3DView:_show_text(text, pos)
	Gui.text(self.ui_renderer.gui, text, "materials/fonts/gw_head", 20, "gw_head", pos, Color(0, 255, 0))
	return Vector3(pos[1], pos[2] - 30, pos[3])
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

            --ingame_ui.input_manager:block_device_except_service("minimap_3d_view", "keyboard", 1)
            --ingame_ui.input_manager:block_device_except_service("minimap_3d_view", "mouse", 1)
            ingame_ui.input_manager:block_device_except_service("minimap_3d_view", "gamepad", 1)

            ingame_ui.menu_active = true
            ingame_ui.current_view = "minimap_3d_view"
        end,

        -- This transition hides mouse cursor, unblocks all input services and sets current view to nil.
        minimap_3d_view_close = function(ingame_ui, transition_params)
            ShowCursorStack.pop()

            ingame_ui.input_manager:device_unblock_all_services("keyboard", 1)
            ingame_ui.input_manager:device_unblock_all_services("mouse", 1)
            ingame_ui.input_manager:device_unblock_all_services("gamepad", 1)

            ingame_ui.menu_active = false
            ingame_ui.current_view = nil
        end
    }
}
-- mod:register_view(view_data)

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

mod.update = function(dt) 
    if not mod.view then
        return
    end

    local debug = mod.view.debug
    local active = mod.view.active

    if debug then
        mod.view:print_game_location()
    end

	if not mod._level_settings then
		mod._level_settings = mod:_get_level_settings()
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
	local local_player_unit = Managers.player:local_player().player_unit
    local player_position = Unit.local_position(local_player_unit, 0)
    if mod.view then
        mod.view:_show_text(player_position)
    end
end


-- loads custom settings (such as specific camera preferences) for currently loaded level
mod._get_level_settings = function(self)
    mod:echo("get_level_settings")
	local level_transition_handler = Managers.state.game_mode.level_transition_handler
    local level_key = level_transition_handler:get_current_level_keys()
    if level_key == "inn_level_sonnstill" then
        level_key = "inn_level"
    end
	mod._level_key = level_key
	mod:echo(level_key)
	return dofile("scripts/mods/minimap2/level_settings")[level_key]
end

mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)