# Overview

Vim plugin for automatically highlighting other uses of the word under the cursor using either LSP, Tree-sitter, or regex matching.

![gif](https://media.giphy.com/media/mSG0nwAHDt3Fl7WyoL/giphy.gif)

# Quickstart

Just install the plugin and things will work *just work*, no configuration needed.

You'll also get `<a-n>` and `<a-p>` as keymaps to move between references and `<a-i>` as a textobject for the reference illuminated under the cursor.

# Configuration

```lua
-- default configuration
require('illuminate').configure({
    -- providers: provider used to get references in the buffer, ordered by priority
    providers = {
        'lsp',
        'treesitter',
        'regex',
    },
    -- delay: delay in milliseconds
    delay = 100,
    -- filetype_overrides: filetype specific overrides.
    -- The keys are strings to represent the filetype while the values are tables that
    -- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
    filetype_overrides = {},
    -- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
    filetypes_denylist = {
        'dirbuf',
        'dirvish',
        'fugitive',
    },
    -- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
    -- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
    filetypes_allowlist = {},
    -- modes_denylist: modes to not illuminate, this overrides modes_allowlist
    -- See `:help mode()` for possible values
    modes_denylist = {},
    -- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
    -- See `:help mode()` for possible values
    modes_allowlist = {},
    -- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
    -- Only applies to the 'regex' provider
    -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
    providers_regex_syntax_denylist = {},
    -- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
    -- Only applies to the 'regex' provider
    -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
    providers_regex_syntax_allowlist = {},
    -- under_cursor: whether or not to illuminate under the cursor
    under_cursor = true,
    -- large_file_cutoff: number of lines at which to use large_file_config
    -- The `under_cursor` option is disabled when this cutoff is hit
    large_file_cutoff = nil,
    -- large_file_config: config to use for large files (based on large_file_cutoff).
    -- Supports the same keys passed to .configure
    -- If nil, vim-illuminate will be disabled for large files.
    large_file_overrides = nil,
    -- min_count_to_highlight: minimum number of matches required to perform highlighting
    min_count_to_highlight = 1,
    -- should_enable: a callback that overrides all other settings to
    -- enable/disable illumination. This will be called a lot so don't do
    -- anything expensive in it.
    should_enable = function(bufnr) return true end,
    -- case_insensitive_regex: sets regex case sensitivity
    case_insensitive_regex = false,
})
```

# Highlight Groups

#### IlluminatedWordText

Default highlight group used for references if no kind information is available.

```vim
hi def IlluminatedWordText gui=underline
```

#### IlluminatedWordRead

Highlight group used for references of kind read.

```vim
hi def IlluminatedWordRead gui=underline
```

#### IlluminatedWordWrite

Highlight group used for references of kind write.

```vim
hi def IlluminatedWordWrite gui=underline
```

# Commands

#### :IlluminatePause

Globally pause vim-illuminate.

#### :IlluminateResume

Globally resume vim-illuminate.

#### :IlluminateToggle

Globally toggle the pause/resume for vim-illuminate.

#### :IlluminatePauseBuf

Buffer-local pause of vim-illuminate.

#### :IlluminateResumeBuf

Buffer-local resume of vim-illuminate.

#### :IlluminateToggleBuf

Buffer-local toggle of the pause/resume for vim-illuminate.

# Functions

#### require('illuminate').configure(config)

Override the default configuration with `config`

#### require('illuminate').pause()

Globally pause vim-illuminate.

#### require('illuminate').resume()

Globally resume vim-illuminate.

#### require('illuminate').toggle()

Globally toggle the pause/resume for vim-illuminate.

#### require('illuminate').toggle_buf()

Buffer-local toggle of the pause/resume for vim-illuminate.

#### require('illuminate').pause_buf()

Buffer-local pause of vim-illuminate.

#### require('illuminate').resume_buf()

Buffer-local resume of vim-illuminate.

#### require('illuminate').freeze_buf()

Freeze the illumination on the buffer, this won't clear the highlights.

#### require('illuminate').unfreeze_buf()

Unfreeze the illumination on the buffer.

#### require('illuminate').toggle_freeze_buf()

Toggle the frozen state of the buffer.

#### require('illuminate').invisible_buf()

Turn off the highlighting for the buffer, this won't stop the engine from running so you can still use `<c-n>` and `<c-p>`.

#### require('illuminate').visible_buf()

Turn on the highlighting for the buffer, this is only needed if you've previous called `require('illuminate').invisible_buf()`.

#### require('illuminate').toggle_visibility_buf()

Toggle the visibility of highlights in the buffer.

#### require('illuminate').goto_next_reference(wrap)

Move the cursor to the closest references after the cursor which it is not currently on. Wraps the buffer if on the last reference.

Wraps the references unless `wrap` is false (defaults to **'wrapscan'**).

#### require('illuminate').goto_prev_reference(wrap)

Move the cursor to the closest references before the cursor which it is not currently on. Wraps the buffer if on the first reference.

Wraps the references unless `wrap` is false (defaults to **'wrapscan'**).

#### require('illuminate').textobj_select()

Selects the reference the cursor is currently on for use as a text-object.

# Vim Users

**Note:** This section is deprecated for Neovim users, Neovim users can use the newer version of the plugin. Neovim users can force this old version of the plugin by adding `let g:Illuminate_useDeprecated = 1` to their `init.vim`.

Illuminate will delay before highlighting, this is not lag, it is to avoid the jarring experience of things illuminating too fast. This can be controlled with `g:Illuminate_delay` (which is default to 0 milliseconds):

**Note**: Delay only works for Vim8 and Neovim.

```vim
" Time in milliseconds (default 0)
let g:Illuminate_delay = 0
```
Illuminate will by default highlight the word under the cursor to match the behaviour seen in Intellij and VSCode. However, to make it not highlight the word under the cursor, use the following:

```vim
" Don't highlight word under cursor (default: 1)
let g:Illuminate_highlightUnderCursor = 0
```

By default illuminate will highlight all words the cursor passes over, but for many languages, you will only want to highlight certain highlight-groups.
You can determine the highlight-group of a symbol under your cursor with `:echo synIDattr(synID(line("."), col("."), 1), "name")`.

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
