#!/usr/bin/env lua
-- Unit tests for swirl/scripts/autotile_lib.lua (pure layout helpers).

local function script_dir()
	local src = debug.getinfo(1, "S").source
	if src:sub(1, 1) == "@" then
		return src:sub(2):match("(.*/)") or "./"
	end
	return "./"
end

-- Prefer SweetPotato sibling checkout; fall back to ISO skel after sync.
local root = script_dir() .. ".."
local candidates = {
	root .. "/../SweetPotato/swirl/scripts/autotile_lib.lua",
	root .. "/profile/airootfs/etc/skel/.config/swirl/scripts/autotile_lib.lua",
}

local lib
for _, path in ipairs(candidates) do
	local f = io.open(path, "r")
	if f then
		f:close()
		lib = dofile(path)
		break
	end
end
assert(lib, "autotile_lib.lua not found")

local pass, fail = 0, 0

local function check(cond, label)
	if cond then
		print("[PASS] " .. label)
		pass = pass + 1
	else
		print("[FAIL] " .. label)
		fail = fail + 1
	end
end

local function widths_eq(got, want, label)
	if #got ~= #want then
		check(false, label .. " (length)")
		return
	end
	for i = 1, #want do
		if got[i] ~= want[i] then
			check(false, label .. " @ " .. i)
			return
		end
	end
	check(true, label)
end

widths_eq(lib.column_widths(0), {}, "0 columns → empty")
widths_eq(lib.column_widths(1), { 1.0 }, "1 column → full")
widths_eq(lib.column_widths(2), { 0.5, 0.5 }, "2 columns → 50/50")
widths_eq(lib.column_widths(3), { 0.5, 0.5, 1.0 }, "3 columns → 50/50 + full")
widths_eq(lib.column_widths(4), { 0.5, 0.5, 0.5, 0.5 }, "4 columns → all 50/50")

local filtered = lib.columns_except({ "a", "b", "c" }, "b")
check(#filtered == 2 and filtered[1] == "a" and filtered[2] == "c", "columns_except drops id")
check(#lib.columns_except(nil, "x") == 0, "columns_except nil → empty")

check(lib.view_count({ 1, 2, 3 }, 2) == 2, "view_count excludes dying view")
check(lib.view_count(nil, 1) == 0, "view_count nil → 0")

check(lib.should_go_home({ { 1 } }, 1) == true, "go home when only dying view remains")
check(lib.should_go_home({ { 1 }, { 2 } }, 1) == false, "stay when another workspace has a window")
check(lib.should_go_home({ {}, {} }, nil) == true, "go home when all empty")

print()
print(string.format("autotile_lib: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
