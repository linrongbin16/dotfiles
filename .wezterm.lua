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
	"D2CodingLigature Nerd Font Mono",
	"Monaco Nerd Font Mono",
	"CodeNewRoman Nerd Font Mono",
	"SaurceCodePro Nerd Font Mono",
	"Noto Nerd Font Mono",
	"Hack Nerd Font Mono",
}
local FONT_SIZE = 16.0
if not IS_MACOS then
	FONT_SIZE = 11.0
end

local config = {}

if IS_WINDOWS or IS_MACOS then
	config.front_end = "WebGpu"
	config.webgpu_power_preference = "HighPerformance"
end

-- ui.lua {

config.font = wezterm.font_with_fallback(FONTS)
config.font_size = FONT_SIZE

config.enable_scroll_bar = true
config.colors.scrollbar_thumb = "#A872FB"

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

-- key-mappings.lua {

config.keys = {}
table.insert(config.keys, { key = "LeftArrow", mods = "SHIFT|SUPER", action = wezterm_action.ActivateTabRelative(-1) })
table.insert(config.keys, { key = "RightArrow", mods = "SHIFT|SUPER", action = wezterm_action.ActivateTabRelative(1) })
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

-- key-mappings.lua }

-- shell.lua {

if IS_WINDOWS then
	config.default_prog = { "pwsh.exe" }
end

-- shell.lua }

return config
