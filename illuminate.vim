hi link illuminatedWord cursorline

if exists('g:loaded_illuminate')
  finish
endif
let g:loaded_illuminate = 1

if has("autocmd")
  augroup illuminated_autocmd
    autocmd!
    autocmd CursorMoved,WinLeave,BufLeave,InsertEnter * if s:Should_illuminate_file() | call s:MaybeRemove_illumination() | endif
    autocmd WinLeave,BufLeave,InsertEnter * if s:Should_illuminate_file() | call s:Remove_illumination() | endif
    autocmd CursorHold,InsertLeave * if s:Should_illuminate_file() | call s:Illuminate() | endif
  augroup END
endif

command RemoveIllumination call s:Remove_illumination()

let s:match_ids = -1
let s:previous_match = ''

fun! s:Illuminate() abort
  call s:Remove_illumination()

  let l:matched_word = s:Cur_word()
  if l:matched_word !~ @/ || !&hls || !v:hlsearch
    if exists('g:Illuminate_ftHighlightGroups') && has_key(g:Illuminate_ftHighlightGroups, &ft)
      if index(g:Illuminate_ftHighlightGroups[&ft], synIDattr(synID(line('.'), col('.'), 1), "name")) >= 0
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

" TODO: This could be in autoload
fun! s:Should_illuminate_file()
  if !exists('g:Illuminate_ftblacklist')
    let g:Illuminate_ftblacklist=['']
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
endf
