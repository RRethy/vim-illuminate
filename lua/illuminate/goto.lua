local util = require('illuminate.util')
local ref = require('illuminate.reference')
local engine = require('illuminate.engine')

local M = {}

function M.goto_next_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i + 1
    if i > #ref.buf_get_references(bufnr) then
        if wrap then
            i = 1
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_next_reference hit BOTTOM of the references")
            return
        end
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end

function M.goto_prev_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i - 1
    if i == 0 then
        if wrap then
            i = #ref.buf_get_references(bufnr)
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_prev_reference hit TOP of the references")
            return
        end
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd('normal! m`')
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end

return M
