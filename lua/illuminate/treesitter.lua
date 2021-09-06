local queries = require("nvim-treesitter.query")
local ts_utils = require'nvim-treesitter.ts_utils'
local locals = require'nvim-treesitter.locals'

local M = {}

local illuminate_treesitter_ns = vim.api.nvim_create_namespace('illuminate-treesitter')

local function augroup(bufnr, autocmds)
    vim.cmd('augroup vim_illuminate_treesitter'..bufnr)
    vim.cmd('autocmd!')
    if autocmds then
        autocmds()
    end
    vim.cmd('augroup END')
end

local function autocmd(bufnr)
    vim.cmd(string.format('autocmd CursorMoved,CursorMovedI <buffer=%d> lua require("illuminate.treesitter").on_cursor_moved(%d)', bufnr, bufnr))
end

local function cursor_in_references(bufnr)
end

local function clear_highlights(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, illuminate_treesitter_ns, 0, -1)
end

function M.on_cursor_moved(bufnr)
    if not cursor_in_references(bufnr) then
        clear_highlights(bufnr)
    end

    vim.defer_fn(function()
        local node_at_point = ts_utils.get_node_at_cursor()
        local references = locals.get_references(bufnr)
        print(vim.inspect(references))

        -- if not node_at_point or not vim.tbl_contains(references, node_at_point) then
        --     return
        -- end

        -- local def_node, scope = locals.find_definition(node_at_point, bufnr)
        -- local usages = locals.find_usages(def_node, scope, bufnr)

        -- for _, usage_node in ipairs(usages) do
        --     if usage_node ~= node_at_point then
        --         ts_utils.highlight_node(usage_node, bufnr, usage_namespace, 'TSDefinitionUsage')
        --     end
        -- end

        -- if def_node ~= node_at_point then
        --     ts_utils.highlight_node(def_node, bufnr, usage_namespace, 'TSDefinition')
        -- end
    end, vim.g.Illuminate_delay or 0)
end

function M.init()
    require('nvim-treesitter').define_modules {
        illuminate = {
            module_path = 'illuminate.treesitter',
            enable = false,
            disable = {},
            delay = 0,
            is_supported = queries.has_locals,
        }
    }
end

function M.attach(bufnr)
    if vim.b.illuminate_lsp_enabled then
        return
    end
    vim.b.illuminate_treesitter_enabled = true

    vim.cmd('IlluminationDisable!')
    augroup(bufnr, function()
        autocmd(bufnr)
    end)
end

function M.detach(bufnr)
    vim.b.illuminate_treesitter_enabled = false
    augroup(bufnr)
    clear_highlights(bufnr)
end

return M
