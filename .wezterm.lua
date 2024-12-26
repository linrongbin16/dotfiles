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
	-- "RecMonoCasual Nerd Font Mono",
	-- "JetBrainsMono Nerd Font Mono",
	-- "Maple Mono NF",
	"Monaco Nerd Font Mono",
	-- "Monaco",
	-- "ComicShannsMono Nerd Font Mono",
	-- "CaskaydiaMono Nerd Font Mono",
	"CodeNewRoman Nerd Font Mono",
	"SaurceCodePro Nerd Font Mono",
	"Noto Nerd Font Mono",
	"Hack Nerd Font Mono",
}
local FONT_SIZE = 13.0
local TAB_BAR_FONT_SIZE = 10.0
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

-- local COLOR_SCHEME = "Batman"
-- local COLOR_SCHEME = "Catppuccin Mocha"

-- config.color_scheme = COLOR_SCHEME
-- local theme = wezterm.get_builtin_color_schemes()[COLOR_SCHEME]
local theme = wezterm.color.get_default_colors()

config.enable_scroll_bar = true
-- config.colors = { scrollbar_thumb = "#A872FB" }
config.colors = { scrollbar_thumb = theme.brights[1] }

config.window_frame = {
	font = wezterm.font_with_fallback(FONTS),
	font_size = TAB_BAR_FONT_SIZE,
	-- active_titlebar_bg = theme.background,
	-- active_titlebar_fg = theme.foreground,
	-- active_titlebar_fg = theme.brights[8],

	-- inactive_titlebar_bg = theme.background,
	-- inactive_titlebar_fg = theme.foreground,
	-- inactive_titlebar_fg = theme.brights[8],
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

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	-- Get the process name.
	-- local process = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	-- Current working directory.
	local cwd = tab.active_pane.current_working_dir
	cwd = cwd and string.format("%s ", cwd.file_path:gsub(os.getenv("HOME"), "~")) or ""
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
