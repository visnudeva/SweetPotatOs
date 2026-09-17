-- Pure helpers for Swirl pair-column autotile (no compositor API).
-- Used by autotile.lua and unit tests.

local lib = {}

-- Width fraction for each column index (1-based) given column count n.
-- Odd n → last column full (1.0); all others 0.5. Even n → all 0.5.
function lib.column_width(n, index)
	if n < 1 or index < 1 or index > n then
		return nil
	end
	if (n % 2 == 1) and index == n then
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

return lib
