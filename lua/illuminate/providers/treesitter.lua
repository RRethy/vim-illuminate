local M = {}

local buf_attached = {}

-- get_node is builtin in v0.9+, get_node_at_cursor is for older versions
local get_node_at_cursor = vim.treesitter.get_node or require('nvim-treesitter.ts_utils').get_node_at_cursor
function M.get_references(bufnr)
    local ok, locals = pcall(require, 'nvim-treesitter.locals')
    if not ok then
        return
    end

    local node_at_point = get_node_at_cursor()
    if not node_at_point then
        return
    end

    local refs = {}

    local maybe_def_node, scope = locals.find_definition(node_at_point, bufnr)
    -- Now it might be that `maybe_def_node` is a definition,
    -- but it might as well be that it is something else, for example, a comment.
    -- Through observation (in the absense of specification of `find_usages`),
    -- we know that for non-identifiers `find_usages(some_node)` returns `some_node`.
    -- Thus, we cautiously ignore `maybe_def_node`,
    -- in the sense that we don't mark it as writing yet.
    -- We will mark it later.
    -- If we can get back to this node through `find_usages`,
    -- then we know that this node was a definition,
    -- because `find_definition(some_node)` returns `some_node`,
    -- also when `some_node` is a definition,
    -- and `find_usages(some_node)` returns an empty list
    -- if `some_node` isn't an identifier
    -- (also known from oversvation, in the absense of specification).

    local usages = locals.find_usages(maybe_def_node, scope, bufnr)
    for _, node in ipairs(usages) do
        local range = { node:range() }
        -- If something is found through usages,
        -- we assume that it is a read.
        local kind = vim.lsp.protocol.DocumentHighlightKind.Read
        -- But if it is the `maybe_def_node` that we skipped (did not mark) above
        -- because we were not sure if it was an identifier,
        -- we now know that it is an identifier,
        -- because we found it through `find_usages`.
        if node == maybe_def_node then
            -- Yet, we cannot be sure that it is the definition of that identifier,
            -- because some things have their definition outside of the current file,
            -- for example, imported APIs.
            -- Thus, we must also check if this node is a definition.
            -- Performance: despite being in a loop, this check is done at most once,
            -- since `usages` contains no duplicates and only one `node` equals `maybe_def_node`.
           if is_definition(locals, node) then
               kind = vim.lsp.protocol.DocumentHighlightKind.Write
           end
        end

        table.insert(refs, {
            { range[1], range[2] },
            { range[3], range[4] },
            kind,
        })
    end

    return refs
end

-- Check if `node` is marked as a defintion (`locals.definition[.something]`)
-- Specification: https://github.com/nvim-treesitter/nvim-treesitter/blob/51bba660a89e0027929206b622c9c1cbdd995cfb/CONTRIBUTING.md#locals
function is_definition(locals, node)
    for _, entry in ipairs(locals.get_definitions(bufnr, 'locals.definition')) do
        if entry.node  == node then
            -- node marked as `locals.definition`
            return true
        else
            for _, sub in pairs(entry) do
                if sub.node == node then
                    -- node marked as `locals.definition.something`
                    return true
                end
            end
        end
    end
    return false
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
