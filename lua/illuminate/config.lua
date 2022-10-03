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
}

function M.set(config_overrides)
    config = vim.tbl_extend('force', config, config_overrides or {})
end

function M.get()
    return (
        M.large_file_cutoff() == nil
            or vim.fn.line('$') <= config.large_file_cutoff()
            or M.large_file_config() == nil
        )
        and config
        or M.large_file_config()
end

function M.filetype_override(bufnr)
    local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    return config['filetype_overrides'] and config['filetype_overrides'][ft] or {}
end

function M.providers(bufnr)
    return M.filetype_override(bufnr)['providers'] or config['providers']
end

function M.filetypes_denylist()
    return config['filetypes_denylist'] or {}
end

function M.filetypes_allowlist()
    return config['filetypes_allowlist'] or {}
end

function M.modes_denylist(bufnr)
    return M.filetype_override(bufnr)['modes_denylist'] or config['modes_denylist'] or {}
end

function M.modes_allowlist(bufnr)
    return M.filetype_override(bufnr)['modes_allowlist'] or config['modes_allowlist'] or {}
end

function M.provider_regex_syntax_denylist(bufnr)
    return M.filetype_override(bufnr)['providers_regex_syntax_denylist']
        or config['providers_regex_syntax_denylist']
        or {}
end

function M.provider_regex_syntax_allowlist(bufnr)
    return M.filetype_override(bufnr)['providers_regex_syntax_allowlist']
        or config['providers_regex_syntax_allowlist']
        or {}
end

function M.under_cursor(bufnr)
    if M.filetype_override(bufnr)['under_cursor'] ~= nil then
        return M.filetype_override(bufnr)['under_cursor'] ~= nil
    end
    return config['under_cursor']
end

function M.delay(bufnr)
    local delay = M.filetype_override(bufnr)['delay'] or config['delay'] or 17
    if delay < 17 then
        return 17
    end
    return delay
end

function M.max_file_lines()
    return config['max_file_lines']
end

function M.large_file_cutoff()
    return config['large_file_cutoff']
end

function M.large_file_config()
    return config['large_file_config'] or {
        filetypes_allowlist = { '_none' }
    }
end

return M
