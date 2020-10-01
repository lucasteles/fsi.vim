# fsi.vim

**FSI integration for  Vim/Neovim**

[![fsi.vim](https://asciinema.org/a/362740.svg)](https://asciinema.org/a/362740)

_Scripts from [Ionide-vim](https://github.com/ionide/Ionide-vim/blob/master/README.mkd) without LSP features._

## About fsi.vim

* Simple integration with F# Interactive


## Requirements

* Neovim or Vim 8.0+

* [.NET Core SDK](https://dotnet.microsoft.com/download)
  - Required to run FsAutoComplete.
  - Very useful for command-line development.

## Getting Started

#### Installing with your plugin manager

##### [vim-plug](https://github.com/lucasteles/fsi.vim)

~~~.vim
Plug 'lucasteles/fsi.vim'
~~~


## Usage

FSI is displayed using the builtin `:terminal` feature introduced in Vim 8 / Neovim and can be used like in VSCode.

#### `:FsiShow`
  - Shows a F# Interactive window.

#### `:FsiEval <expr>`
  - Evaluates given expression in FSI.

#### `:FsiEvalBuffer`
  - Sends the content of current file to FSI.

#### `:FsiReset`
  - Resets the current FSI session.

#### `Alt-Enter`
  - When in normal mode, sends the current line to FSI.
  - When in visual mode, sends the selection to FSI.
  - Sending code to FSI opens FSI window but the cursor does not focus to it. Unlike Neovim, Vim doesn't support asynchronous buffer updating so you have to input something (e.g. moving cursor) to see the result. You can change this behavior in settings.

#### `Alt-@`
  - Toggles FSI window. FSI windows shown in different tabpages share the same FSI session.
  - When opened, the cursor automatically focuses to the FSI window (unlike in `Alt-Enter` by default).

#### Customize

##### Set additional runtime arguments passed to FSI (default: `[]` (empty))

Sets additional arguments of the FSI instance Ionide-vim spawns and changes the behavior of FSAC accordingly when editing fsx files.

~~~.vim
let g:fsharp#fsi_extra_parameters = ['--langversion:preview']
~~~

##### Customize how FSI window is opened (default: `botright 10new`)

It must create a new empty window and then focus to it.

See [`:help opening-window`](http://vimdoc.sourceforge.net/htmldoc/windows.html#opening-window) for details.

~~~.vim
let g:fsharp#fsi_window_command = "botright vnew"
~~~

##### Set if sending line/selection to FSI shoule make the cursor focus to FSI window (default: disabled)

If you are using Vim, you might want to enable this to see the result without inputting something.

~~~.vim
let g:fsharp#fsi_focus_on_send = 1 " 0 to not to focus.
~~~

##### Change the key mappings 

~~~.vim
" custom mapping example
let g:fsharp#fsi_keymap_send   = "<C-e>"
let g:fsharp#fsi_keymap_toggle = "<C-@>"
~~~

