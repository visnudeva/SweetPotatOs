-- Swirl / scroll: niri-like column auto-tile
--
-- Pairing on the strip:
--   odd count  -> last column full width, earlier columns in 50/50 pairs
--   even count -> all columns 50/50
-- Examples: 1=full, 2=50/50, 3=50/50+full, 4=50/50+50/50, ...
--
-- scroll.command() only accepts containers that own a view. Top-level strip
-- columns are parent wrappers, so we always command a child view; set_size h
-- walks up to the column automatically.
--
-- On unmap the dying window is still in the tree, so we exclude its column
-- before retilling. set_size uses OPERATION_RESIZE which blocks maximize_if_single
-- from later restoring full width — we must set 1.0 ourselves when one remains.
--
-- Moving a window to another workspace does not unmap it, so we also listen for
-- ipc_view "move" and retile both the old and new workspaces.
-- Closing the last window anywhere jumps back to workspace 1.

local view_workspace = {}

local function first_view(container)
	if not container then
		return nil
	end
	local views = scroll.container_get_views(container)
	if views and views[1] then
		return views[1]
	end
	return nil
end

local function column_of(container)
	if not container then
		return nil
	end
	return scroll.container_get_parent(container) or container
end

local function set_width(container, fraction)
	local view = first_view(container)
	if not view then
		return
	end
	scroll.command(view, "set_size h " .. tostring(fraction))
end

-- Apply pair layout to an explicit list of top-level columns.
local function apply_pair_layout(columns)
	local n = #columns
	if n == 0 then
		return
	end

	for i, column in ipairs(columns) do
		if (n % 2 == 1) and i == n then
			set_width(column, 1.0)
		else
			set_width(column, 0.5)
		end
	end
end

local function columns_except(workspace, exclude_column_id)
	local tiling = scroll.workspace_get_tiling(workspace)
	if not tiling then
		return {}
	end

	local columns = {}
	for _, column in ipairs(tiling) do
		if column ~= exclude_column_id then
			columns[#columns + 1] = column
		end
	end
	return columns
end

local function retile(workspace, exclude_column_id)
	if not workspace then
		return
	end
	apply_pair_layout(columns_except(workspace, exclude_column_id))
end

local function remember(view, workspace)
	if view and workspace then
		view_workspace[view] = workspace
	end
end

-- Count views in a column/container, ignoring exclude_view (still present during unmap).
local function view_count(container, exclude_view)
	local views = scroll.container_get_views(container)
	if not views then
		return 0
	end
	local n = 0
	for _, v in ipairs(views) do
		if v and v ~= exclude_view then
			n = n + 1
		end
	end
	return n
end

local function workspace_has_windows(workspace, exclude_view)
	if not workspace then
		return false
	end
	for _, column in ipairs(scroll.workspace_get_tiling(workspace) or {}) do
		if view_count(column, exclude_view) > 0 then
			return true
		end
	end
	for _, con in ipairs(scroll.workspace_get_floating(workspace) or {}) do
		if view_count(con, exclude_view) > 0 then
			return true
		end
	end
	return false
end

local function any_windows_left(exclude_view)
	for _, output in ipairs(scroll.root_get_outputs() or {}) do
		for _, ws in ipairs(scroll.output_get_workspaces(output) or {}) do
			if workspace_has_windows(ws, exclude_view) then
				return true
			end
		end
	end
	return false
end

-- Last window closed anywhere → return to workspace 1.
local function go_home_if_empty(exclude_view)
	if any_windows_left(exclude_view) then
		return
	end
	scroll.command(nil, "workspace number 1")
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
end

local function on_view_unmap(view, _)
	local dying = scroll.view_get_container(view)
	local workspace = dying and scroll.container_get_workspace(dying)
		or view_workspace[view]
		or scroll.focused_workspace()
	local exclude = dying and column_of(dying) or nil
	view_workspace[view] = nil
	retile(workspace, exclude)
	go_home_if_empty(view)
end

local function on_view_float(view, _)
	local container = scroll.view_get_container(view)
	if not container then
		return
	end
	local workspace = scroll.container_get_workspace(container)
		or view_workspace[view]
	if not workspace then
		return
	end
	-- Floating window left the strip; retile remaining tiled columns.
	if scroll.container_get_floating(container) then
		retile(workspace, column_of(container))
		view_workspace[view] = nil
	else
		remember(view, workspace)
		retile(workspace, nil)
	end
end

-- Cross-workspace (and overview drag) moves do not unmap — retile both sides.
local function on_ipc_view(view, change, _)
	if change ~= "move" then
		return
	end
	local container = scroll.view_get_container(view)
	if not container then
		return
	end
	if scroll.container_get_floating(container) then
		return
	end

	local new_ws = scroll.container_get_workspace(container)
	local old_ws = view_workspace[view]

	if old_ws and old_ws ~= new_ws then
		retile(old_ws, nil)
	end
	if new_ws then
		retile(new_ws, nil)
		remember(view, new_ws)
	end
end

scroll.add_callback("view_map", on_view_map, nil)
scroll.add_callback("view_unmap", on_view_unmap, nil)
scroll.add_callback("view_float", on_view_float, nil)
scroll.add_callback("ipc_view", on_ipc_view, nil)

scroll.log("swirl autotile: pair layout + retile on move + home on empty")
