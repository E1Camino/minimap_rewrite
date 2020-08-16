local mod = get_mod("minimap2")

mod:dofile("scripts/mods/minimap2/OrtoCam")

mod.active = false

local DEFINITIONS = mod:dofile("scripts/mods/minimap2/minimap_3d_definitions")

-- MOD STATE AND LOGIC
local Minimap3DView = class()
function Minimap3DView:init(ingame_ui_context)
    self._world_name = "minimap_3d_world"
    self._viewport_name = "minimap_3d_viewport"
    self._input_service_name = "minimap_3d_input"
    self.debug = true
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.ui_top_renderer = ingame_ui_context.ui_top_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.statistics_db = ingame_ui_context.statistics_db
	self.stats_id = ingame_ui_context.stats_id
	self.input_manager = ingame_ui_context.input_manager
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
    -- self.world = ingame_ui_context.world_manager:world("level_world")
    self.world = Managers.world:world("level_world")
    self.wwise_world = Managers.world:wwise_world(self.world)
    
    self:create_ui_elements()

    mod.view = self

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
    self:draw(dt)
end


--[[
  This method is called when ingame_ui performs a transition which results in this view becoming active.
  'transition_params' is an optional argument. You'll get one if you pass it to `mod:handle_transition(...)`. It will
  also be passed to a transition function.
--]]
function Minimap3DView:on_enter(transition_params)
    local viewport_widget = self.widgets.viewport

    if viewport_widget then
        mod:echo("switch to custom viewport")

        local status, result = pcall(Managers.world:world("level_world"))

        if not status then
            local world = Managers.world:world("level_world")
            self.world = world
        end

        self.o_world = Managers.world:world("level_world")
        self.o_viewport = ScriptWorld.viewport(o_world, "player_1")

        ScriptWorld.deactivate_viewport(o_world, o_viewport)

        local previewer_pass_data = viewport_widget.element.pass_data[1]
        self.viewport = previewer_pass_data.viewport
        self.world = Application.main_world()

        if not self.camera then
            self.camera = MinimapOrtoCam:new(self.world, self.viewport)
        end
        ScriptWorld.activate_viewport(self.world, self.viewport)
    end
    mod.active = true

    mod:echo("Custom View opened. transition_params: %s", transition_params)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_open")
end

function Minimap3DView:print_game_location()
    local ingame_ui = self.ingame_ui

    -- on screen text
    local local_player_unit = Managers.player:local_player().player_unit
    local player_position = Unit.local_position(local_player_unit, 0)
    local w, h = Application.resolution()
    local pos = Vector3(20, h - 25, 5) 
    pos = self:_show_text("pos: " .. player_position.x .. ", " .. player_position.y .. ", " .. player_position.z, pos)
--    pos = ingame_ui:_show_text("testasdasd", pos2)
end


function Minimap3DView:_show_text(text, pos)
	Gui.text(self.ui_renderer.gui, text, "materials/fonts/gw_head", 20, "gw_head", pos, Color(0, 255, 0))
	return Vector3(pos[1], pos[2] - 30, pos[3])
end
  
--[[
  Everything is the same as for `Minimap3DView:on_enter(...)`. But this method is called if a transition resulted in
  this view becoming inactive.
--]]
function Minimap3DView:on_exit(transition_params)
    -- happily copied from character_selection_view.lua:suspend (l:573)
    local viewport_widget = self.widgets.viewport

    if viewport_widget then
        mod:echo("switch to original viewport")
        local previewer_pass_data = viewport_widget.element.pass_data[1]
        local viewport = previewer_pass_data.viewport
        local world = previewer_pass_data.world

        ScriptWorld.deactivate_viewport(world, viewport)

        ScriptWorld.activate_viewport(self.o_world, self.o_viewport)

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
    Managers.world:destroy_world(self._world_name)
end

--[[
  It is used by ingame_ui to grab view's input service to perform some necessary actions under the hood.
--]]
function Minimap3DView:input_service()
    return self.input_manager:get_service(self._input_service_name)
end

function Minimap3DView:create_ui_elements()
    self.scenegraph = UISceneGraph.init_scenegraph(DEFINITIONS.scenegraph_definition)
  
    self.widgets = {}
    for widget_name, widget_definition in pairs(DEFINITIONS.widgets_definition) do
        mod:echo(widget_name)
        if widget_name == "viewport" then
            widget_definition.style.viewport.viewport_name = self._viewport_name
            widget_definition.style.viewport.world_name = self._world_name
        end
        mod:dump(widget_definition, "widget definition", 3)
        self.widgets[widget_name] = UIWidget.init(widget_definition)
    end
end

function Minimap3DView:destroy_ui_elements()
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
    local viewport = self.widgets.viewport
    
    UIRenderer.begin_pass(ui_top_renderer, scenegraph, input_service, dt, nil, render_settings)
    
    if viewport then
		UIRenderer.draw_widget(ui_top_renderer, viewport)
	end
    
    UIRenderer.end_pass(ui_top_renderer)
    
    if active and camera then
        camera:sync(dt)
    end
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

            ingame_ui.input_manager:block_device_except_service("minimap_3d_view", "keyboard", 1)
            ingame_ui.input_manager:block_device_except_service("minimap_3d_view", "mouse", 1)
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
mod:register_view(view_data)

mod.toggle_debug_mode = function()
    if mod.view.debug then
        mod.view.debug = false
    else
        mod.view.debug = true
    end
end

mod.update = function(dt)
    
    if mod.view.debug then
        mod.view:print_game_location()
    end
    if not mod.view then
        return
    end
	if not mod.view.active then
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
	mod:echo(player_position)
end
mod:command("m_debug", "Shows debug stuff for Minimap mod", mod.print_debug)