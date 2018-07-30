" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.3

" Some local variables {{{
let s:match_id = 1867
let s:priority = 10
let s:previous_match = ''
let s:enabled = 1
" }}}

" g:Illuminate_delay init {{{
if !exists('g:Illuminate_delay')
  let g:Illuminate_delay = 250
endif
" }}}

" Exposed functions {{{
fun! illuminate#on_cursor_moved() abort
  if !s:should_illuminate_file()
    return
  endif

  if (s:previous_match != s:get_cur_word())
    call s:remove_illumination()
  else
    return
  endif

  if !has('timers')
    call s:illuminate()
    return
  endif

  if exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
  endif

  " Only use timer if it's needed
  if g:Illuminate_delay > 0
    let IlluminateFn = function('s:illuminate')
    let s:timer_id = timer_start(g:Illuminate_delay, IlluminateFn)
  else
    let s:timer_id = -1
    call s:illuminate()
  endif
endf

fun! illuminate#on_leaving_autocmds() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun illuminate#on_insert_entered() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#disable_illumination() abort
  let s:enabled = 0
  call s:remove_illumination()
endf

fun! illuminate#enable_illumination() abort
  let s:enabled = 1
  if s:should_illuminate_file()
    call s:illuminate()
  endif
endf
" }}}

" Abstracted functions {{{
fun! s:illuminate(...) abort
  if !s:enabled
    return
  endif

  call s:remove_illumination()

  let l:matched_word = s:get_cur_word()
  if l:matched_word !~ @/ || !&hls || !v:hlsearch
    if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &ft)
      if index(g:Illuminate_ftHighlightGroups[&ft], synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")) >= 0
        call s:match_word(l:matched_word)
      endif
    else
      call s:match_word(l:matched_word)
    endif
  endif
endf

fun! s:match_word(word) abort
  silent! call matchadd("illuminatedWord", '\V' . a:word, s:priority, s:match_id)
  let s:previous_match = a:word
endf

fun! s:get_cur_word() abort
  return '\<' . expand("<cword>") . '\>'
endf

fun! s:remove_illumination() abort
  if has('timers') && exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
    let s:timer_id = -1
  endif

  try
    call matchdelete(s:match_id)
  catch /E803/
  endtry
endf

fun! s:should_illuminate_file()
  if !exists('g:Illuminate_ftblacklist')
    let g:Illuminate_ftblacklist=['']
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
endf
" }}}

" vim: foldlevel=0 foldmethod=marker
