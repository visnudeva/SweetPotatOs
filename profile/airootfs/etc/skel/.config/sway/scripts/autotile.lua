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

local function on_view_map(view, _)
	local container = scroll.view_get_container(view)
	if not container or scroll.container_get_floating(container) then
		return
	end
	local workspace = scroll.container_get_workspace(container)
	if not workspace then
		return
	end
	apply_pair_layout(columns_except(workspace, nil))
end

local function on_view_unmap(view, _)
	local dying = scroll.view_get_container(view)
	local workspace = dying and scroll.container_get_workspace(dying)
		or scroll.focused_workspace()
	if not workspace then
		return
	end
	local exclude = dying and column_of(dying) or nil
	apply_pair_layout(columns_except(workspace, exclude))
end

local function on_view_float(view, _)
	local container = scroll.view_get_container(view)
	if not container then
		return
	end
	local workspace = scroll.container_get_workspace(container)
	if not workspace then
		return
	end
	-- Floating window left the strip; retile remaining tiled columns.
	local exclude = nil
	if scroll.container_get_floating(container) then
		exclude = column_of(container)
	end
	apply_pair_layout(columns_except(workspace, exclude))
end

scroll.add_callback("view_map", on_view_map, nil)
scroll.add_callback("view_unmap", on_view_unmap, nil)
scroll.add_callback("view_float", on_view_float, nil)

scroll.log("swirl autotile: pair layout (odd=full last, even=50/50)")
