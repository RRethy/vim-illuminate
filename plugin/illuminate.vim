" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Last Change:	2018 July 28
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.2

if exists('g:loaded_illuminate')
  finish
endif

let g:loaded_illuminate = 1

if !exists('g:Illuminate_delay')
  let g:Illuminate_delay = 250
endif

" Highlight group(s) {{{
if !hlexists('illuminatedWord')
  hi link illuminatedWord cursorline
endif
" }}}

" Autocommands {{{
if has("autocmd")
  augroup illuminated_autocmd
    autocmd!
    autocmd CursorMoved,InsertLeave * call s:Handle_cursor_moved()
    autocmd WinLeave,BufLeave,InsertEnter * call s:Handle_removal_autocmds()
  augroup END
else
  echoerr 'Illuminate requires vim compiled with +autocmd'
  finish
endif
" }}}

" Some state variables {{{
let s:match_id = 1867
let s:priority = 10
let s:previous_match = ''
let s:enabled = 1
" }}}

" Commands {{{
command! -nargs=0 DisableIllumination let s:enabled = 0
      \ | call s:Remove_illumination()
command! -nargs=0 EnableIllumination let s:enabled = 1
      \ | if illuminatehelper#should_illuminate_file() | call g:Illuminate() | endif
" }}} Commands:

" All the messy functions {{{
fun! s:Handle_cursor_moved()
  if !has('timers')
    call g:Illuminate()
    return
  endif

  if illuminatehelper#should_illuminate_file()
    call s:MaybeRemove_illumination()
    if exists('s:timer_id') && s:timer_id > -1
      call timer_stop(s:timer_id)
    endif
    let s:timer_id = timer_start(g:Illuminate_delay, 'g:Illuminate')
  endif
endf

fun! s:Handle_removal_autocmds()
  if illuminatehelper#should_illuminate_file()
    call s:MaybeRemove_illumination()
  endif
endf

fun! g:Illuminate(...) abort
  if !s:enabled
    return
  endif

  call s:Remove_illumination()

  let l:matched_word = s:Cur_word()
  if l:matched_word !~ @/ || !&hls || !v:hlsearch
    if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &ft)
      if index(g:Illuminate_ftHighlightGroups[&ft], synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")) >= 0
        call s:Match_word(l:matched_word)
      endif
    else
      call s:Match_word(l:matched_word)
    endif
  endif
endf

fun! s:Match_word(word)
  silent! call matchadd("illuminatedWord", '\V' . a:word, s:priority, s:match_id)
  let s:previous_match = a:word
endf

fun! s:Cur_word()
  return '\<' . expand("<cword>") . '\>'
endf

fun! s:MaybeRemove_illumination()
  if (s:previous_match != s:Cur_word())
    call s:Remove_illumination()
  endif
endf

fun! s:Remove_illumination()
  if has('timers') && exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
    let s:timer_id = -1
  endif

  try
    call matchdelete(s:match_id)
  catch /E803/
  endtry
endf
" }}}

" vim: foldlevel=0 foldmethod=marker
