" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Last Change:	2018 July 27
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.1

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
    autocmd CursorMoved,WinLeave,BufLeave,InsertEnter *
          \ if illuminatehelper#should_illuminate_file()
          \ |   call s:MaybeRemove_illumination()
          \ | endif
    autocmd WinLeave,BufLeave,InsertEnter *
          \ if illuminatehelper#should_illuminate_file()
          \ |   call s:Remove_illumination()
          \ | endif
    autocmd CursorHold,InsertLeave *
          \ if illuminatehelper#should_illuminate_file()
          \ |   call s:Illuminate()
          \ | endif
  augroup END
endif
" }}}

" Some state variables {{{
let s:match_ids = -1
let s:previous_match = ''
let s:enabled = 1
" }}}

" Commands {{{
command! -nargs=0 DisableIllumination let s:enabled = 0
      \ | call s:Remove_illumination()
command! -nargs=0 EnableIllumination let s:enabled = 1
      \ | if illuminatehelper#should_illuminate_file() | call s:Illuminate() | endif
" }}} Commands:

" All the messy functions {{{
fun! s:Illuminate() abort
  if !s:enabled
    return
  endif

  call s:Remove_illumination()

  let l:matched_word = s:Cur_word()
  if l:matched_word !~ @/ || !&hls || !v:hlsearch
    if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &ft)
      if index(g:Illuminate_ftHighlightGroups[&ft], synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")) >= 0
        let s:match_ids = matchadd("illuminatedWord", '\V' . l:matched_word)
        let s:previous_match = l:matched_word
      endif
    else
      let s:match_ids = matchadd("illuminatedWord", '\V' . l:matched_word)
      let s:previous_match = l:matched_word
    endif
  endif
endf

fun! s:Match_word(word)
  let s:match_ids = matchadd("illuminatedWord", '\V' . l:matched_word)
  let s:previous_match = l:matched_word
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
  if s:match_ids >= 0
    try
      call matchdelete(s:match_ids)
    catch /E803/
    endtry
    let s:match_ids = -1
  endif
endf
" }}}

" vim: foldlevel=0 foldmethod=marker
