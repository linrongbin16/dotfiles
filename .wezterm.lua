function run_command(cmd)
	local f = assert(io.popen(cmd, "r"))
	local s = assert(f:read("*a"))
	f:close()
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	s = string.gsub(s, "[\n\r]+", "")
	return s
end

local is_windows = package.config:sub(1, 1) == "\\"
local is_linux = false
if not is_windows then
	local os_name = run_command("uname")
	is_linux = os_name ~= "Darwin"
end

-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

local FiraCodeFont = "FiraCode Nerd Font"
local CodeNewRomanFont = "CodeNewRoman Nerd Font"
local MonacoFont = "Monaco Nerd Font Mono"
local NotoSansMonoFont = "NotoSansMono NFM"
local IosevakaFont = "Iosevka Nerd Font Mono"
local HackFont = "Hack Nerd Font Mono"

local CatppuccinMochaTheme = "Catppuccin Mocha"
local GruvboxDarkTheme = "Gruvbox Dark (Gogh)"

config.font = wezterm.font(FiraCodeFont)
-- config.font = wezterm.font("Monaco Nerd Font Mono")
config.font_size = 14.0
if is_windows then
	config.font_size = 14.0
end
if is_linux then
	config.font_size = 11.0
end
config.color_scheme = GruvboxDarkTheme
config.use_fancy_tab_bar = true
config.window_frame = {
	font = wezterm.font(CodeNewRomanFont),
	font_size = 13,
}
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

local function get_current_working_dir(tab)
	local current_dir = tab.active_pane.current_working_dir
	local home_dir = string.format("file://%s", os.getenv("HOME"))
	if current_dir:find("^" .. home_dir) ~= nil then
		return "~" .. current_dir:sub(#home_dir + 1, #current_dir)
	else
		-- return current_dir
		return current_dir:sub(#"file:///", #current_dir)
	end
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = string.format(" %s %s ", get_process(tab), get_current_working_dir(tab))
	return {
		{ Text = title },
	}
end)

config.default_cwd = wezterm.home_dir

if is_windows then
	config.default_prog = { "pwsh.exe" }
end

-- and finally, return the configuration to wezterm
return config
