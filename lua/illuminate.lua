local M = {}

local timers = {}
local references = {}
local paused_bufs = {}

-- returns r1 < r2 based on start of range
local function before_by_start(r1, r2)
    if r1['start'].line < r2['start'].line then return true end
    if r2['start'].line < r1['start'].line then return false end
    if r1['start'].character < r2['start'].character then return true end
    return false
end

-- returns r1 < r2 base on start and if they are disjoint
local function before_disjoint(r1, r2)
    if r1['end'].line < r2['start'].line then return true end
    if r2['start'].line < r1['end'].line then return false end
    if r1['end'].character < r2['start'].character then return true end
    return false
end

-- check for cursor row in [start,end]
-- check for cursor col in [start,end]
-- While the end is technically exclusive based on the highlighting, we treat it as inclusive to match the server.
local function point_in_range(point, range)
    if point.row == range['start']['line'] and point.col < range['start']['character'] then
        return false
    end
    if point.row == range['end']['line'] and point.col > range['end']['character'] then
        return false
    end
    return point.row >= range['start']['line'] and point.row <= range['end']['line']
end

local function cursor_in_references(bufnr)
    if not references[bufnr] then
        return false
    end
    if vim.api.nvim_win_get_buf(0) ~= bufnr then
        return false
    end
    local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
    crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col)
    for _, reference in pairs(references[bufnr]) do
        local range = reference.range
        if point_in_range({ row = crow, col = ccol }, range) then
            return true
        end
    end
    return false
end

local function handle_document_highlight(result, bufnr, client_id)
    if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then return end
    local btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
        -- vim.loop.close(btimer)
    end
    if type(result) ~= 'table' then
        vim.lsp.util.buf_clear_references(bufnr)
        return
    end
    timers[bufnr] = vim.defer_fn(function()
        if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then return end
        vim.lsp.util.buf_clear_references(bufnr)
        if cursor_in_references(bufnr) then
            local client = vim.lsp.get_client_by_id(client_id)
            if client then
                vim.lsp.util.buf_highlight_references(bufnr, result, client.offset_encoding)
            end
        end
    end, vim.g.Illuminate_delay or 17)
    table.sort(result, function(a, b)
        return before_by_start(a.range, b.range)
    end)
    references[bufnr] = result
end

local function valid(bufnr, range)
    return range
        and range.start.line < vim.api.nvim_buf_line_count(bufnr)
        and range.start.character < #vim.fn.getline(range.start.line + 1)
end

local function augroup(bufnr, autocmds)
    vim.cmd('augroup vim_illuminate_lsp' .. bufnr)
    vim.cmd('autocmd!')
    if autocmds then
        vim.b.illuminate_lsp_enabled = true
        autocmds()
    else
        vim.b.illuminate_lsp_enabled = false
    end
    vim.cmd('augroup END')
end

local function autocmd(bufnr)
    vim.cmd(string.format('autocmd CursorMoved,CursorMovedI <buffer=%d> lua require"illuminate".on_cursor_moved(%d)',
        bufnr, bufnr))
end

local function move_cursor(row, col)
    if not paused_bufs[vim.api.nvim_get_current_buf()] then
        augroup(vim.api.nvim_get_current_buf(), function()
            vim.api.nvim_win_set_cursor(0, { row, col })
            autocmd(vim.api.nvim_get_current_buf())
        end)
    else
        vim.api.nvim_win_set_cursor(0, { row, col })
    end
end

function M.on_attach(client)
    M.stop_buf()
    if client and not client.supports_method('textDocument/documentHighlight') then
        return
    end
    pcall(vim.api.nvim_command, 'IlluminationDisable!')
    augroup(vim.api.nvim_get_current_buf(), function()
        autocmd(vim.api.nvim_get_current_buf())
    end)
    vim.lsp.handlers['textDocument/documentHighlight'] = function(...)
        if vim.fn.has('nvim-0.5.1') == 1 then
            handle_document_highlight(select(2, ...), select(3, ...).bufnr, select(3, ...).client_id)
        else
            handle_document_highlight(select(3, ...), select(5, ...), nil)
        end
    end
    vim.lsp.buf.document_highlight()
end

function M.on_cursor_moved(bufnr)
    if not cursor_in_references(bufnr) then
        vim.lsp.util.buf_clear_references(bufnr)
    end

    -- Best-effort check if any client support textDocument/documentHighlight
    local supported = nil
    if vim.lsp.for_each_buffer_client then
        supported = false
        vim.lsp.for_each_buffer_client(bufnr, function(client)
            if client.supports_method('textDocument/documentHighlight') then
                supported = true
            end
        end)
    end

    if supported == nil or supported then
        vim.lsp.buf.document_highlight()
    else
        augroup(vim.api.nvim_get_current_buf(), function()
        end)
    end
end

function M.get_document_highlights(bufnr)
    return references[bufnr]
end

function M.next_reference(opt)
    opt = vim.tbl_extend('force', { reverse = false, wrap = false, range_ordering = 'start', silent = false }, opt or {})

    local before
    if opt.range_ordering == 'start' then
        before = before_by_start
    else
        before = before_disjoint
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local refs = M.get_document_highlights(bufnr)
    if not refs or #refs == 0 then return nil end

    local next = nil
    local nexti = nil
    local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
    local crange = { start = { line = crow - 1, character = ccol } }

    for i, ref in ipairs(refs) do
        local range = ref.range
        if valid(bufnr, range) then
            if opt.reverse then
                if before(range, crange) and (not next or before(next, range)) then
                    next = range
                    nexti = i
                end
            else
                if before(crange, range) and (not next or before(range, next)) then
                    next = range
                    nexti = i
                end
            end
        end
    end
    if not next and opt.wrap then
        nexti = opt.reverse and #refs or 1
        next = refs[nexti].range
    end
    if next then
        move_cursor(next.start.line + 1, next.start.character)
        if not opt.silent then
            print('[' .. nexti .. '/' .. #refs .. ']')
        end
    end
    return next
end

function M.toggle_pause()
    if paused_bufs[vim.api.nvim_get_current_buf()] then
        paused_bufs[vim.api.nvim_get_current_buf()] = false
        augroup(vim.api.nvim_get_current_buf(), function()
            autocmd(vim.api.nvim_get_current_buf())
        end)
        M.on_cursor_moved(vim.api.nvim_get_current_buf())
    else
        paused_bufs[vim.api.nvim_get_current_buf()] = true
        augroup(vim.api.nvim_get_current_buf(), nil)
    end
end

function M.configure(config)
    require('illuminate.config').set(config)
end

function M.pause()
    require('illuminate.engine').pause()
end

function M.resume()
    require('illuminate.engine').resume()
end

function M.toggle()
    require('illuminate.engine').toggle()
end

function M.toggle_buf()
    require('illuminate.engine').toggle_buf()
end

function M.pause_buf()
    require('illuminate.engine').pause_buf()
end

function M.stop_buf()
    require('illuminate.engine').stop_buf()
end

function M.resume_buf()
    require('illuminate.engine').resume_buf()
end

function M.freeze_buf()
    require('illuminate.engine').freeze_buf()
end

function M.unfreeze_buf()
    require('illuminate.engine').unfreeze_buf()
end

function M.toggle_freeze_buf()
    require('illuminate.engine').toggle_freeze_buf()
end

function M.invisible_buf()
    require('illuminate.engine').invisible_buf()
end

function M.visible_buf()
    require('illuminate.engine').visible_buf()
end

function M.toggle_visibility_buf()
    require('illuminate.engine').toggle_visibility_buf()
end

function M.goto_next_reference(wrap)
    if wrap == nil then
        wrap = vim.o.wrapscan
    end
    require('illuminate.goto').goto_next_reference(wrap)
end

function M.goto_prev_reference(wrap)
    if wrap == nil then
        wrap = vim.o.wrapscan
    end
    require('illuminate.goto').goto_prev_reference(wrap)
end

function M.textobj_select()
    require('illuminate.textobj').select()
end

function M.debug()
    require('illuminate.engine').debug()
end

function M.is_paused()
    return require('illuminate.engine').is_paused()
end

function M.set_highlight_defaults()
    vim.cmd [[
    hi def IlluminatedWordText guifg=none guibg=none gui=underline
    hi def IlluminatedWordRead guifg=none guibg=none gui=underline
    hi def IlluminatedWordWrite guifg=none guibg=none gui=underline
    ]]
end

return M
