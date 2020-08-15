local mod = get_mod("minimap2")

local DEFINITIONS = mod:dofile("scripts/mods/minimap2/minimap_3d_definitions")

local Minimap3DView = class()
function Minimap3DView:init(ingame_ui_context)
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
	input_manager:create_input_service("minimap_3d", "IngameMenuKeymaps", "IngameMenuFilters")
	input_manager:map_device_to_service("minimap_3d", "keyboard")
	input_manager:map_device_to_service("minimap_3d", "mouse")
	input_manager:map_device_to_service("minimap_3d", "gamepad")
    self.input_manager = input_manager

    -- Create wwise_world which is used for making sounds (for opening view, closing view, etc.)
    self.world = ingame_ui_context.world_manager:world("level_world")
    self.wwise_world = Managers.world:wwise_world(self.world)
    
    self:create_ui_elements()

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
    self._draw_minimap_viewport = true

    if self.widgets.viewport then
        local viewport_name = "player_1"
        local world = Managers.world:world("level_world")
        local viewport = ScriptWorld.viewport(world, viewport_name)

        ScriptWorld.deactivate_viewport(world, viewport)

        local previewer_pass_data = self.widgets.viewport.element.pass_data[1]
        local viewport = previewer_pass_data.viewport
        local world = previewer_pass_data.world

        ScriptWorld.activate_viewport(world, viewport)
    end

    mod:echo("Custom View opened. transition_params: %s", transition_params)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_open")
end
  
  
--[[
  Everything is the same as for `Minimap3DView:on_enter(...)`. But this method is called if a transition resulted in
  this view becoming inactive.
--]]
function Minimap3DView:on_exit(transition_params)
    self._draw_minimap_viewport = false
    -- happily copied from character_selection_view.lua:suspend (l:573)
    local viewport_name = "player_1"
    local world = Managers.world:world("level_world")
    local viewport = ScriptWorld.viewport(world, viewport_name)

    ScriptWorld.activate_viewport(world, viewport)

    local previewer_pass_data = self.widgets.viewport.element.pass_data[1]
    local viewport = previewer_pass_data.viewport
    local world = previewer_pass_data.world

    ScriptWorld.deactivate_viewport(world, viewport)

    mod:echo("Custom View closed. transition_params: %s", transition_params)
    WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_close")
end
  
  
--[[ (OPTIONAL)
  This method is called when ingame_ui wants to destroy your view. It's always called when ingame_ui is destroyed at
  the end of the level and in some exotic situations.
--]]
function Minimap3DView:destroy()
    Managers.world:destroy_world("minimap_3d_world")
end

--[[
  It is used by ingame_ui to grab view's input service to perform some necessary actions under the hood.
--]]
function Minimap3DView:input_service()
    return self.input_manager:get_service("minimap_3d")
end

function Minimap3DView:create_ui_elements()
    self.scenegraph = UISceneGraph.init_scenegraph(DEFINITIONS.scenegraph_definition)
  
    self.widgets = {}
    for widget_name, widget_definition in pairs(DEFINITIONS.widgets_definition) do
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
  
    UIRenderer.begin_pass(ui_top_renderer, scenegraph, input_service, dt, nil, render_settings)
  
    if self.widgets.viewport then
		UIRenderer.draw_widget(ui_top_renderer, self.widgets.viewport)
	end
  
    UIRenderer.end_pass(ui_top_renderer)
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