local M = {}

local config = {
    providers = {
        'lsp',
        'treesitter',
        'regex',
    },
    delay = 100,
    filetype_overrides = {},
    filetypes_denylist = {
        'dirbuf',
        'dirvish',
        'fugitive',
    },
    filetypes_allowlist = {},
    modes_denylist = {},
    modes_allowlist = {},
    providers_regex_syntax_denylist = {},
    providers_regex_syntax_allowlist = {},
    under_cursor = true,
    max_file_lines = nil,
    large_file_cutoff = nil,
    large_file_config = nil,
    min_count_to_highlight = 1,
    should_enable = nil,
    case_insensitive_regex = false,
}

function M.set(config_overrides)
    config = vim.tbl_extend('force', config, config_overrides or {})
end

function M.get_raw()
    return config
end

function M.get()
    return (
            M.large_file_cutoff() == nil
            or vim.fn.line('$') <= M.large_file_cutoff()
            or M.large_file_overrides() == nil
        )
        and config
        or M.large_file_overrides()
end

function M.filetype_override(bufnr)
    local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    return M.get()['filetype_overrides'] and M.get()['filetype_overrides'][ft] or {}
end

function M.providers(bufnr)
    return M.filetype_override(bufnr)['providers'] or M.get()['providers']
end

function M.filetypes_denylist()
    return M.get()['filetypes_denylist'] or {}
end

function M.filetypes_allowlist()
    return M.get()['filetypes_allowlist'] or {}
end

function M.modes_denylist(bufnr)
    return M.filetype_override(bufnr)['modes_denylist'] or M.get()['modes_denylist'] or {}
end

function M.modes_allowlist(bufnr)
    return M.filetype_override(bufnr)['modes_allowlist'] or M.get()['modes_allowlist'] or {}
end

function M.provider_regex_syntax_denylist(bufnr)
    return M.filetype_override(bufnr)['providers_regex_syntax_denylist']
        or M.get()['providers_regex_syntax_denylist']
        or {}
end

function M.provider_regex_syntax_allowlist(bufnr)
    return M.filetype_override(bufnr)['providers_regex_syntax_allowlist']
        or M.get()['providers_regex_syntax_allowlist']
        or {}
end

function M.under_cursor(bufnr)
    if M.filetype_override(bufnr)['under_cursor'] ~= nil then
        return M.filetype_override(bufnr)['under_cursor'] ~= nil
    end
    return M.get()['under_cursor']
end

function M.delay(bufnr)
    local delay = M.filetype_override(bufnr)['delay'] or M.get()['delay'] or 17
    if string.sub(vim.api.nvim_get_mode().mode, 1, 1) == 'i' then
        delay = delay + 100
    end
    if delay < 17 then
        return 17
    end
    return delay
end

function M.max_file_lines()
    return M.get()['max_file_lines']
end

function M.large_file_cutoff()
    return config['large_file_cutoff']
end

function M.large_file_overrides()
    if config['large_file_overrides'] ~= nil then
        if config['large_file_overrides']['under_cursor'] == nil then
            config['large_file_overrides']['under_cursor'] = true
        end
        return config['large_file_overrides']
    end
    return {
        filetypes_allowlist = { '_none' }
    }
end

function M.min_count_to_highlight()
    return M.get()['min_count_to_highlight'] or 1
end

function M.should_enable()
    return M.get()['should_enable'] or function(_)
        return true
    end
end

function M.case_insensitive_regex()
    return M.get()['case_insensitive_regex']
end

return M
