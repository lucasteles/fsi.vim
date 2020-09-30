if exists('g:loaded_autoload_fsi_vim')
    finish
endif
let g:loaded_autoload_fsi_vim = 1

let s:fsi_buffer = -1
let s:fsi_job    = -1
let s:fsi_width  = 0
let s:fsi_height = 0

function! s:win_gotoid_safe(winid)
    function! s:vimReturnFocus(window)
        call win_gotoid(a:window)
        redraw!
    endfunction
    if has('nvim')
        call win_gotoid(a:winid)
    else
        call timer_start(1, { -> s:vimReturnFocus(a:winid) })
    endif
endfunction

function! s:get_fsi_command()
    let cmd = g:fsi_command
    if exists('g:fsi_extra_parameters')
        for prm in g:fsi_extra_parameters
            let cmd = cmd . " " . prm
        endfor
    endif
    return cmd
endfunction

function! s:openFsi(returnFocus)
    if bufwinid(s:fsi_buffer) <= 0
        let fsi_command = s:get_fsi_command()
        " Neovim
        if exists('*termopen') || exists('*term_start')
            let current_win = win_getid()
            execute g:fsi_window_command
            if s:fsi_width  > 0 | execute 'vertical resize' s:fsi_width | endif
            if s:fsi_height > 0 | execute 'resize' s:fsi_height | endif
            " if window is closed but FSI is still alive then reuse it
            if s:fsi_buffer >= 0 && bufexists(str2nr(s:fsi_buffer))
                exec 'b' s:fsi_buffer
                normal G
                if !has('nvim') && mode() == 'n' | execute "normal A" | endif
                if a:returnFocus | call s:win_gotoid_safe(current_win) | endif
            " open FSI: Neovim
            elseif has('nvim')
                let s:fsi_job = termopen(fsi_command)
                if s:fsi_job > 0
                    let s:fsi_buffer = bufnr("%")
                else
                    close
                    echom "[FSAC] Failed to open FSI."
                    return -1
                endif
            " open FSI: Vim
            else
                let options = {
                \ "term_name": "F# Interactive",
                \ "curwin": 1,
                \ "term_finish": "close"
                \ }
                let s:fsi_buffer = term_start(fsi_command, options)
                if s:fsi_buffer != 0
                    if exists('*term_setkill') | call term_setkill(s:fsi_buffer, "term") | endif
                    let s:fsi_job = term_getjob(s:fsi_buffer)
                else
                    close
                    echom "[FSAC] Failed to open FSI."
                    return -1
                endif
            endif
            setlocal bufhidden=hide
            normal G
            if a:returnFocus | call s:win_gotoid_safe(current_win) | endif
            return s:fsi_buffer
        else
            echom "[FSAC] Your Vim does not support terminal".
            return 0
        endif
    endif
    return s:fsi_buffer
endfunction

function! ToggleFsi()
    let fsiWindowId = bufwinid(s:fsi_buffer)
    if fsiWindowId > 0
        let current_win = win_getid()
        call win_gotoid(fsiWindowId)
        let s:fsi_width = winwidth('%')
        let s:fsi_height = winheight('%')
        close
        call win_gotoid(current_win)
    else
        call s:openFsi(0)
    endif
endfunction

function! s:quitFsi()
    if s:fsi_buffer >= 0 && bufexists(str2nr(s:fsi_buffer))
        if has('nvim')
            let winid = bufwinid(s:fsi_buffer)
            if winid > 0 | execute "close " . winid | endif
            call jobstop(s:fsi_job)
        else
            call job_stop(s:fsi_job, "term")
        endif
        let s:fsi_buffer = -1
        let s:fsi_job = -1
    endif
endfunction

function! s:resetFsi()
    call s:quitFsi()
    return s:openFsi(1)
endfunction

function! s:sendFsi(text)
    if s:openFsi(!g:fsi_focus_on_send) > 0
        " Neovim
        if has('nvim')
            call chansend(s:fsi_job, a:text . ";;". "\n")
        " Vim 8
        else
            call term_sendkeys(s:fsi_buffer, a:text . ";;" . "\<cr>")
            call term_wait(s:fsi_buffer)
        endif
    endif
endfunction

" https://stackoverflow.com/a/6271254
function! s:get_visual_selection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return lines
endfunction

function! s:get_complete_buffer()
    return join(getline(1, '$'), "\n")
endfunction

function! SendSelectionToFsi() range
    let lines = s:get_visual_selection()
    exec 'normal' len(lines) . 'j'
    let text = join(lines, "\n")
    return s:sendFsi(text)
endfunction

function! SendLineToFsi()
    let text = getline('.')
    exec 'normal j'
    return s:sendFsi(text)
endfunction

function! s:sendAllToFsi()
    let text = s:get_complete_buffer()
    return s:sendFsi(text)
endfunction



if !exists('g:fsi_command')
    let g:fsi_command = "dotnet fsi"
endif
if !exists('g:fsi_keymap')
    let g:fsi_keymap = "vscode"
endif
if !exists('g:fsi_window_command')
    let g:fsi_window_command = "botright 10new"
endif
if !exists('g:fsi_focus_on_send')
    let g:fsi_focus_on_send = 0
endif


" enable syntax based folding
setl fdm=syntax

" comment settings
setl formatoptions=croql
setl commentstring=(*%s*)
setl comments=s0:*\ -,m0:*\ \ ,ex0:*),s1:(*,mb:*,ex:*),:\/\/\/,:\/\/

com! -buffer -nargs=1 FsiEval call s:sendFsi(<f-args>)
com! -buffer FsiEvalBuffer call s:sendAllToFsi()
com! -buffer FsiReset call s:resetFsi()
com! -buffer FsiShow call ToggleFsi()

let g:fsi_keymap_send   = "<M-cr>"
let g:fsi_keymap_toggle = "<M-@>"

if g:fsi_keymap != "none"
    execute "vnoremap <silent>" g:fsi_keymap_send ":call SendSelectionToFsi()<cr><esc>"
    execute "nnoremap <silent>" g:fsi_keymap_send ":call SendLineToFsi()<cr>"
    execute "nnoremap <silent>" g:fsi_keymap_toggle ":call ToggleFsi()<cr>"
    execute "tnoremap <silent>" g:fsi_keymap_toggle "<C-\\><C-n>:call ToggleFsi()<cr>"
endif



