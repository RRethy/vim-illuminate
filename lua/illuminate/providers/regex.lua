local config = require('illuminate.config')
local util = require('illuminate.util')

local M = {}

local START_WORD_REGEX = vim.regex([[^\k*]])
local END_WORD_REGEX = vim.regex([[\k*$]])

local function get_cur_word(bufnr, cursor)
    local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1], cursor[1] + 1, false)[1]
    local left_part = string.sub(line, 0, cursor[2] + 1)
    local right_part = string.sub(line, cursor[2] + 1)
    local start_idx, _ = END_WORD_REGEX:match_str(left_part)
    local _, end_idx = START_WORD_REGEX:match_str(right_part)
    local word = string.format('%s%s', string.sub(left_part, start_idx + 1), string.sub(right_part, 2, end_idx))
    return [[\V\<]] .. vim.fn.escape(word, [[/\]]) .. [[\>]]
end

function M.get_references(bufnr, cursor)
    local refs = {}
    local re = vim.regex(get_cur_word(bufnr, cursor))
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    for i = 0, line_count - 1 do
        local start_byte, end_byte = 0, 0
        while true do
            local start_offset, end_offset = re:match_line(bufnr, i, end_byte)
            if not start_offset then break end

            start_byte = end_byte + start_offset
            end_byte = end_byte + end_offset
            table.insert(refs, {
                { i, start_byte },
                { i, end_byte },
                vim.lsp.protocol.DocumentHighlightKind.Text,
            })
        end
    end

    return refs
end

function M.is_ready()
    local name = vim.fn.synIDattr(
        vim.fn.synIDtrans(
            vim.fn.synID(vim.fn.line('.'), vim.fn.col('.'), 1)
        ),
        'name'
    )
    if util.is_allowed(
        config.provider_regex_syntax_allowlist(),
        config.provider_regex_syntax_denylist(),
        name
    ) then
        return true
    end
    return false
end

return M
