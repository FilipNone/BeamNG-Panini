-- lua/ge/extensions/panini/main.lua
-- Runtime controller for the Panini Projection PostEffect.
-- Enables/disables the effect and pushes uniform values to the shader.

local M = {}

-- Settings prefix for persistence
local settingsPrefix = "panini_"

-- Default settings
local settings = {
  enabled = true,
  d       = 0.5,   -- panini strength    [0 = off, 1 = full panini]
  s       = 0.0,   -- vertical compress  [0 = none, 1 = full]
  crop    = 1.0,   -- crop to fill       [0 = corners visible, 1 = cropped]
  fov     = 90.0,  -- field of view
}

-- Load settings from disk
local function loadSettings()
  local saved = settings.getValue(settingsPrefix .. "enabled")
  if saved ~= nil then settings.enabled = saved end
  
  saved = settings.getValue(settingsPrefix .. "d")
  if saved ~= nil then settings.d = saved end
  
  saved = settings.getValue(settingsPrefix .. "s")
  if saved ~= nil then settings.s = saved end
  
  saved = settings.getValue(settingsPrefix .. "crop")
  if saved ~= nil then settings.crop = saved end
  
  saved = settings.getValue(settingsPrefix .. "fov")
  if saved ~= nil then settings.fov = saved end
end

-- Save settings to disk
local function saveSettings()
  settings.setValue(settingsPrefix .. "enabled", settings.enabled)
  settings.setValue(settingsPrefix .. "d", settings.d)
  settings.setValue(settingsPrefix .. "s", settings.s)
  settings.setValue(settingsPrefix .. "crop", settings.crop)
  settings.setValue(settingsPrefix .. "fov", settings.fov)
end

-- Push the current settings to the PostEffect shader uniforms.
-- PaniniPostFx is a global Torque engine singleton declared in panini.cs
local function applySettings()
  if not scenetree or not scenetree.PaniniPostFx then
    return
  end

  local pfx = scenetree.PaniniPostFx

  if settings.enabled then
    pfx:enable()
    pfx:setShaderConst("$d",    tostring(settings.d))
    pfx:setShaderConst("$s",    tostring(settings.s))
    pfx:setShaderConst("$crop", tostring(settings.crop))
  else
    pfx:disable()
  end
end

-- Apply FOV setting
local function applyFOV()
  local currentFOV = settings.getValue("FOV")
  if currentFOV ~= nil and currentFOV ~= settings.fov then
    settings.setValue("FOV", settings.fov)
  end
end

-- Public API ----------------------------------------------------------------

-- Enable or disable the effect at runtime.
M.setEnabled = function(v)
  settings.enabled = v
  saveSettings()
  applySettings()
end

M.isEnabled = function()
  return settings.enabled
end

-- Set all three shader parameters at once.
M.setParams = function(d, s, crop)
  settings.d    = d    or settings.d
  settings.s    = s    or settings.s
  settings.crop = crop or settings.crop
  saveSettings()
  applySettings()
end

-- Set individual parameters
M.setD = function(v)
  settings.d = v
  saveSettings()
  applySettings()
end

M.setS = function(v)
  settings.s = v
  saveSettings()
  applySettings()
end

M.setCrop = function(v)
  settings.crop = v
  saveSettings()
  applySettings()
end

-- FOV control
M.setFOV = function(v)
  settings.fov = v
  saveSettings()
  applyFOV()
end

M.getFOV = function()
  return settings.fov
end

-- Return a copy of current settings (useful for UI)
M.getSettings = function()
  return {
    enabled = settings.enabled,
    d       = settings.d,
    s       = settings.s,
    crop    = settings.crop,
    fov     = settings.fov,
  }
end

-- UI Module API (for ImGui-based UI)
M.ui = {}

-- Called to render the ImGui UI for the Panini mod
M.ui.render = function()
  local im = ui_imgui
  local changed = false
  
  -- Main checkbox
  if im.Checkbox("Enable Panini Projection", settings.enabled) then
    settings.enabled = not settings.enabled
    changed = true
  end
  
  im.Separator()
  
  -- Sliders (disabled if effect is off)
  if not settings.enabled then
    im.BeginDisabled()
  end
  
  -- Panini strength (d)
  im.Text("Panini Strength (d)")
  if im.SliderFloat("##panini_d", settings.d, 0.0, 1.0, "%.2f") then
    settings.d = im.GetSliderFloat()
    saveSettings()
    applySettings()
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Controls the strength of the panini projection effect.")
    im.Text("0 = no effect, 1 = maximum distortion")
    im.EndTooltip()
  end
  
  -- Vertical compression (s)
  im.Text("Vertical Compression (s)")
  if im.SliderFloat("##panini_s", settings.s, 0.0, 1.0, "%.2f") then
    settings.s = im.GetSliderFloat()
    saveSettings()
    applySettings()
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Controls vertical line straightening.")
    im.Text("0 = curved verticals (classic panini)")
    im.Text("1 = straight verticals")
    im.EndTooltip()
  end
  
  -- Crop mode
  im.Text("Crop Mode")
  if im.SliderFloat("##panini_crop", settings.crop, 0.0, 1.0, "%.2f") then
    settings.crop = im.GetSliderFloat()
    saveSettings()
    applySettings()
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Crops the image to hide black corners at high distortion.")
    im.Text("0 = show full image with corners")
    im.Text("1 = crop to fill screen")
    im.EndTooltip()
  end
  
  if not settings.enabled then
    im.EndDisabled()
  end
  
  im.Separator()
  
  -- FOV Control (always enabled)
  im.Text("Field of View")
  if im.SliderFloat("##panini_fov", settings.fov, 30.0, 150.0, "%.0f") then
    settings.fov = im.GetSliderFloat()
    saveSettings()
    applyFOV()
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Adjusts the camera's field of view.")
    im.Text("Typical values: 60-120 degrees")
    im.EndTooltip()
  end
  
  -- Reset button
  im.Separator()
  if im.Button("Reset to Defaults") then
    settings.enabled = true
    settings.d = 0.5
    settings.s = 0.0
    settings.crop = 1.0
    settings.fov = 90.0
    saveSettings()
    applySettings()
    applyFOV()
  end
end

-- Extension lifecycle -------------------------------------------------------

M.onExtensionLoaded = function()
  -- Load the settings module first
  local settingsModule = require("core_settings_settings")
  
  -- Load settings from disk
  local saved = settingsModule.getValue(settingsPrefix .. "enabled")
  if saved ~= nil then settings.enabled = saved end
  
  saved = settingsModule.getValue(settingsPrefix .. "d")
  if saved ~= nil then settings.d = saved end
  
  saved = settingsModule.getValue(settingsPrefix .. "s")
  if saved ~= nil then settings.s = saved end
  
  saved = settingsModule.getValue(settingsPrefix .. "crop")
  if saved ~= nil then settings.crop = saved end
  
  saved = settingsModule.getValue(settingsPrefix .. "fov")
  if saved ~= nil then settings.fov = saved end
  
  -- Sync FOV from game settings if different
  local gameFOV = settingsModule.getValue("FOV")
  if gameFOV ~= nil and gameFOV ~= settings.fov then
    settings.fov = gameFOV
  end
  
  applySettings()
  applyFOV()
end

M.onExtensionUnloaded = function()
  -- Disable the effect cleanly when the mod is unloaded
  if scenetree and scenetree.PaniniPostFx then
    scenetree.PaniniPostFx:disable()
  end
end

-- Register UI module for access from other extensions
if extensions then
  extensions._panini_ui = M.ui
end

return M