-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

local FiraCodeFont = "FiraCode Nerd Font"
local CodeNewRomanFont = "CodeNewRoman Nerd Font"
local MonacoFont = "Monaco"
local NotoSansMonoFont = "NotoSansMono NFM"

config.font = wezterm.font(NotoSansMonoFont)
-- config.font = wezterm.font("Monaco Nerd Font Mono")
config.font_size = 14.0
config.color_scheme = "Catppuccin Mocha"
config.use_fancy_tab_bar = true
config.window_frame = {
	font = wezterm.font(CodeNewRomanFont),
	font_size = 13,
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
		return current_dir
		-- return current_dir:sub(#"file:///", #current_dir)
	end
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = string.format(" %s %s ", get_process(tab), get_current_working_dir(tab))
	return {
		{ Text = title },
	}
end)

config.default_cwd = wezterm.home_dir

-- and finally, return the configuration to wezterm
return config