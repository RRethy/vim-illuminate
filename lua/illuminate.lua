local M = {}

local timers = {}
local references = {}

local function handle_document_highlight(_, _, result, _, bufnr, _) -- TODO use client_id
    if not bufnr then return end
    local btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
    end
    if type(result) ~= 'table' then return end
    -- TODO fix getting out of sync when doing a macro
    timers[bufnr] = vim.defer_fn(function()
        vim.lsp.util.buf_clear_references(bufnr)
        vim.lsp.util.buf_highlight_references(bufnr, result)
    end, vim.g.Illuminate_delay or 250)
    references[bufnr] = result
end

-- check for cursor row in [start,end]
-- check for cursor col in [start,end]
-- While the end is technically exclusive based on the highlighting, we treat it as inclusive to match the server.
local function in_range(point, range)
    if point.row == range['start']['line'] and point.col < range['start']['character'] then
        return false
    end
    if point.row == range['end']['line'] and point.col > range['end']['character'] then
        return false
    end
    return point.row >= range['start']['line'] and point.row <= range['end']['line']
end

local function cursor_in_references(bufnr)
    if not references[bufnr] then
        return false
    end
    if vim.api.nvim_win_get_buf(0) ~= bufnr then
        return false
    end
    local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
    crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)
    for _, reference in pairs(references[bufnr]) do
        local range = reference.range
        if in_range({row=crow,col=ccol}, range) then
            return true
        end
    end
    return false
end

function M.on_attach(_)
    vim.api.nvim_command [[ IlluminationDisable! ]]
    vim.api.nvim_command [[ autocmd CursorMoved,CursorMovedI <buffer> lua require'illuminate'.on_cursor_moved() ]]
    vim.lsp.handlers['textDocument/documentHighlight'] = handle_document_highlight
    vim.lsp.buf.document_highlight()
end

function M.on_cursor_moved()
    local bufnr = vim.api.nvim_get_current_buf()
    if not cursor_in_references(bufnr) then
        vim.lsp.util.buf_clear_references(bufnr)
    else
    end
    vim.lsp.buf.document_highlight()
end

return M
