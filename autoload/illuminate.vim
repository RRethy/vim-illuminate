" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.4

" Some local variables {{{
let s:match_id = 1867
let s:priority = -1
let s:previous_match = ''
let s:enabled = 1
" }}}

" Global variables init {{{
let g:Illuminate_delay = get(g:, 'Illuminate_delay', 250)
let g:Illuminate_highlightUnderCursor = get(g:, 'Illuminate_highlightUnderCursor', 1)
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

  " Any delay at or below 17 milliseconds gets counted as no delay
  if !has('timers') || g:Illuminate_delay <= 17
    call s:illuminate()
    return
  endif

  if exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
  endif

  let s:timer_id = timer_start(g:Illuminate_delay, function('s:illuminate'))
endf

fun! illuminate#on_leaving_autocmds() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#on_insert_entered() abort
  if s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#toggle_illumination() abort
  if !s:enabled
    call illuminate#enable_illumination()
  else
    call illuminate#disable_illumination()
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

  if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &filetype)
    if index(g:Illuminate_ftHighlightGroups[&filetype], synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')) >= 0
      call s:match_word(s:get_cur_word())
    endif
  else
    call s:match_word(s:get_cur_word())
  endif
  let s:previous_match = s:get_cur_word()
endf

fun! s:match_word(word) abort
  if (a:word ==# '\<\>')
    return
  endif
  if g:Illuminate_highlightUnderCursor
    silent! call matchadd('illuminatedWord', '\V' . a:word, s:priority, s:match_id)
  else
    silent! call matchadd('illuminatedWord', '\V\(\k\*\%#\k\*\)\@\!\&' . a:word, s:priority, s:match_id)
  endif
endf

fun! s:get_cur_word() abort
  let line = getline('.')
  let col = col('.') - 1
  if v:version < 800
    let word = expand('<cword>')
  else
    let word = matchstr(line[:col], '\k*$') . matchstr(line[col:], '^\k*')[1:]
  endif
  return '\<' . escape(word, '/\?') . '\>'
endf

fun! s:remove_illumination() abort
  if has('timers') && exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
    let s:timer_id = -1
  endif

  try
    call matchdelete(s:match_id)
  catch /\v(E803|E802)/
  endtry

  let s:previous_match = ''
endf

fun! s:should_illuminate_file() abort
  if !exists('g:Illuminate_ftblacklist')
    let g:Illuminate_ftblacklist=['']
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
endf
" }}}

" vim: foldlevel=1 foldmethod=marker
