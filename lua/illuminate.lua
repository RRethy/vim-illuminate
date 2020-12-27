-- vim.api.nvim_command('autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()')
-- vim.api.nvim_command('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
-- vim.api.nvim_command('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')
-- vim.api.nvim_command('hi def link LspReferenceText CursorLine')

local M = {}

function M.on_attached(client)
        -- vim.api.nvim_command('autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()')
    -- vim.api.nvim_command('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
    -- vim.api.nvim_command('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')
    vim.api.nvim_command('hi def link LspReferenceText CursorLine')
            -- local bufnr = api.nvim_get_current_buf()
        -- util.buf_highlight_references(bufnr, result)
    -- vim.api.nvim_command('hi LspReferenceText guibg=#00ff00')
    -- vim.api.nvim_command('hi LspReferenceRead guibg=#000000')
    -- vim.api.nvim_command('hi LspReferenceWrite guifg=#ffffff')

    vim.lsp.handlers['textDocument/documentHighlight'] = function(_, _, result, _)
        if not result then return end
        print(vim.inspect(result))
    end
end

return M
