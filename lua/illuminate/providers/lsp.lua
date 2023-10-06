local M = {}

local bufs = {}

local function _str_byteindex_enc(line, col, encoding)
    if not encoding then
        encoding = 'utf-16'
    end

    if encoding == 'utf-8' then
        if col then
            return col
        else
            return #line
        end
    elseif encoding == 'utf-16' then
        return vim.str_byteindex(line, col, true)
    elseif encoding == 'utf-32' then
        return vim.str_byteindex(line, col)
    else
        return col
    end
end

local function get_line_byte_from_position(bufnr, line, col, offset_encoding)
    if col == 0 then
        return col
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)
    if not lines or #lines == 0 then
        return col
    end
    local ok, result = pcall(_str_byteindex_enc, lines[1], col, offset_encoding)
    if ok then
        return result
    end
    return math.min(#(lines[1]), col)
end

function M.get_references(bufnr)
    if not bufs[bufnr] or not bufs[bufnr][3] then
        return nil
    end

    return bufs[bufnr][3]
end

function M.is_ready(bufnr)
    local supported = false
    if vim.lsp.for_each_buffer_client then
        supported = false
        vim.lsp.for_each_buffer_client(bufnr, function(client)
            if client and client.supports_method('textDocument/documentHighlight') then
                supported = true
            end
        end)
    end
    return supported
end

function M.initiate_request(bufnr, winid)
    local id = 1
    if bufs[bufnr] then
        local prev_id, cancel_fn, references = unpack(bufs[bufnr])
        if references == nil then
            pcall(cancel_fn)
        end
        id = prev_id + 1
    end

    local cancel_fn = vim.lsp.buf_request_all(
        bufnr,
        'textDocument/documentHighlight',
        vim.lsp.util.make_position_params(winid),
        function(client_results)
            if bufs[bufnr][1] ~= id then
                return
            end
            if not vim.api.nvim_buf_is_valid(bufnr) then
                bufs[bufnr][3] = {}
                return
            end

            local references = {}
            for client_id, results in pairs(client_results) do
                local client = vim.lsp.get_client_by_id(client_id)
                if client and results['result'] then
                    for _, res in ipairs(results['result']) do
                        local start_col = get_line_byte_from_position(
                            bufnr,
                            res['range']['start']['line'],
                            res['range']['start']['character'],
                            res['offset_encoding']
                        )
                        local end_col = get_line_byte_from_position(
                            bufnr,
                            res['range']['end']['line'],
                            res['range']['end']['character'],
                            res['offset_encoding']
                        )
                        table.insert(references, {
                            { res['range']['start']['line'], start_col },
                            { res['range']['end']['line'],   end_col },
                            res['kind'],
                        })
                    end
                end
            end

            bufs[bufnr][3] = references
        end
    )

    bufs[bufnr] = {
        id,
        cancel_fn,
    }
end

return M
