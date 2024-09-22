local util = require('illuminate.util')
local config = require('illuminate.config')
local ref = require('illuminate.reference')

local M = {}

local HL_NAMESPACE = vim.api.nvim_create_namespace('illuminate.highlight')

local function kind_to_hl_group(kind)
    return kind == vim.lsp.protocol.DocumentHighlightKind.Text and 'IlluminatedWordText'
        or kind == vim.lsp.protocol.DocumentHighlightKind.Read and 'IlluminatedWordRead'
        or kind == vim.lsp.protocol.DocumentHighlightKind.Write and 'IlluminatedWordWrite'
        or 'IlluminatedWordText'
end

function M.buf_highlight_references(bufnr, references)
    if config.min_count_to_highlight() > #references then
        return
    end

    local cursor_pos = util.get_cursor_pos()
    for _, reference in ipairs(references) do
        if config.under_cursor(bufnr) or not ref.is_pos_in_ref(cursor_pos, reference) then
            M.range(
                bufnr,
                reference[1],
                reference[2],
                reference[3]
            )
        end
    end
end

function M.range(bufnr, start, finish, kind)
    local start_l, start_col = unpack(start)
    local finish_l, finish_col = unpack(finish)
    start = { bufnr, start_l + 1, start_col + 1 }
    finish = { bufnr, finish_l + 1, finish_col + 1 }

    local region = vim.fn.getregionpos(start, finish, { type = "v", exclusive = true })

    for _, segment in ipairs(region) do
        local start_pos, finish_pos = unpack(segment)

        vim.api.nvim_buf_set_extmark(bufnr, HL_NAMESPACE, start_pos[2] - 1, start_pos[3] - 1, {
            hl_group = kind_to_hl_group(kind),
            end_col = finish_pos[3],
            priority = 199,
            strict = false,
        })
    end
end

function M.buf_clear_references(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, HL_NAMESPACE, 0, -1)
end

return M
