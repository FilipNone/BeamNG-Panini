-- lua/ge/extensions/panini/ui.lua
-- ImGui-based UI window for the Panini Projection mod.

local M = {}

local im = ui_imgui

-- Window state
local windowVisible = false
local windowDocked = false

-- Get the main module
local function getMain()
  return extensions.panini_main
end

-- Toggle window visibility
M.toggleWindow = function(visible)
  if visible ~= nil then
    windowVisible = visible
  else
    windowVisible = not windowVisible
  end
end

M.isVisible = function()
  return windowVisible
end

-- Render the window
local function renderWindow()
  local main = getMain()
  if not main then return end
  
  -- Set window flags
  local flags = im.ImGuiWindowFlags_None
  if windowDocked then
    flags = flags + im.ImGuiWindowFlags_NoCollapse
  end
  
  -- Use the window visibility variable directly for the checkbox binding
  local isVisible = windowVisible
  if im.Begin("Panini Projection", isVisible, flags) then
    main.ui.render()
    
    -- Docking options (right-click context)
    if im.BeginPopupContextWindow("PaniniContext") then
      if im.Selectable("Dock Window") then
        windowDocked = true
      end
      if im.Selectable("Undock Window") then
        windowDocked = false
      end
      im.EndPopup()
    end
  end
  im.End()
end

-- Called every frame when the window is visible
M.onFrame = function()
  if not windowVisible then return end
  renderWindow()
end

-- Called when the UI state changes (for CEF integration)
M.onUiChangedState = function(new)
  -- Could be used to hide window when in menus
end

-- Extension lifecycle
M.onExtensionLoaded = function()
  -- Window starts hidden by default
  windowVisible = false
  
  -- Register this module globally for access from input bindings
  rawset(_G, "panini_ui_toggle", function()
    M.toggleWindow()
  end)
end

M.onExtensionUnloaded = function()
  windowVisible = false
  rawset(_G, "panini_ui_toggle", nil)
end

return M