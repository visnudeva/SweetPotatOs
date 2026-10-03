-- Swirl / scroll: niri-like column auto-tile
--
-- Pairing: odd count → last column full width; even → all 50/50.
-- Move between workspaces does not unmap — retile both sides on ipc_view move.
-- Closing the last window anywhere → workspace number 1.
--
-- set_size uses OPERATION_RESIZE which blocks maximize_if_single, so we set
-- 1.0 ourselves when a single column remains. On unmap the dying column is
-- still in the tree — exclude it before retilling.

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("(.*/)") or "./"
	end
	return "./"
end

local lib = dofile(script_dir() .. "autotile_lib.lua")
local view_workspace = {}

local function first_view(container)
	if not container then
		return nil
	end
	local views = scroll.container_get_views(container)
	return views and views[1] or nil
end

local function column_of(container)
	if not container then
		return nil
	end
	return scroll.container_get_parent(container) or container
end

local function set_width(container, fraction)
	local view = first_view(container)
	if view then
		scroll.command(view, "set_size h " .. tostring(fraction))
	end
end

local function apply_pair_layout(columns)
	local n = #columns
	for i, column in ipairs(columns) do
		set_width(column, lib.column_width(n, i))
	end
end

local function retile(workspace, exclude_column_id)
	if not workspace then
		return
	end
	apply_pair_layout(lib.columns_except(scroll.workspace_get_tiling(workspace), exclude_column_id))
end

local function remember(view, workspace)
	if view and workspace then
		view_workspace[view] = workspace
	end
end

local function workspace_view_lists()
	local lists = {}
	for _, output in ipairs(scroll.root_get_outputs() or {}) do
		for _, ws in ipairs(scroll.output_get_workspaces(output) or {}) do
			local views = {}
			for _, column in ipairs(scroll.workspace_get_tiling(ws) or {}) do
				for _, v in ipairs(scroll.container_get_views(column) or {}) do
					views[#views + 1] = v
				end
			end
			for _, con in ipairs(scroll.workspace_get_floating(ws) or {}) do
				for _, v in ipairs(scroll.container_get_views(con) or {}) do
					views[#views + 1] = v
				end
			end
			lists[#lists + 1] = views
		end
	end
	return lists
end

local function go_home_if_empty(exclude_view)
	if lib.should_go_home(workspace_view_lists(), exclude_view) then
		scroll.command(nil, "workspace number 1")
	end
end

-- Gap only on the focused workspace, and only while it has more than one
-- tiled window. Unfocused workspaces update when they are focused.
-- Mod+g writes ~/.config/sweetpotatos/frame ("off" hides the gap).
local applied_gap = {}
local applied_enabled = nil

local function frame_enabled()
	local home = os.getenv("HOME") or ""
	local f = io.open(home .. "/.config/sweetpotatos/frame", "r")
	if not f then
		return true
	end
	local line = f:read("*l") or ""
	f:close()
	return line ~= "off"
end

local function workspace_view_count(workspace, exclude_view)
	if not workspace then
		return 0
	end
	local views = {}
	for _, column in ipairs(scroll.workspace_get_tiling(workspace) or {}) do
		for _, v in ipairs(scroll.container_get_views(column) or {}) do
			views[#views + 1] = v
		end
	end
	return lib.view_count(views, exclude_view)
end

local applying_gap = false

local function command_ok(results)
	if type(results) ~= "table" then
		return false
	end
	for _, item in ipairs(results) do
		if type(item) == "string" then
			return false
		end
	end
	return #results > 0
end

local function sync_gaps(workspace, exclude_view)
	local enabled = frame_enabled()
	-- frame.sh can zero every workspace without going through this cache.
	if applied_enabled ~= enabled then
		applied_gap = {}
		applied_enabled = enabled
	end
	if applying_gap or not workspace or scroll.focused_workspace() ~= workspace then
		return
	end
	local px = lib.inner_gap_px(workspace_view_count(workspace, exclude_view), enabled)
	if applied_gap[workspace] == px then
		return
	end
	-- Runtime gap commands are rejected while the config file is still loading.
	-- Do not remember a failed apply; the deferred mark below retries.
	applying_gap = true
	local results = scroll.command(nil, "gaps inner current set " .. tostring(px))
	applying_gap = false
	if command_ok(results) then
		applied_gap[workspace] = px
	end
end

local function on_view_map(view, _)
	local container = scroll.view_get_container(view)
	if not container or scroll.container_get_floating(container) then
		return
	end
	local workspace = scroll.container_get_workspace(container)
	if not workspace then
		return
	end
	remember(view, workspace)
	retile(workspace, nil)
	sync_gaps(workspace, nil)
end

local function on_view_unmap(view, _)
	local dying = scroll.view_get_container(view)
	local workspace = dying and scroll.container_get_workspace(dying)
		or view_workspace[view]
		or scroll.focused_workspace()
	local exclude = dying and column_of(dying) or nil
	view_workspace[view] = nil
	retile(workspace, exclude)
	sync_gaps(workspace, view)
	go_home_if_empty(view)
end

local function on_view_float(view, _)
	local container = scroll.view_get_container(view)
	if not container then
		return
	end
	local workspace = scroll.container_get_workspace(container) or view_workspace[view]
	if not workspace then
		return
	end
	if scroll.container_get_floating(container) then
		retile(workspace, column_of(container))
		view_workspace[view] = nil
		sync_gaps(workspace, view)
	else
		remember(view, workspace)
		retile(workspace, nil)
		sync_gaps(workspace, nil)
	end
end

local function on_ipc_view(view, change, _)
	-- Deferred ping after config load (runtime gaps are rejected mid-parse).
	if change == "mark" then
		local container = scroll.view_get_container(view)
		local workspace = container and scroll.container_get_workspace(container)
			or scroll.focused_workspace()
		sync_gaps(workspace, nil)
		return
	end
	if change ~= "move" then
		return
	end
	local container = scroll.view_get_container(view)
	if not container or scroll.container_get_floating(container) then
		return
	end
	local new_ws = scroll.container_get_workspace(container)
	local old_ws = view_workspace[view]
	if old_ws and old_ws ~= new_ws then
		retile(old_ws, nil)
		sync_gaps(old_ws, nil)
	end
	if new_ws then
		retile(new_ws, nil)
		remember(view, new_ws)
		sync_gaps(new_ws, nil)
	end
end

local function on_workspace_focus(workspace, _)
	sync_gaps(workspace, nil)
end

scroll.add_callback("view_map", on_view_map, nil)
scroll.add_callback("view_unmap", on_view_unmap, nil)
scroll.add_callback("view_float", on_view_float, nil)
scroll.add_callback("ipc_view", on_ipc_view, nil)
scroll.add_callback("workspace_focus", on_workspace_focus, nil)

sync_gaps(scroll.focused_workspace(), nil)
-- Config parse rejects "gaps … current". Retry once the compositor is reading commands.
scroll.exec_process("sleep 0.3; swaymsg 'mark --add __spo_gaps' >/dev/null 2>&1; swaymsg 'unmark __spo_gaps' >/dev/null 2>&1")
