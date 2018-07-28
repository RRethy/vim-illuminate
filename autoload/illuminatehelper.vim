fun! illuminatehelper#should_illuminate_file()
  if !exists('g:Illuminate_ftblacklist')
    let g:Illuminate_ftblacklist=['']
  endif

  return index(g:Illuminate_ftblacklist, &filetype) < 0
endf
