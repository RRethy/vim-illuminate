local util = require('illuminate.util')

local M = {}

local config = {
    providers = {
        'lsp',
        'treesitter',
        'regex',
    },
    delay = 100,
    filetypes_denylist = {
        'dirvish',
        'fugitive',
    },
    filetypes_allowlist = {},
    modes_denylist = {},
    modes_allowlist = {},
    providers_regex_syntax_denylist = {},
    providers_regex_syntax_allowlist = {},
    under_cursor = true,
}

function M.set(config_overrides)
    config = vim.tbl_extend('force', config, config_overrides or {})

    if config then
        if config['delay'] < 17 then
            config['delay'] = 17
        end

        if config['providers'] then
            for _, provider in ipairs(config['providers']) do
                if type(provider) == 'table' then
                    for k, v in pairs(provider) do
                        if k ~= 'name' then
                            config['providers'][string.format('providers_%s_%s', provider.name, k)] = v
                        end
                    end
                end
            end
        end
    end
end

function M.debug()
    print(vim.inspect(config))
end

function M.get()
    return config
end

function M.filetypes_denylist()
    return config['filetypes_denylist'] or {}
end

function M.filetypes_allowlist()
    return config['filetypes_allowlist'] or {}
end

function M.modes_denylist()
    return config['modes_denylist'] or {}
end

function M.modes_allowlist()
    return config['modes_allowlist'] or {}
end

function M.provider_regex_syntax_denylist()
    return util.tbl_get(config, 'table', 'providers_regex_syntax_denylist') or {}
end

function M.provider_regex_syntax_allowlist()
    return util.tbl_get(config, 'table', 'providers_regex_syntax_allowlist') or {}
end

function M.under_cursor()
    return config['under_cursor']
end

return M
