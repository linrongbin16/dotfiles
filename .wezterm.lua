-- fork from: https://github.com/b0o/wezterm-conf

local wezterm = require("wezterm")
local wezterm_action = wezterm.action
local wezterm_nerdfonts = wezterm.nerdfonts
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

local function _extract_path(p)
	local dirname, filename = p:match("^(.*/)([^/]-)$")
	return dirname, filename
end

local IS_WINDOWS = package.config:sub(1, 1) == "\\"
local IS_LINUX = false
local IS_MACOS = false
if not IS_WINDOWS then
	local os_name = _execute("uname")
	IS_LINUX = os_name ~= "Darwin"
	IS_MACOS = os_name == "Darwin"
end
local SHELL = nil
if IS_MACOS or IS_LINUX then
	local shellname = _execute("echo $SHELL")
	local _, shortname = _extract_path(shellname)
	SHELL = shortname
end

local config = {}

-- utils.lua {
-- utility functions extracted from Neovim
-- see /usr/share/nvim/runtime/lua/vim/shared.lua

local utils = {}

--- Checks if a table is empty.
---
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
---@param t table Table to check
---@return boolean `true` if `t` is empty
function utils.tbl_isempty(t)
	assert(type(t) == "table", string.format("Expected table, got %s", type(t)))
	return next(t) == nil
end

--- We only merge empty tables or tables that are not an array (indexed by integers)
local function can_merge(v)
	return type(v) == "table" and (utils.tbl_isempty(v) or not utils.tbl_isarray(v))
end

local function tbl_extend(behavior, deep_extend, ...)
	if behavior ~= "error" and behavior ~= "keep" and behavior ~= "force" then
		error('invalid "behavior": ' .. tostring(behavior))
	end

	if select("#", ...) < 2 then
		error("wrong number of arguments (given " .. tostring(1 + select("#", ...)) .. ", expected at least 3)")
	end

	local ret = {}

	for i = 1, select("#", ...) do
		local tbl = select(i, ...)
		utils.validate({ ["after the second argument"] = { tbl, "t" } })
		if tbl then
			for k, v in pairs(tbl) do
				if deep_extend and can_merge(v) and can_merge(ret[k]) then
					ret[k] = tbl_extend(behavior, true, ret[k], v)
				elseif behavior ~= "force" and ret[k] ~= nil then
					if behavior == "error" then
						error("key found in more than one map: " .. k)
					end -- Else behavior is "keep".
				else
					ret[k] = v
				end
			end
		end
	end
	return ret
end

--- Merges two or more tables.
---
---@param behavior string Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... table Two or more tables
---@return table Merged table
function utils.tbl_extend(behavior, ...)
	return tbl_extend(behavior, false, ...)
end

--- Merges recursively two or more tables.
---
---@generic T1: table
---@generic T2: table
---@param behavior "error"|"keep"|"force" (string) Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... T2 Two or more tables
---@return T1|T2 (table) Merged table
function utils.tbl_deep_extend(behavior, ...)
	return tbl_extend(behavior, true, ...)
end

do
	local type_names = {
		["table"] = "table",
		t = "table",
		["string"] = "string",
		s = "string",
		["number"] = "number",
		n = "number",
		["boolean"] = "boolean",
		b = "boolean",
		["function"] = "function",
		f = "function",
		["callable"] = "callable",
		c = "callable",
		["nil"] = "nil",
		["thread"] = "thread",
		["userdata"] = "userdata",
	}

	local function _is_type(val, t)
		return type(val) == t or (t == "callable" and utils.is_callable(val))
	end

	local function is_valid(opt)
		if type(opt) ~= "table" then
			return false, string.format("opt: expected table, got %s", type(opt))
		end

		for param_name, spec in pairs(opt) do
			if type(spec) ~= "table" then
				return false, string.format("opt[%s]: expected table, got %s", param_name, type(spec))
			end

			local val = spec[1] -- Argument value
			local types = spec[2] -- Type name, or callable
			local optional = (true == spec[3])

			if type(types) == "string" then
				types = { types }
			end

			if utils.is_callable(types) then
				-- Check user-provided validation function
				local valid, optional_message = types(val)
				if not valid then
					local error_message =
						string.format("%s: expected %s, got %s", param_name, (spec[3] or "?"), tostring(val))
					if optional_message ~= nil then
						error_message = error_message .. string.format(". Info: %s", optional_message)
					end

					return false, error_message
				end
			elseif type(types) == "table" then
				local success = false
				for i, t in ipairs(types) do
					local t_name = type_names[t]
					if not t_name then
						return false, string.format("invalid type name: %s", t)
					end
					types[i] = t_name

					if (optional and val == nil) or _is_type(val, t_name) then
						success = true
						break
					end
				end
				if not success then
					return false,
						string.format("%s: expected %s, got %s", param_name, table.concat(types, "|"), type(val))
				end
			else
				return false, string.format("invalid type name: %s", tostring(types))
			end
		end

		return true, nil
	end

	--- Validates a parameter specification (types and values).
	---
	--- Usage example:
	---
	--- ```lua
	---  function user.new(name, age, hobbies)
	---    M.validate{
	---      name={name, 'string'},
	---      age={age, 'number'},
	---      hobbies={hobbies, 'table'},
	---    }
	---    ...
	---  end
	--- ```
	---
	--- Examples with explicit argument values (can be run directly):
	---
	--- ```lua
	---  M.validate{arg1={{'foo'}, 'table'}, arg2={'foo', 'string'}}
	---     --> NOP (success)
	---
	---  M.validate{arg1={1, 'table'}}
	---     --> error('arg1: expected table, got number')
	---
	---  M.validate{arg1={3, function(a) return (a % 2) == 0 end, 'even number'}}
	---     --> error('arg1: expected even number, got 3')
	--- ```
	---
	--- If multiple types are valid they can be given as a list.
	---
	--- ```lua
	---  M.validate{arg1={{'foo'}, {'table', 'string'}}, arg2={'foo', {'table', 'string'}}}
	---  -- NOP (success)
	---
	---  M.validate{arg1={1, {'string', 'table'}}}
	---  -- error('arg1: expected string|table, got number')
	---
	--- ```
	---
	---@param opt table Names of parameters to validate. Each key is a parameter
	---          name; each value is a tuple in one of these forms:
	---          1. (arg_value, type_name, optional)
	---             - arg_value: argument value
	---             - type_name: string|table type name, one of: ("table", "t", "string",
	---               "s", "number", "n", "boolean", "b", "function", "f", "nil",
	---               "thread", "userdata") or list of them.
	---             - optional: (optional) boolean, if true, `nil` is valid
	---          2. (arg_value, fn, msg)
	---             - arg_value: argument value
	---             - fn: any function accepting one argument, returns true if and
	---               only if the argument is valid. Can optionally return an additional
	---               informative error message as the second returned value.
	---             - msg: (optional) error string if validation fails
	function utils.validate(opt)
		local ok, err_msg = is_valid(opt)
		if not ok then
			error(err_msg, 2)
		end
	end
end

--- Returns true if object `f` can be called as a function.
---
---@param f any Any object
---@return boolean `true` if `f` is callable, else `false`
function utils.is_callable(f)
	if type(f) == "function" then
		return true
	end
	local m = getmetatable(f)
	if m == nil then
		return false
	end
	return type(m.__call) == "function"
end

--- Tests if `t` is an "array": a table indexed _only_ by integers (potentially non-contiguous).
---
--- If the indexes start from 1 and are contiguous then the array is also a list. |vim.tbl_islist()|
---
--- Empty table `{}` is an array, unless it was created by |vim.empty_dict()| or returned as
--- a dict-like |API| or Vimscript result, for example from |rpcrequest()| or |vim.fn|.
---
---@see https://github.com/openresty/luajit2#tableisarray
---
---@param t table
---@return boolean `true` if array-like table, else `false`.
function utils.tbl_isarray(t)
	if type(t) ~= "table" then
		return false
	end

	local count = 0

	for k, _ in pairs(t) do
		--- Check if the number k is an integer
		if type(k) == "number" and k == math.floor(k) then
			count = count + 1
		else
			return false
		end
	end

	return count > 0
end

--- Extends a list-like table with the values of another list-like table.
---
--- NOTE: This mutates dst!
---
---@generic T: table
---@param dst T List which will be modified and appended to
---@param src table List from which values will be inserted
---@param start (integer|nil) Start index on src. Defaults to 1
---@param finish (integer|nil) Final index on src. Defaults to `#src`
---@return T dst
function utils.list_extend(dst, src, start, finish)
	utils.validate({
		dst = { dst, "t" },
		src = { src, "t" },
		start = { start, "n", true },
		finish = { finish, "n", true },
	})
	for i = start or 1, finish or #src do
		table.insert(dst, src[i])
	end
	return dst
end

--- Apply a function to all values of a table.
---
---@generic T
---@param func fun(value: T): any (function) Function
---@param t table<any, T> (table) Table
---@return table Table of transformed values
function utils.tbl_map(func, t)
	utils.validate({ func = { func, "c" }, t = { t, "t" } })

	local rettab = {}
	for k, v in pairs(t) do
		rettab[k] = func(v)
	end
	return rettab
end

-- nvu.lua }

-- colors.lua {

-- colors.lavi.lua {

local lavi = {}

lavi.foreground = "#FFF1E0"
lavi.background = "#252137"

lavi.cursor_bg = "#FFFFFF"
lavi.cursor_fg = "#252137"
lavi.cursor_border = "#FFFFFF"

lavi.selection_bg = "#FFFFFF"
lavi.selection_fg = "#000000"

lavi.ansi = {}

lavi.ansi[1] = "#2F2A38"
lavi.ansi[2] = "#FF87A5"
lavi.ansi[3] = "#6EEB84"
lavi.ansi[4] = "#FFD080"
lavi.ansi[5] = "#80BDFF"
lavi.ansi[6] = "#B891FF"
lavi.ansi[7] = "#3FC4C4"
lavi.ansi[8] = "#EEE6FF"

lavi.brights = {}

lavi.brights[1] = "#8977A8"
lavi.brights[2] = "#F2637E"
lavi.brights[3] = "#AFFF61"
lavi.brights[4] = "#FFDF61"
lavi.brights[5] = "#7583FF"
lavi.brights[6] = "#B98AFF"
lavi.brights[7] = "#2BEDC0"
lavi.brights[8] = "#FFFFFF"

lavi.cashew = "#CEB999"
lavi.almond = "#a6875a"
lavi.cocoa = "#3b290e"

lavi.licorice = "#483270"
lavi.lavender = "#A872FB"
lavi.velvet = "#B29EED"
lavi.anise = "#7F7DEE"
lavi.hydrangea = "#fb72fa"
lavi.blush = "#EBBBF9"
lavi.powder = "#EAC6F5"
lavi.dust = "#EAD2F1"
lavi.mistyrose = "#ffe4e1"
lavi.rebeccapurple = "#3C2C74"

lavi.evergreen = "#9fdfb4"

lavi.snow = "#e4fffe"
lavi.ice = "#a4e2e0"
lavi.mint = "#a2e0ca"

lavi.nectar = "#f0f070"
lavi.cayenne = "#FF7D90"
lavi.yam = "#e86f54"
lavi.pumpkin = "#ff9969"
lavi.rose = "#b32e29"

lavi.grey2 = "#222222"
lavi.grey5 = "#777777"
lavi.grey6 = "#aaaaaa"
lavi.grey7 = "#cccccc"
lavi.grey8 = "#dddddd"

lavi.mid_velvet = "#6E6EA3"

lavi.deep_lavender = "#38265A"
lavi.deep_licorice = "#252137"
lavi.deep_anise = "#564D82"
lavi.deep_velvet = "#8F8FB3"

lavi.light_lavender = "#EAD6FF"

lavi.light_background = lavi.deep_anise

lavi.tab_bar = {}

lavi.tab_bar.background = lavi.background

-- colors.lavi.lua }

local colors = {
	color_schemes = {
		lavi = lavi,
	},
}

-- colors.lua }

-- ui.lua {

config.font = wezterm.font_with_fallback({
	"Monaco Nerd Font Mono",
	"CodeNewRoman Nerd Font Mono",
	"SaurceCodePro Nerd Font Mono",
	"Noto Nerd Font Mono",
	"Hack Nerd Font Mono",
})
config.font_size = 13.0
if IS_WINDOWS then
	config.font_size = 14.0
end
if IS_LINUX then
	config.font_size = 11.0
end

config.color_scheme = "lavi"
config.enable_scroll_bar = true
config.colors = {
	scrollbar_thumb = "orange",
}

-- https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.status_update_interval = 1000

wezterm.on("gui-startup", function()
	local tab, pane, window = wezterm_mux.spawn_window({})
	window:gui_window():maximize()
end)

-- ui.lua }

-- tab-bar.lua {

local theme = colors.color_schemes[config.color_scheme]

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 24

config.tab_bar_style = {
	new_tab = wezterm.format({
		{ Background = { Color = theme.background } },
		{ Text = " " },
		{ Background = { Color = theme.background } },
		{ Foreground = { Color = theme.ansi[8] } },
		{ Text = " + " },
		{ Background = { Color = theme.background } },
		{ Text = " " },
	}),
	new_tab_hover = wezterm.format({
		{ Background = { Color = theme.background } },
		{ Text = " " },
		{ Background = { Color = theme.ansi[6] } },
		{ Foreground = { Color = theme.brights[8] } },
		{ Text = " + " },
		{ Background = { Color = theme.background } },
		{ Text = " " },
	}),
}

local function tab_title(tab_info, max_width)
	local tab_index = tab_info.tab_index
	local title = tab_info.tab_title
	local result = (title and #title > 0) and title or tab_info.active_pane.title
	result = string.format("%d %s", tab_index + 1, wezterm.truncate_left(result, max_width - 6))
	return result
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
	local edge_background = theme.background
	local background = theme.light_background
	local foreground = theme.ansi[8]

	if tab.is_active then
		background = theme.brights[1]
		foreground = theme.brights[8]
	elseif hover then
		foreground = theme.brights[8]
	end

	local edge_foreground = background

	local title = tab_title(tab, max_width)

	title = " " .. title .. " "

	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = wezterm_nerdfonts.ple_lower_right_triangle },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = wezterm_nerdfonts.ple_lower_left_triangle },
	}
end)

wezterm.on("update-status", function(window)
	local left_background = theme.brights[1]
	local left_foreground = theme.brights[8]
	if window:leader_is_active() then
		left_background = theme.ansi[2]
	end
	local left_text = nil
	if IS_WINDOWS then
		left_text = "  "
	elseif IS_MACOS then
		left_text = "  " .. SHELL .. " "
	else
		left_text = "  " .. SHELL .. " "
	end
	window:set_left_status(wezterm.format({
		{ Background = { Color = left_background } },
		{ Foreground = { Color = left_foreground } },
		-- { Text = " ♥ " },
		{ Text = left_text },
		{ Foreground = { Color = left_background } },
		{ Background = { Color = theme.background } },
		{ Text = wezterm_nerdfonts.ple_lower_left_triangle },
		{ Text = " " },
	}))
end)

-- tab-bar.lua }

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

return config
