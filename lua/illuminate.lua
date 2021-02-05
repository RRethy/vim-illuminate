local M = {}

local timers = {}
local references = {}

-- returns r1 < r2 based on start of range
local function before(r1, r2)
    if r1.start.line < r2.start.line then return true end
    if r2.start.line < r1.start.line then return false end
    if r1.start.character < r2.start.character then return true end
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
        if point_in_range({row=crow,col=ccol}, range) then
            return true
        end
    end
    return false
end

local function handle_document_highlight(_, _, result, _, bufnr, _) -- TODO use client_id
    if not bufnr then return end
    local btimer = timers[bufnr]
    if btimer then
        vim.loop.timer_stop(btimer)
    end
    if type(result) ~= 'table' then
        vim.lsp.util.buf_clear_references(bufnr)
        return
    end
    timers[bufnr] = vim.defer_fn(function()
        vim.lsp.util.buf_clear_references(bufnr)
        if cursor_in_references(bufnr) then
            vim.lsp.util.buf_highlight_references(bufnr, result)
        end
    end, vim.g.Illuminate_delay or 0)
    table.sort(result, function(a, b)
        return before(a.range, b.range)
    end)
    references[bufnr] = result
end

local function valid(bufnr, range)
    return range
        and range.start.line < vim.api.nvim_buf_line_count(bufnr)
        and range.start.character < #vim.fn.getline(range.start.line + 1)
end

local function augroup(bufnr, autocmds)
    vim.cmd('augroup vim_illuminate_lsp'..bufnr)
    vim.cmd('autocmd!')
    autocmds()
    vim.cmd('augroup END')
end

local function autocmd()
    vim.cmd('autocmd CursorMoved,CursorMovedI <buffer> lua require"illuminate".on_cursor_moved()')
end

local function move_cursor(row, col)
    augroup(vim.api.nvim_get_current_buf(), function()
        vim.api.nvim_win_set_cursor(0, {row, col})
        autocmd()
    end)
end

function M.on_attach(_)
    vim.api.nvim_command [[ IlluminationDisable! ]]
    augroup(vim.api.nvim_get_current_buf(), function()
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

function M.next_reference(opt)
    opt = vim.tbl_extend('force', {reverse=false, wrap=false}, opt or {})

	local bufnr = vim.api.nvim_get_current_buf()
    local refs = M.get_document_highlights(bufnr)
    if not refs or #refs == 0 then return nil end

	local next = nil
    local nexti = nil
	local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
	local crange = {start={line=crow-1,character=ccol}}

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
        print('['..nexti..'/'..#refs..']')
    end
    return next
end

return M
