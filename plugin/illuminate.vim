" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.3

if exists('g:loaded_illuminate')
  finish
endif

let g:loaded_illuminate = 1

" Configuration {{{
let g:Illuminate_delay = get(g:, 'Illuminate_delay', 250)
let g:Illuminate_highlightUnderCursor = get(g:, 'Illuminate_highlightUnderCursor', 1)
let g:Illuminate_highlightPriority = get(g:, 'Illuminate_highlightPriority', -1)
let g:Illuminate_ftblacklist=get(g:,'Illuminate_ftblacklist',['']) " Blacklist empty filetype by default
let g:Illuminate_ftwhitelist=get(g:,'Illuminate_ftwhitelist',[])
let g:Illuminate_ftblacklist_regex=get(g:,'Illuminate_ftblacklist_regex','')
let g:Illuminate_ftwhitelist_regex=get(g:,'Illuminate_ftwhitelist_regex',"")
" }}}

" Highlight group(s) {{{
if !hlexists('illuminatedWord')
  " this is for backwards compatibility
  if !empty(get(g:, 'Illuminate_hl_link', ''))
    exe get(g:, 'Illuminate_hl_link', '')
  else
    hi link illuminatedWord cursorline
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

" Keep these for backwards compatibility
command! -nargs=0 DisableIllumination :IlluminationDisable
command! -nargs=0 EnableIllumination :IlluminationEnable
" }}} Commands:

" vim: foldlevel=1 foldmethod=marker expandtab tabstop=2
