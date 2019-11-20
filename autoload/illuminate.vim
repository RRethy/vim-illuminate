" illuminate.vim - Vim plugin for selectively illuminating other uses of current word
" Maintainer:	Adam P. Regasz-Rethy (RRethy) <rethy.spud@gmail.com>
" Version: 0.4

let s:priority = -1
let s:previous_match = ''
let s:enabled = 1

let g:Illuminate_delay = get(g:, 'Illuminate_delay', 250)
let g:Illuminate_highlightUnderCursor = get(g:, 'Illuminate_highlightUnderCursor', 1)

fun! illuminate#on_cursor_moved() abort
  if !s:should_illuminate_file()
    return
  endif

  if (s:previous_match !=# s:get_cur_word())
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

fun! s:illuminate(...) abort
  if !s:enabled
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
    let w:match_id = matchadd('illuminatedWord', '\V' . a:word, s:priority)
  else
    let w:match_id = matchadd('illuminatedWord', '\V\(\k\*\%#\k\*\)\@\!\&' . a:word, s:priority)
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

  let s:previous_match = ''
endf

fun! s:should_illuminate_file() abort
  if !exists('g:Illuminate_ftblacklist')
    " Blacklist empty filetype by default
    let g:Illuminate_ftblacklist=['']
  endif
  if !exists('g:Illuminate_ftwhitelist')
    let g:Illuminate_ftwhitelist=[]
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
        \ && (empty(g:Illuminate_ftwhitelist) || index(g:Illuminate_ftwhitelist, &filetype) >= 0)
endf

fun! s:should_illuminate_word() abort
  let ft_hl_groups = get(g:, 'Illuminate_ftHighlightGroups', {})
  let hl_groups_whitelist = get(ft_hl_groups, &filetype, [])
  if empty(hl_groups_whitelist)
    let hl_groups_blacklist = get(ft_hl_groups, &filetype.':blacklist', [])
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

" vim: foldlevel=1 foldmethod=marker
