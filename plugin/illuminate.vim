" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.3

if exists('g:loaded_illuminate')
  finish
endif

let g:loaded_illuminate = 1

" Highlight group(s) {{{
if !hlexists('illuminatedWord')
  hi link illuminatedWord cursorline
endif
" }}}

" Autocommands {{{
if has("autocmd")
  augroup illuminated_autocmd
    autocmd!
    autocmd CursorMoved,InsertLeave * call illuminate#on_cursor_moved()
    autocmd WinLeave,BufLeave * call illuminate#on_leaving_autocmds()
    autocmd InsertEnter * call illuminate#on_insert_entered()
  augroup END
else
  echoerr 'Illuminate requires vim compiled with +autocmd'
  finish
endif
" }}}

" Commands {{{
command! -nargs=0 IlluminationDisable call illuminate#disable_illumination()
command! -nargs=0 IlluminationEnable call illuminate#enable_illumination()
command! -nargs=0 IlluminationToggle call illuminate#toggle_illumination()

" Keep these for backwards compatibility
command! -nargs=0 DisableIllumination :IlluminationDisable
command! -nargs=0 EnableIllumination :IlluminationEnable
" }}} Commands:

" vim: foldlevel=0 foldmethod=marker
