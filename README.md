# vim-illuminate

Vim plugin for selectively illuminating other uses of current word

## Rational

All modern IDEs and editors will highlight the word under the cursor which is a great way to see other uses of the current variable without having to look for it and possible miss it. As well, this highlighting should only be done for various types, such as Class names, variables, functions, etc. Instead of trying to define which syntax items it will highlight for each language, I left it customizable for the user to choose what they want highlighted.

## About

This plugin is a tool for illuminating the other uses of the current word
under the cursor.

illuminate will by default highlight all uses of the word under the cursor,
but will a little bit of configuration it can easily only highlight what you want
it to highlight based on the file type and highlight-groups.

illuminate will also do a few other nice such as delaying the highlight for
'updatetime', it will interact nicely with search highlighting, jumping
around between buffers, jumping around between windows, and turning off
highlighting while in insert mode.

## Configuration

By default |illuminate| will highlight all words the cursor passes over, but
for many languages, you will only want to highlight certain
highlight-groups. You can define which highlight groups you want the
illuminating to apply to. This can be done with a dict mapping a |filetype| to
a list of highlight-groups in your vimrc.
```
For example:

let g:Illuminate_ftHighlightGroups = {
  \ 'vim': ['vimVar', 'vimFBVar', 'vimString', 'vimLineComment',
  \         'vimFuncName', 'vimFunction', 'vimUserFunc', 'vimFunc']
  \ }
```


illuminate can also be disabled for various |filetypes|.
```
For Example:

let g:Illuminate_ftblacklist = ['nerdtree']
```

Lastly, by default the highlighting will be done with the hl-group cursorline
since that is in my opinion the nicest. But it can be overriden using the
following:
```
hi link illuminatedWord cursorline
```
