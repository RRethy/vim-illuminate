local util = require('illuminate.util')
local ref = require('illuminate.reference')
local engine = require('illuminate.engine')

local M = {}

function M.goto_next_reference()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    if i + 1 > #ref.buf_get_references(bufnr) then
        if vim.api.nvim_get_option('wrapscan') then
            i = 1
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: cannot go beyond LAST reference")
        end
    else
        i = i + 1
    end
    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end

function M.goto_prev_reference()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    if i == 1 then
        if vim.api.nvim_get_option('wrapscan') then
            i = #ref.buf_get_references(bufnr)
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: cannot go beyond FIRST reference")
        end
    else
        i = i - 1
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end

return M
