local M = {}

local timers = {}
local references = {}

local function handle_document_highlight(_, _, result, _, bufnr, _) -- TODO use client_id
    if not bufnr then return end
    local btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
    end
    if type(result) ~= 'table' then return end
    -- TODO fix getting out of sync when doing a macro
    timers[bufnr] = vim.defer_fn(function()
        vim.lsp.util.buf_clear_references(bufnr)
        vim.lsp.util.buf_highlight_references(bufnr, result)
    end, vim.g.Illuminate_delay or 250)
    references[bufnr] = result
end

-- check for cursor row in [start,end]
-- check for cursor col in [start,end]
-- While the end is technically exclusive based on the highlighting, we treat it as inclusive to match the server.
local function in_range(point, range)
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
        if in_range({row=crow,col=ccol}, range) then
            return true
        end
    end
    return false
end

-- returns true if r1 is before r2 by starting position, otherwise false
local function before(r1, r2)
    if r1.start.line < r2.start.line then return true end
    if r2.start.line < r1.start.line then return false end
    if r1.start.character < r2.start.character then return true end
    return false
end

local function valid(bufnr, range)
    return range.start.line < vim.api.nvim_buf_line_count(bufnr) and range.start.character < #vim.fn.getline(range.start.line + 1)
end

local function next_ref(bufnr)
    local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
    crow = crow - 1 -- reference ranges are (0,0)-indexed for (row,col) while cursor it (1,0)-indexed
    local refs = M.get_document_highlights(bufnr)
    if not refs then return nil end

    local next = nil
    local first = nil
    for _, ref in pairs(refs) do
        local range = ref.range
        if valid(bufnr, range) then
            if first then
                if before(range, first) then first = range end
            else
                first = range
            end
            if before({start={line=crow,character=ccol}}, range) then
                if next and before(range, next) or not next then next = range end
            end
        end
    end
    -- if we didn't find a next, then return the first range
    return next and next or first
end

local function augroup(autocmds)
    vim.cmd('augroup vim_illuminate_lsp')
    vim.cmd('autocmd!')
    autocmds()
    vim.cmd('augroup END')
end

local function autocmd()
    vim.cmd('autocmd CursorMoved,CursorMovedI <buffer> lua require"illuminate".on_cursor_moved()')
end

function M.on_attach(_)
    vim.api.nvim_command [[ IlluminationDisable! ]]
    augroup(function()
        autocmd()
    end)
    vim.lsp.handlers['textDocument/documentHighlight'] = handle_document_highlight
    vim.lsp.buf.document_highlight()
end

function M.on_cursor_moved()
    local bufnr = vim.api.nvim_get_current_buf()
    if not cursor_in_references(bufnr) then
        vim.lsp.util.buf_clear_references(bufnr)
    end
    vim.lsp.buf.document_highlight()
end

function M.get_document_highlights(bufnr)
    return references[bufnr]
end

function M.jump_next_document_highlight()
    -- this will avoid triggering another CursorMoved autocmd when moving the cursor
    -- we do a autocmd! to clear the autocmd and then redefine it
    augroup(function()
        local bufnr = vim.api.nvim_get_current_buf()
        local range = next_ref(bufnr)
        if range then
            vim.api.nvim_win_set_cursor(0, {range.start.line + 1, range.start.character})
        end
        autocmd()
    end)
end

return M
