--- ========== Wezterm API ==========
local wezterm = require("wezterm")
local wezterm_action = wezterm.action
local wezterm_mux = wezterm.mux

-- This table will hold the configuration.
local config = {}

local function _run_command(cmd)
	local f = assert(io.popen(cmd, "r"))
	local s = assert(f:read("*a"))
	f:close()
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	s = string.gsub(s, "[\n\r]+", "")
	return s
end

local function _home_dir()
	return string.format("file://%s", os.getenv("HOME"))
end

local function _current_dir(current_uri)
	local homedir = _home_dir()
	if current_uri:find("^" .. homedir) ~= nil then
		return "~" .. current_uri:sub(#homedir + 1, #current_uri)
	else
		return current_uri:sub(#"file:///", #current_uri)
	end
end

local IS_WINDOWS = package.config:sub(1, 1) == "\\"
local IS_LINUX = false
local IS_MACOS = false
if not IS_WINDOWS then
	local os_name = _run_command("uname")
	IS_LINUX = os_name ~= "Darwin"
	IS_MACOS = os_name == "Darwin"
end

--- ========== Keys ==========
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

--- ========== Fonts & Themes ==========
local FiraCodeFont = "FiraCode Nerd Font Mono"
local CodeNewRomanFont = "CodeNewRoman Nerd Font"
local MonacoFont = "Monaco Nerd Font Mono"
local NotoSansMonoFont = "NotoSansMono NFM"
local IosevakaFont = "Iosevka Nerd Font Mono"
local HackFont = "Hack Nerd Font Mono"
local FantasqueSansMonoFont = "FantasqueSansMono NFM"
local SauceCodeProFont = "SauceCodePro Nerd Font Mono"
local LemonadeFont = "Lemonade"
local MaconFont = "Macon"

local CatppuccinMochaTheme = "Catppuccin Mocha"
local GruvboxDarkTheme = "Gruvbox Dark (Gogh)"

config.font = wezterm.font(SauceCodeProFont)
-- config.font = wezterm.font(MaconFont)
config.font_size = 15.0
if IS_WINDOWS then
	config.font_size = 14.0
end
if IS_LINUX then
	config.font_size = 10.0
end
config.colors = {
	scrollbar_thumb = "green",
}
-- config.color_scheme = GruvboxDarkTheme

--- ========== Tabs ==========
config.use_fancy_tab_bar = true
config.tab_max_width = 256
config.window_frame = {
	font = wezterm.font(FiraCodeFont),
	font_size = 13,
}
config.scrollback_lines = 200000
config.enable_scroll_bar = true
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

local function get_process(tab)
	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	if string.find(process_name, "kubectl") then
		process_name = "kubectl"
	end
	return wezterm.format({ { Text = string.format("[%s]", process_name) } })
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local function _get_cwd(tab)
		return _current_dir(tab.active_pane.current_working_dir)
	end

	local title = string.format(" %s %s ", get_process(tab), _get_cwd(tab))
	return {
		{ Text = title },
	}
end)

--- ========== Gui Startup ==========

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = wezterm_mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

--- ========== Right Status ==========

-- wezterm.on("update-right-status", function(window, pane)
-- 	local SOLID_LEFT_ARROW = ""
-- 	local SOLID_RIGHT_ARROW = ""
-- 	local COLORS = {
-- 		"#3c1361",
-- 		"#52307c",
-- 		"#663a82",
-- 		"#7c5295",
-- 		"#b491c8",
-- 	}
-- 	local TEXT_FG = "#c0c0c0"
--
-- 	local cells = {}
-- 	local cwd_uri = pane:get_current_working_dir()
-- 	local cwd = nil
-- 	if type(cwd_uri) == "userdata" then
-- 		cwd = cwd_uri.file_path
-- 	else
-- 		cwd = _current_dir(cwd_uri)
-- 	end
-- 	table.insert(cells, cwd)
--
-- 	local date = wezterm.strftime("%a %b %-d %H:%M")
-- 	table.insert(cells, date)
--
-- 	local elements = {}
-- 	local num_cells = 0
--
-- 	table.insert(elements, { Foreground = { Color = "#3c1361" } })
--
-- 	table.insert(elements, { Text = SOLID_RIGHT_ARROW })
--
-- 	local function _push(text, is_last)
-- 		local cell_no = num_cells + 1
-- 		table.insert(elements, { Foreground = { Color = TEXT_FG } })
-- 		table.insert(elements, { Background = { Color = COLORS[cell_no] } })
-- 		table.insert(elements, { Text = " " .. text .. " " })
-- 		if not is_last then
-- 			table.insert(elements, { Foreground = { Color = COLORS[cell_no + 1] } })
-- 			table.insert(elements, { Text = SOLID_RIGHT_ARROW })
-- 		end
-- 		num_cells = num_cells + 1
-- 	end
--
-- 	while #cells > 0 do
-- 		local cell = table.remove(cells, 1)
-- 		_push(cell, #cells == 0)
-- 	end
--
-- 	window:set_right_status(wezterm.format(elements))
-- end)

--- ========== CWD ==========
config.default_cwd = wezterm.home_dir

--- ========== Shell ==========
if IS_WINDOWS then
	config.default_prog = { "pwsh.exe" }
end

--- ========== Wezterm API ==========
return config
