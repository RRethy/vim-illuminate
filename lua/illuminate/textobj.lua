local util = require('illuminate.util')
local ref = require('illuminate.reference')

local M = {}

local visual_modes = {
    ['v'] = true,
    ['vs'] = true,
    ['V'] = true,
    ['Vs'] = true,
    ['CTRL-V'] = true,
    ['CTRL-Vs'] = true,
    ['s'] = true,
    ['S'] = true,
    ['CTRL-S'] = true,
}

function M.select()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    if i > #ref.buf_get_references(bufnr) then
        return
    end

    local reference = ref.buf_get_references(bufnr)[i]
    vim.api.nvim_win_set_cursor(winid, { reference[1][1] + 1, reference[1][2] })
    if not visual_modes[vim.api.nvim_get_mode().mode] then
        vim.cmd('normal! v')
    else
        vim.cmd('normal! o')
    end
    vim.api.nvim_win_set_cursor(winid, { reference[2][1] + 1, reference[2][2] - 1 })
end

return M
