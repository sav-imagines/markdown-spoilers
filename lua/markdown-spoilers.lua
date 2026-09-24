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
local HL_NAME = "MarkdownSpoilers"

local M = {}

function M.update_spoilers()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_buf_idx = vim.api.nvim_get_current_buf()

	-- remove previous highlights
	vim.api.nvim_buf_clear_namespace(current_buf_idx, EXTMARK_NS, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(current_buf_idx, 0, -1, false)

	local comments = {}
	for i, line in pairs(lines) do
		if line == nil then
			break
		end
		-- positions with '||' in line
		local comments_in_line = line:find_match_indeces("||")
		local comment_count = #comments_in_line

		-- round down to nearest even number (ignore unclosed final ones, no multi-line spoilers)
		if comment_count % 2 ~= 0 then
			comment_count = comment_count - 1
		end

		if comment_count > 0 then
			for j = 1, comment_count, 2 do
				local start_col = comments_in_line[j] - 1
				local end_col = comments_in_line[j + 1] + 1
				local is_hovered = i == cursor_pos[1] and (start_col <= cursor_pos[2] and cursor_pos[2] < end_col)

				if not is_hovered then
					vim.api.nvim_buf_set_extmark(current_buf_idx, EXTMARK_NS, i - 1, comments_in_line[j] - 1, {
						end_line = i - 1,
						end_col = comments_in_line[j + 1] + 1,
						hl_group = HL_NAME,
					})
					table.append(comments, {
						line_idx = i,
						start_idx = comments_in_line[j],
						end_idx = comments_in_line[(j + 1)],
					})
				end
			end
		end
	end
end

function table.append(t, value)
	t[#t + 1] = value
end

---@param str string
---@param match string
---@return table<integer, integer>
function string.find_match_indeces(str, match)
	local matches_count = 0
	local match_len = #match

	---@type table<integer, integer>
	local matches = {}

	for i = 1, #str - 1 do
		if string.sub(str, i, i + (#match - 1)) == match then
			matches_count = matches_count + 1
			table.append(matches, i)
			i = i + match_len
		end
	end
	return matches
end

---@param opts table<string>|nil
function M.setup(opts)
	-- fallback to empty table
	opts = opts or {}
	opts._color = opts._color or "#6890d1"

	vim.api.nvim_set_hl(0, HL_NAME, {
		bg = opts._color,
		fg = opts._color,
	})

	-- on any of these, update the highlights
	vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CursorMoved" }, {
		pattern = { "*.md" },
		callback = M.update_spoilers,
	})
end

-- Return the module
return M
