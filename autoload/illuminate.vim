" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.4

let s:previous_match = ''
let s:enabled = 1

let g:Illuminate_delay = get(g:, 'Illuminate_delay', 0)
let g:Illuminate_highlightUnderCursor = get(g:, 'Illuminate_highlightUnderCursor', 1)
let g:Illuminate_highlightPriority = get(g:, 'Illuminate_highlightPriority', -1)

fun! illuminate#on_cursor_moved() abort
  if !s:should_illuminate_file()
    return
  endif

  if s:previous_match !=# s:get_cur_word()
    call s:remove_illumination()
  elseif get(g:, 'Illuminate_highlightUnderCursor', 1) == 0 || hlexists('illuminatedCurWord')
    call s:remove_illumination()
    call s:illuminate()
    return
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

fun! illuminate#on_cursor_moved_i() abort
  if get(g:, 'Illuminate_insert_mode_highlight', 0)
    call illuminate#on_cursor_moved()
  endif
endf

fun! illuminate#on_insert_entered() abort
  if !get(g:, 'Illuminate_insert_mode_highlight', 0) && s:should_illuminate_file()
    call s:remove_illumination()
  endif
endf

fun! illuminate#toggle_illumination(bufonly) abort
  if a:bufonly
    let b:illuminate_enabled = get(b:, 'illuminate_enabled', s:enabled)
    if !b:illuminate_enabled
      call illuminate#enable_illumination(1)
    else
      call illuminate#disable_illumination(1)
    endif
  else
    if !s:enabled
      call illuminate#enable_illumination(0)
    else
      call illuminate#disable_illumination(0)
    endif
  endif
endf

fun! illuminate#disable_illumination(bufonly) abort
  if a:bufonly
    let b:illuminate_enabled = 0
  else
    let s:enabled = 0
  endif
  call s:remove_illumination()
endf

fun! illuminate#enable_illumination(bufonly) abort
  if a:bufonly
    let b:illuminate_enabled = 1
  else
    let s:enabled = 1
  endif
  if s:should_illuminate_file()
    call s:illuminate()
  endif
endf

fun! s:illuminate(...) abort
  if !get(b:, 'illuminate_enabled', s:enabled)
    return
  endif

  call s:remove_illumination()

  if s:should_illuminate_word()
    call s:match_word(s:get_cur_word())
  endif
  let s:previous_match = s:get_cur_word()
endf

fun! s:match_word(word) abort
  if (a:word ==# '\<\>')
    return
  endif
  if g:Illuminate_highlightUnderCursor
    if hlexists('illuminatedCurWord')
      let w:match_id = matchadd('illuminatedWord', '\V\(\k\*\%#\k\*\)\@\!\&' . a:word, g:Illuminate_highlightPriority)
      let w:match_curword_id = matchadd('illuminatedCurWord', '\V\(\k\*\%#\k\*\)\&' . a:word, g:Illuminate_highlightPriority)
    else
      let w:match_id = matchadd('illuminatedWord', '\V' . a:word, g:Illuminate_highlightPriority)
    endif
  else
    let w:match_id = matchadd('illuminatedWord', '\V\(\k\*\%#\k\*\)\@\!\&' . a:word, g:Illuminate_highlightPriority)
  endif
endf

fun! s:get_cur_word() abort
  let line = getline('.')
  let col = col('.') - 1
  let left_part = strpart(line, 0, col + 1)
  let right_part = strpart(line, col, col('$'))
  let word = matchstr(left_part, '\k*$') . matchstr(right_part, '^\k*')[1:]

  return '\<' . escape(word, '/\') . '\>'
endf

fun! s:remove_illumination() abort
  if has('timers') && exists('s:timer_id') && s:timer_id > -1
    call timer_stop(s:timer_id)
    let s:timer_id = -1
  endif

  if exists('w:match_id')
    try
      call matchdelete(w:match_id)
    catch /\v(E803|E802)/
    endtry
  endif

  if exists('w:match_curword_id')
    try
      call matchdelete(w:match_curword_id)
    catch /\v(E803|E802)/
    endtry
  endif

  let s:previous_match = ''
endf

fun! s:should_illuminate_file() abort
  let g:Illuminate_ftblacklist = get(g:, 'Illuminate_ftblacklist', [])
  let g:Illuminate_ftwhitelist = get(g:, 'Illuminate_ftwhitelist', [])

  return !s:list_contains_pat(g:Illuminate_ftblacklist, &filetype)
        \ && (empty(g:Illuminate_ftwhitelist) || s:list_contains_pat(g:Illuminate_ftwhitelist, &filetype))
endf

fun! s:should_illuminate_word() abort
  let ft_hl_groups = get(g:, 'Illuminate_ftHighlightGroups', {})
  let hl_groups_whitelist = get(ft_hl_groups, &filetype, [])
  call extend(hl_groups_whitelist, get(ft_hl_groups, '*', []))
  if empty(hl_groups_whitelist)
    let hl_groups_blacklist = get(ft_hl_groups, &filetype.':blacklist', [])
    call extend(hl_groups_blacklist, get(ft_hl_groups, '*:blacklist', []))
    if empty(hl_groups_blacklist)
      return 1
    else
      return index(hl_groups_blacklist, synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')) < 0
            \ && index(hl_groups_blacklist, synIDattr(synID(line('.'), col('.'), 1), 'name')) < 0
    endif
  endif

  return index(ft_hl_groups[&filetype], synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')) >= 0
        \ || index(ft_hl_groups[&filetype], synIDattr(synID(line('.'), col('.'), 1), 'name')) >= 0
endf

fun! s:dict_has_key_pat(d, key) abort
  for [k, v] in items(a:d)
    if key =~# '^'.k.'$'
      return 1
    endif
  endfor
  return 0
endfun

fun! s:list_contains_pat(list, val) abort
  for pat in a:list
    if a:val =~# '^'.pat.'$'
      return 1
    endif
  endfor
  return 0
endfun

" vim: foldlevel=1 foldmethod=expr tabstop=2 softtabstop=2 shiftwidth=2
