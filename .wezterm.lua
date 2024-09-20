local wezterm = require("wezterm")
local wezterm_action = wezterm.action
local wezterm_mux = wezterm.mux

local function _execute(cmd)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))
  f:close()
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", "")
  return s
end

local IS_WINDOWS = package.config:sub(1, 1) == "\\"
local IS_LINUX = false
local IS_MACOS = false
if not IS_WINDOWS then
  local os_name = _execute("uname")
  IS_LINUX = os_name ~= "Darwin"
  IS_MACOS = os_name == "Darwin"
end

local FONTS = {
  -- "Pragmasevka Nerd Font",
  -- "Mononoki Nerd Font Mono",
  -- "D2CodingLigature Nerd Font Mono",
  "Monaco Nerd Font Mono",
  "CodeNewRoman Nerd Font Mono",
  "SaurceCodePro Nerd Font Mono",
  "Noto Nerd Font Mono",
  "Hack Nerd Font Mono",
}
local FONT_SIZE = 15.0
local TAB_BAR_FONT_SIZE = 12.0
if not IS_MACOS then
  FONT_SIZE = 11.0
  TAB_BAR_FONT_SIZE = 10.0
end

local config = wezterm.config_builder()

-- local config = {
-- 	colors = {},
-- }

config.webgpu_power_preference = "HighPerformance"
config.max_fps = 100

-- ui.lua {

config.font = wezterm.font_with_fallback(FONTS)
config.font_size = FONT_SIZE

config.enable_scroll_bar = true
config.colors = { scrollbar_thumb = "#A872FB" }

-- local COLOR_SCHEME = "Batman"
local COLOR_SCHEME = "Catppuccin Mocha"

config.color_scheme = COLOR_SCHEME
local theme = wezterm.get_builtin_color_schemes()[COLOR_SCHEME]

config.window_frame = {
  font = wezterm.font_with_fallback(FONTS),
  font_size = TAB_BAR_FONT_SIZE,
  active_titlebar_bg = theme.background,
  active_titlebar_fg = theme.brights[8],
  -- active_titlebar_fg = theme.foreground,
  inactive_titlebar_bg = theme.background,
  inactive_titlebar_fg = theme.brights[8],
  -- inactive_titlebar_fg = theme.foreground,
}

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

wezterm.on("gui-startup", function()
  local tab, pane, window = wezterm_mux.spawn_window({})
  window:gui_window():maximize()
end)

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 120

function str_startswith(s, start)
  return string.len(s) >= string.len(start) and string.sub(s, 1, #start) == start
end

function str_endswith(s, ending)
  return string.len(ending) == 0 or (string.len(s) >= string.len(ending) and string.sub(s, - #ending) == ending)
end

local function get_current_working_dir(tab)
  local cwd = tab.active_pane.current_working_dir
  if IS_WINDOWS then
    local home_dir = os.getenv("UserProfile")
    if type(home_dir) == "string" and string.len(home_dir) > 0 then
      home_dir = string.gsub(home_dir, "\\", "/")
    end
    if cwd and type(cwd.file_path) == "string" then
      cwd = cwd.file_path:gsub(home_dir, "~")
      if str_startswith(cwd, "/") then
        cwd = string.sub(cwd, 2)
      end
      if str_endswith(cwd, "/") then
        cwd = string.sub(cwd, 1, #cwd - 1)
      end
    end
  else
    if cwd and type(cwd.file_path) == "string" then
      cwd = cwd.file_path:gsub(os.getenv("HOME"), "~")
    end
  end

  return cwd
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  -- Get the process name.
  -- local process = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
  -- Current working directory.
  local cwd = get_current_working_dir(tab)
  -- Format and return the title.
  return string.format(" %d %s ", tab.tab_index + 1, cwd)
end)

-- key-mappings.lua {

config.keys = {}
if not IS_WINDOWS then
  table.insert(config.keys, { key = "LeftArrow", mods = "SHIFT|SUPER", action = wezterm_action.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "RightArrow", mods = "SHIFT|SUPER", action = wezterm_action.ActivateTabRelative(1) })
end
if IS_MACOS then
  table.insert(
    config.keys,
    { key = "ApplicationLeftArrow", mods = "CMD|SHIFT", action = wezterm_action.ActivateTabRelative(-1) }
  )
  table.insert(
    config.keys,
    { key = "ApplicationRightArrow", mods = "CMD|SHIFT", action = wezterm_action.ActivateTabRelative(1) }
  )
end
if IS_WINDOWS then
  table.insert(config.keys, { key = "LeftArrow", mods = "SHIFT|ALT", action = wezterm_action.ActivateTabRelative(-1) })
  table.insert(config.keys, { key = "RightArrow", mods = "SHIFT|ALT", action = wezterm_action.ActivateTabRelative(1) })
  for i = 1, 8 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = 'ALT',
      action = wezterm_action.ActivateTab(i - 1),
    })
  end
  table.insert(
    config.keys,
    { key = "t", mods = "ALT", action = wezterm_action.SpawnTab('CurrentPaneDomain') }
  )
end

-- key-mappings.lua }

-- shell.lua {

if IS_WINDOWS then
  config.default_prog = { "pwsh.exe" }
end

-- shell.lua }

return config
