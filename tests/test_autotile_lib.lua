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
widths_eq(lib.column_widths(3), { 0.5, 0.5, 0.5 }, "3 columns → all half")
widths_eq(lib.column_widths(4), { 0.5, 0.5, 0.5, 0.5 }, "4 columns → all half")

check(lib.after_remove_action(0) == "preserve", "remove 0 → preserve")
check(lib.after_remove_action(1) == "expand_lone", "remove to 1 → expand lone")
check(lib.after_remove_action(2) == "preserve", "remove to 2 → preserve Mod+m sizes")
check(lib.after_remove_action(3) == "preserve", "remove to 3 → preserve")

check(lib.after_add_action(0) == "none", "add 0 → none")
check(lib.after_add_action(1) == "expand_lone", "add to 1 → expand lone")
check(lib.after_add_action(2) == "normalize_pair", "add to 2 → normalize pair")
check(lib.after_add_action(3) == "size_new_half", "add to 3 → only new half")
check(lib.after_add_action(4) == "size_new_half", "add to 4 → only new half")

local filtered = lib.columns_except({ "a", "b", "c" }, "b")
check(#filtered == 2 and filtered[1] == "a" and filtered[2] == "c", "columns_except drops id")
check(#lib.columns_except(nil, "x") == 0, "columns_except nil → empty")

check(lib.view_count({ 1, 2, 3 }, 2) == 2, "view_count excludes dying view")
check(lib.view_count(nil, 1) == 0, "view_count nil → 0")

check(lib.should_go_home({ { 1 } }, 1) == true, "go home when only dying view remains")
check(lib.should_go_home({ { 1 }, { 2 } }, 1) == false, "stay when another workspace has a window")
check(lib.should_go_home({ {}, {} }, nil) == true, "go home when all empty")

check(lib.inner_gap_px(0) == lib.INNER_GAP, "gap when frames on with no windows")
check(lib.inner_gap_px(1) == lib.INNER_GAP, "gap with one window when frames on")
check(lib.inner_gap_px(2) == lib.INNER_GAP, "gap with two windows")
check(lib.inner_gap_px(3) == lib.INNER_GAP, "gap with three windows")
check(lib.inner_gap_px(3, false) == 0, "toggle off clears a multi-window gap")
check(lib.inner_gap_px(3, true) == lib.INNER_GAP, "toggle on keeps a multi-window gap")
check(lib.inner_gap_px(1, false) == 0, "toggle off stays flush with one window")
check(lib.inner_gap_px(1, true) == lib.INNER_GAP, "toggle on gaps a lone window")

check(lib.bar_frame_active(true) == true, "bar framed when frames on")
check(lib.bar_frame_active(nil) == true, "bar framed when frame file missing")
check(lib.bar_frame_active(false) == false, "bar flush when frames off")
check(lib.bar_gaps_cmd(true) == "bar potato gaps 8 8 0 8", "bar gaps on")
check(lib.bar_gaps_cmd(false) == "bar potato gaps 0", "bar gaps off")
check(lib.bar_radius_cmd(true) == "bar potato border_radius 8", "bar radius on")
check(lib.bar_radius_cmd(false) == "bar potato border_radius 0", "bar radius off")
check(lib.bar_border_cmd(true) == "bar potato border 2", "bar border on")
check(lib.bar_border_cmd(false) == "bar potato border 0", "bar border off")

print(string.format("\nautotile_lib: %d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
