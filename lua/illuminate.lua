-- TODO clear old highlighting on different cword
-- TODO delay as needed
-- TODO hi def link maybe
-- TODO change highlighting of word under cursor
-- TODO highlights can overlap (for return values likes `return true`), they should maybe have different highlighting

local M = {}

local timers = {}
local references = {}

function M.on_attach(_)
    vim.api.nvim_command [[ hi def link LspReferenceText CursorLine ]]
    vim.api.nvim_command [[ augroup nvim_lspconfig_document_highlight_augroup ]]
    vim.api.nvim_command [[   autocmd! ]]
    vim.api.nvim_command [[   autocmd CursorMoved,CursorMovedI <buffer> lua require'illuminate'.on_cursor_moved() ]]
    vim.api.nvim_command [[ augroup END ]]
    vim.lsp.handlers['textDocument/documentHighlight'] = handle_document_highlight
    vim.lsp.buf.document_highlight()
end

function M.on_cursor_moved()
    vim.lsp.buf.document_highlight()
end

function handle_document_highlight(err, method, result, client_id, bufnr, config)
    btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
    end
    if not cursor_in_references(bufnr) then
        vim.lsp.util.buf_clear_references(bufnr)
    end
    timers[bufnr] = vim.defer_fn(function()
        vim.lsp.util.buf_clear_references(bufnr)
        vim.lsp.util.buf_highlight_references(bufnr, result)
    end, vim.g.Illuminate_delay or 250)
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
        -- check for cursor col in [start,end)
        if crow >= range['start'].line and
            crow <= range['end'].line and
            ccol >= range['start'].character and
            ccol < range['end'].character then
            return true
        end
    end
    return false
end

return M
