local ts_utils = require('nvim-treesitter.ts_utils')
local locals = require('nvim-treesitter.locals')

local M = {}

local buf_attached = {}

function M.get_references(bufnr)
    local node_at_point = ts_utils.get_node_at_cursor()
    if not node_at_point then
        return
    end

    local refs = {}

    local def_node, scope = locals.find_definition(node_at_point, bufnr)
    if def_node ~= node_at_point then
        local range = { def_node:range() }
        table.insert(refs, {
            { range[1], range[2] },
            { range[3], range[4] },
            vim.lsp.protocol.DocumentHighlightKind.Write,
        })
    end

    local usages = locals.find_usages(def_node, scope, bufnr)
    for _, node in ipairs(usages) do
        local range = { node:range() }
        table.insert(refs, {
            { range[1], range[2] },
            { range[3], range[4] },
            vim.lsp.protocol.DocumentHighlightKind.Read,
        })
    end

    return refs
end

function M.is_ready(bufnr)
    return buf_attached[bufnr] and vim.api.nvim_buf_get_option(bufnr, 'filetype') ~= 'yaml'
end

function M.attach(bufnr)
    buf_attached[bufnr] = true
end

function M.detach(bufnr)
    buf_attached[bufnr] = nil
end

return M
