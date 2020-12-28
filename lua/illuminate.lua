local api, lsp = vim.api, vim.lsp

local M = {}

-- TODO clear old highlighting if on different cword
-- TODO delay as needed
-- TODO hi def link maybe
-- TODO change highlighting of word under cursor
-- TODO highlights can overlap (for return values likes `return true`), they should maybe have different highlighting

function M.on_attach(_)
    api.nvim_command [[ hi def link LspReferenceText CursorLine ]]
    api.nvim_command [[ augroup nvim_lspconfig_document_highlight_augroup ]]
    api.nvim_command [[   autocmd! ]]
    api.nvim_command [[   autocmd CursorMoved,CursorMovedI <buffer> lua vim.lsp.buf.document_highlight() ]]
    api.nvim_command [[ augroup END ]]
    lsp.handlers['textDocument/documentHighlight'] = handle_document_highlight
    lsp.buf.document_highlight()
end

function handle_document_highlight(err, method, result, client_id, bufnr, config)
    lsp.util.buf_clear_references(bufnr)
    lsp.util.buf_highlight_references(bufnr, result)
end

return M
