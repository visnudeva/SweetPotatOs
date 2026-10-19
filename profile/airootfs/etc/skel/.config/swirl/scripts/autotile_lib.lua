-- Pure helpers for Swirl column autotile (no compositor API).
-- Used by autotile.lua and unit tests.

local lib = {}

-- Default width when we intentionally set a column (open / lone / pair).
-- One column → full. Otherwise half. Mod+m toggles without using this.
function lib.column_width(n, index)
	if n < 1 or index < 1 or index > n then
		return nil
	end
	if n == 1 then
		return 1.0
	end
	return 0.5
end

function lib.column_widths(n)
	local widths = {}
	for i = 1, n do
		widths[i] = lib.column_width(n, i)
	end
	return widths
end

-- After a column is removed: expand a lone survivor; otherwise keep sizes.
-- Returns "expand_lone" | "preserve"
function lib.after_remove_action(n)
	if n == 1 then
		return "expand_lone"
	end
	return "preserve"
end

-- After a column is added (map / unfloat / move onto a shared desktop).
-- Alone → full. Onto a desktop that already has windows → half (and the
-- classic 1→2 case normalizes both to 50/50).
-- Returns "expand_lone" | "normalize_pair" | "size_new_half" | "none"
function lib.after_add_action(n)
	if n < 1 then
		return "none"
	end
	if n == 1 then
		return "expand_lone"
	end
	if n == 2 then
		return "normalize_pair"
	end
	return "size_new_half"
end

-- Drop one column id from a list (unmap still sees the dying column).
function lib.columns_except(columns, exclude_id)
	local out = {}
	if not columns then
		return out
	end
	for _, column in ipairs(columns) do
		if column ~= exclude_id then
			out[#out + 1] = column
		end
	end
	return out
end

-- Count entries in a view id list, ignoring exclude_view.
function lib.view_count(views, exclude_view)
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

-- True when every workspace report is empty (after excluding a dying view).
function lib.any_windows_left(workspace_view_lists, exclude_view)
	if not workspace_view_lists then
		return false
	end
	for _, views in ipairs(workspace_view_lists) do
		if lib.view_count(views, exclude_view) > 0 then
			return true
		end
	end
	return false
end

function lib.should_go_home(workspace_view_lists, exclude_view)
	return not lib.any_windows_left(workspace_view_lists, exclude_view)
end

-- Inner gap in px. Scroll insets every side, so two windows have twice this
-- between them. A single tiled window stays edge to edge.
-- enabled == false (Mod+Ctrl+g frames off) forces 0. nil or true keeps the usual rule.
lib.INNER_GAP = 8

function lib.inner_gap_px(view_count, enabled)
	if enabled == false then
		return 0
	end
	if view_count > 1 then
		return lib.INNER_GAP
	end
	return 0
end

return lib
