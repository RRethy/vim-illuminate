local M = {}

-- @table pos
-- @field 1 (number) line (0-indexed)
-- @field 2 (number) col (0-indexed)
--
-- @table ref
-- @field 1 (table) start pos
-- @field 2 (table) end pos

local buf_references = {}

local function get_references(bufnr)
    return buf_references[bufnr] or {}
end

local function pos_before(pos1, pos2)
    if pos1[1] < pos2[1] then return true end
    if pos1[1] > pos2[1] then return false end
    if pos1[2] < pos2[2] then return true end
    return false
end

local function pos_equal(pos1, pos2)
    return pos1[1] == pos2[1] and pos1[2] == pos2[2]
end

local function ref_before(ref1, ref2)
    return pos_before(ref1[1], ref2[1]) or pos_equal(ref1[1], ref2[1]) and pos_before(ref1[2], ref2[2])
end

local function buf_sort_references(bufnr)
    local should_sort = false
    for i, ref in ipairs(get_references(bufnr)) do
        if i > 1 then
            if not ref_before(get_references(bufnr)[i - 1], ref) then
                should_sort = true
                break
            end
        end
    end

    if should_sort then
        table.sort(get_references(bufnr), ref_before)
    end
end

function M.is_pos_in_ref(pos, ref)
    return (pos_before(ref[1], pos) or pos_equal(ref[1], pos)) and (pos_before(pos, ref[2]) or pos_equal(pos, ref[2]))
end

function M.bisect_left(references, pos)
    local l, r = 1, #references + 1
    while l < r do
        local m = l + math.floor((r - l) / 2)
        if pos_before(references[m][2], pos) then
            l = m + 1
        else
            r = m
        end
    end
    return l
end

function M.buf_get_references(bufnr)
    return get_references(bufnr)
end

function M.buf_set_references(bufnr, references)
    buf_references[bufnr] = references
    buf_sort_references(bufnr)
end

function M.buf_cursor_in_references(bufnr, cursor_pos)
    if not get_references(bufnr) then
        return false
    end

    local i = M.bisect_left(get_references(bufnr), cursor_pos)

    if i > #get_references(bufnr) then
        return false
    end
    if not M.is_pos_in_ref(cursor_pos, get_references(bufnr)[i]) then
        return false
    end

    return true
end

return M
