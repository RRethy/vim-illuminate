# vim-illuminate

Vim plugin for automatically highlighting other uses of the current word under the cursor

![gif](https://media.giphy.com/media/ZO7QtQWoBP2TZ9mkXq/giphy.gif)

## Rationale

All modern IDEs and editors will highlight the word under the cursor which is a great way to see other uses of the current variable without having to look for it.

## About

This plugin is a tool for illuminating the other uses of the current word under the cursor.

Illuminate will by default highlight all uses of the word under the cursor, but with a little bit of configuration it can easily only highlight what you want it to highlight based on the filetype and highlight-groups.

Illuminate will also do a few other niceties such as delaying the highlight for a user-defined amount of time based on `g:Illuminate_delay` (by default 250), it will interact nicely with search highlighting, jumping around between buffers, jumping around between windows, and won't illuminate while in insert mode (unless told to).

## Configuration

Illuminate will delay before highlighting, this is not lag, it is to avoid the jarring experience of things illuminating too fast. This can be controlled with `g:Illuminate_delay` (which is default to 250 milliseconds):

**Note**: Delay only works for Vim8 and Neovim.

```vim
" Time in milliseconds (default 250)
let g:Illuminate_delay = 250
```
Illuminate will by default highlight the word under the cursor to match the behaviour seen in Intellij and VSCode. However, to make it not highlight the word under the cursor, use the following:

```vim
" Don't highlight word under cursor (default: 1)
let g:Illuminate_highlightUnderCursor = 0
```

By default illuminate will highlight all words the cursor passes over, but for many languages, you will only want to highlight certain highlight-groups (you can determine the highlight-group of a symbol under your cursor with `:echo synIDattr(synID(line("."), col("."), 1), "name")`).

You can define which highlight groups you want the illuminating to apply to. This can be done with a dict mapping a filetype to a list of highlight-groups in your vimrc such as:
```vim
let g:Illuminate_ftHighlightGroups = {
      \ 'vim': ['vimVar', 'vimString', 'vimLineComment',
      \         'vimFuncName', 'vimFunction', 'vimUserFunc', 'vimFunc']
      \ }
```

A blacklist of highlight groups can also be setup by adding the suffix `:blacklist` to the filetype. However, if the whitelist for that filetype already exists, it will override the blacklist.
```vim
let g:Illuminate_ftHighlightGroups = {
      \ 'vim:blacklist': ['vimVar', 'vimString', 'vimLineComment',
      \         'vimFuncName', 'vimFunction', 'vimUserFunc', 'vimFunc']
      \ }
```

illuminate can also be disabled for various filetypes using the following:
```vim
let g:Illuminate_ftblacklist = ['nerdtree']
```

Or you can enable it only for certain filetypes with:
```vim
let g:Illuminate_ftwhitelist = ['vim', 'sh', 'python']
```

By default the highlighting will be done with the highlight-group `CursorLine` since that is in my opinion the nicest. It can however be overridden using the following (use standard Vim highlighting syntax):
Note: It must be in an autocmd to get around a weird Neovim behaviour.
```vim
augroup illuminate_augroup
    autocmd!
    autocmd VimEnter * hi link illuminatedWord CursorLine
augroup END

" or

augroup illuminate_augroup
    autocmd!
    autocmd VimEnter * hi illuminatedWord cterm=underline gui=underline
augroup END
```

Lastly, you can also specify a specific highlight for the word under the cursor so it differs from all other matches using the following higlight group:
```vim
augroup illuminate_augroup
    autocmd!
    autocmd VimEnter * hi illuminatedCurWord cterm=italic gui=italic
augroup END
```

## Installation

This assumes you have the packages feature. If not, any plugin manager will suffice.

### Neovim

```
mkdir -p ~/.config/nvim/pack/plugins/start
cd ~/.config/nvim/pack/plugins/start
git clone https://github.com/RRethy/vim-illuminate.git
```

### Vim

```
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/RRethy/vim-illuminate.git
```

## FAQs

> I am seeing by default an underline for the matched words

Try this: `hi link illuminatedWord Visual`. The reason for the underline is that the highlighting is done with `CursorLine` by default, which defaults to an underline.
