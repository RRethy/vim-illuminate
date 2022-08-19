local util = require('illuminate.util')
local ref = require('illuminate.reference')

local M = {}

function M.goto_next_reference()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i + 1
    if i > #ref.buf_get_references(bufnr) then
        i = 1
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
end

function M.goto_prev_reference()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i - 1
    if i == 0 then
        i = #ref.buf_get_references(bufnr)
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
end

return M
