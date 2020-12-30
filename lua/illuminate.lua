local M = {}

local timers = {}
local references = {}

function M.on_attach(_)
    vim.api.nvim_command [[ IlluminationDisable! ]]
    vim.api.nvim_command [[ autocmd CursorMoved,CursorMovedI <buffer> lua require'illuminate'.on_cursor_moved() ]]
    vim.lsp.handlers['textDocument/documentHighlight'] = handle_document_highlight
    vim.lsp.buf.document_highlight()
end

function M.on_cursor_moved()
    bufnr = vim.api.nvim_get_current_buf()
    if not cursor_in_references(bufnr) then
        vim.lsp.util.buf_clear_references(bufnr)
    end
    vim.lsp.buf.document_highlight()
end

function handle_document_highlight(err, method, result, client_id, bufnr, config)
    btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
    end
    timers[bufnr] = vim.defer_fn(function()
        vim.lsp.util.buf_clear_references(bufnr)
        vim.lsp.util.buf_highlight_references(bufnr, result)
    end, vim.g.Illuminate_delay or 0)
    references[bufnr] = result
end

function cursor_in_references(bufnr)
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
        -- check for cursor row in [start,end]
        -- check for cursor col in [start,end]
        if crow >= range['start'].line and
            crow <= range['end'].line and
            ccol >= range['start'].character and
            ccol <= range['end'].character then
            return true
        end
    end
    return false
end

return M
