-- Markdown Spoilers, a Neovim plugin

-- Copyright (C) 2026 Sav-Imagines

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local EXTMARK_NS = vim.api.nvim_create_namespace("markdown-spoilers")
local HL_NAME_SHOW = "MarkdownSpoilersShow"
local HL_NAME_HIDE = "MarkdownSpoilersHide"

local M = {
	show_all = false, ---@type boolean
}

function M.toggle_spoilers()
	M.show_all = not M.show_all
	M.update_spoilers()
end

function M.show_spoilers()
	M.show_all = true
	M.update_spoilers()
end

function M.hide_spoilers()
	M.show_all = false
	M.update_spoilers()
end

function M.update_spoilers()
	local current_buf_idx = vim.api.nvim_get_current_buf()

	-- remove previous highlights
	vim.api.nvim_buf_clear_namespace(current_buf_idx, EXTMARK_NS, 0, -1)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(current_buf_idx, 0, -1, false)

	for rowIdx, line in pairs(lines) do
		-- positions with '||' in line
		local comment_pairs = line:_find_match_pairs("||")

		local is_on_line = rowIdx == cursor_pos[1]
		for _, pair in ipairs(comment_pairs) do
			local is_hovered = is_on_line and (pair.start_pos <= cursor_pos[2] and cursor_pos[2] < pair.end_pos)

			local line_number = rowIdx - 1 -- rowIdx is 0-indexed
			local HL_GROUP
			if is_hovered or M.show_all then
				HL_GROUP = HL_NAME_SHOW
			else
				HL_GROUP = HL_NAME_HIDE
			end
			vim.api.nvim_buf_set_extmark(current_buf_idx, EXTMARK_NS, line_number, pair.start_pos, {
				end_line = line_number,
				end_col = pair.end_pos, -- include final character
				hl_group = HL_GROUP,
			})
		end
	end
end

---@class Position
---@field start_pos number
---@field end_pos number
---@alias PosList Position[]

---@param str string
---@param match string
---@return PosList
function string._find_match_pairs(str, match)
	local matches_count = 0
	local match_len = #match

	---@type PosList
	local matches = {}

	local last_found = nil ---@type integer|nil
	for i = 1, #str - 1 do
		if string.sub(str, i, i + (#match - 1)) == match then
			matches_count = matches_count + 1
			if last_found then
				local pos = { start_pos = last_found - 1, end_pos = i + 1 } ---@type Position
				table.insert(matches, pos)
				last_found = nil
			else
				last_found = i
			end

			i = i + match_len -- skip ahead after match
		end
	end
	return matches
end

function M._register_commands()
	local current_buf_idx = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_create_user_command(current_buf_idx, "ShowSpoilers", M.show_spoilers, {})
	vim.api.nvim_buf_create_user_command(current_buf_idx, "HideSpoilers", M.hide_spoilers, {})
	vim.api.nvim_buf_create_user_command(current_buf_idx, "ToggleSpoilers", M.toggle_spoilers, {})
end

---@param opts table<string>|nil
function M.setup(opts)
	-- fallback to empty table
	opts = opts or {}
	opts.color = opts.color or "#6890d1"

	vim.api.nvim_set_hl(0, HL_NAME_SHOW, {
		bg = opts.color,
		--fg = "#885588",
	})

	vim.api.nvim_set_hl(0, HL_NAME_HIDE, {
		bg = opts.color,
		fg = opts.color,
	})

	-- on any of these, update the highlights
	vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CursorMoved" }, {
		pattern = { "*.md" },
		callback = M.update_spoilers,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.md" },
		callback = M._register_commands,
	})
end

-- Return the module
return M
