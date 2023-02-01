" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 2.0

if exists('g:loaded_illuminate')
  finish
endif

let g:loaded_illuminate = 1

if has('nvim-0.7.2') && get(g:, 'Illuminate_useDeprecated', 0) != 1
lua << EOF
    local ok, ts = pcall(require, 'nvim-treesitter')
    if ok then
        ts.define_modules({
            illuminate = {
                module_path = 'illuminate.providers.treesitter',
                enable = true,
                disable = {},
                is_supported = require('nvim-treesitter.query').has_locals,
            }
        })
    end
    require('illuminate.engine').start()
    vim.api.nvim_create_user_command('IlluminatePause', require('illuminate').pause, { bang = true })
    vim.api.nvim_create_user_command('IlluminateResume', require('illuminate').resume, { bang = true })
    vim.api.nvim_create_user_command('IlluminateToggle', require('illuminate').toggle, { bang = true })
    vim.api.nvim_create_user_command('IlluminatePauseBuf', require('illuminate').pause_buf, { bang = true })
    vim.api.nvim_create_user_command('IlluminateResumeBuf', require('illuminate').resume_buf, { bang = true })
    vim.api.nvim_create_user_command('IlluminateToggleBuf', require('illuminate').toggle_buf, { bang = true })
    vim.api.nvim_create_user_command('IlluminateDebug', require('illuminate').debug, { bang = true })

    if not require('illuminate.util').has_keymap('n', '<a-n>') then
        vim.keymap.set('n', '<a-n>', require('illuminate').goto_next_reference, { desc = "Move to next reference" })
    end
    if not require('illuminate.util').has_keymap('n', '<a-p>') then
        vim.keymap.set('n', '<a-p>', require('illuminate').goto_prev_reference, { desc = "Move to previous reference" })
    end
    if not require('illuminate.util').has_keymap('o', '<a-i>') then
        vim.keymap.set('o', '<a-i>', require('illuminate').textobj_select)
    end
    if not require('illuminate.util').has_keymap('x', '<a-i>') then
        vim.keymap.set('x', '<a-i>', require('illuminate').textobj_select)
    end
EOF

lua require('illuminate').set_highlight_defaults()
augroup vim_illuminate_autocmds
    autocmd!
    autocmd ColorScheme * lua require('illuminate').set_highlight_defaults()
augroup END

finish
end

" Highlight group(s) {{{
if !hlexists('illuminatedWord')
  " this is for backwards compatibility
  if !empty(get(g:, 'Illuminate_hl_link', ''))
    exe get(g:, 'Illuminate_hl_link', '')
  else
    hi def link illuminatedWord cursorline
  endif
endif
" }}}

" Autocommands {{{
if has('autocmd')
  augroup illuminated_autocmd
    autocmd!
    autocmd CursorMoved,InsertLeave * call illuminate#on_cursor_moved()
    autocmd WinLeave,BufLeave * call illuminate#on_leaving_autocmds()
    autocmd CursorMovedI * call illuminate#on_cursor_moved_i()
    autocmd InsertEnter * call illuminate#on_insert_entered()
  augroup END
else
  echoerr 'Illuminate requires Vim compiled with +autocmd'
  finish
endif
" }}}

" Commands {{{
command! -nargs=0 -bang IlluminationDisable call illuminate#disable_illumination(<bang>0)
command! -nargs=0 -bang IlluminationEnable call illuminate#enable_illumination(<bang>0)
command! -nargs=0 -bang IlluminationToggle call illuminate#toggle_illumination(<bang>0)
" }}} Commands:

" vim: foldlevel=1 foldmethod=marker
