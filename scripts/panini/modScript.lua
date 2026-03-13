-- scripts/panini/modScript.lua
-- Mod initialization script for Panini Projection.

-- Set manual unload mode for both extensions
setExtensionUnloadMode("panini_main", "manual")
setExtensionUnloadMode("panini_ui", "manual")

-- Register input category for Panini controls
if core_input_categories then
  core_input_categories.panini = {
    desc = "Keybind Controls for Panini Projection",
    order = 1.75,
    title = "Panini Projection",
    icon = "photo_filter"
  }
end

-- Input action for toggling the UI window
-- This creates a bindable action that can be mapped in the controls menu
if core_input_actions then
  core_input_actions.panini_toggle_ui = {
    category = "panini",
    action = "panini_toggle_ui",
    desc = "Toggle Panini UI Window",
    defaultBindings = {
      {type = "keyboard", key = "F7"}
    }
  }
end

-- Register the action handler
if core_action_manager then
  core_action_manager:registerAction("panini_toggle_ui", function()
    if panini_ui then
      panini_ui.toggleWindow()
    end
  end)
end

-- Auto-load the extensions when the mod starts
extensions.load("panini_main")
extensions.load("panini_ui")