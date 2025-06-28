if exists("b:mypython_ftplugin")
  finish
endif
let b:mypython_ftplugin = 1

" basic stuff
set expandtab
" these used to be overriden by /usr/local/share/nvim/runtime/ftplugin/python.vim
" but now for neovim, put in after/ftplugin/, loads afterwards
set shiftwidth=4
set tabstop=4
set softtabstop=4

"=============================================================
" functionalities for selection and copying text
"=============================================================

" yank current function into clipboard (register "+)
" the movements with square brackets provided by
" $VIMRUNTIME/ftplugin/python.vim
" see https://vi.stackexchange.com/questions/7262/end-of-python-block-motion
function YankPythonFunction(comment_blanklines)
	" save current cursor and screen position
	let save_cursor = getcurpos()
	let save_winview = winsaveview()

	execute "norm 0"
	if expand("<cword>") == 'def'
		execute "norm V]M"
	else
		execute "norm [[V]Mj"
	end
	redraw
	sleep 50ms
	execute "norm \"+y"
	" show function name
	echom matchstr(@+, "[^\n\r]*")

	" sanitize the function, ie replace blanklines with #
	if a:comment_blanklines == 1
		let @+ = BlankLinesIntoComments(@+)
	end
	"if a:comment_blanklines == 1
	"	let @+ = substitute(@+, '\n\n', '\n\#\n', 'g')
	"	let @+ = substitute(@+, '\n\#\n$', '\n\n', '')
	"end

	" return cursor and screen to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
endfunction

" yank current block into clipboard (register "+)
" blocks are delineated with markers #++#
function YankPythonBlock(comment_blanklines)
	" save current cursor position
	let save_cursor = getcurpos()
	let save_winview = winsaveview()

	if search("#++#", "cbW") == 0
		" failed to find marker, go to top of file
		execute "norm gg"
	end
	call histdel("search", -1)
	execute "norm 0Vj"
	if search("#++#", "W") == 0
		" failed to find marker, go to bottom of file
		execute "norm G"
	end
	call histdel("search", -1)
	redraw
	sleep 50ms
	execute "norm \"+y"

	" sanitize the code block, ie replace blanklines with #
	if a:comment_blanklines == 1
		let @+ = BlankLinesIntoComments(@+)
	end

	" return cursor to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
endfunction

function! BlankLinesIntoComments(str)
	return substitute(a:str, '\n\n\(\s\)', '\n\#\n\1', 'g')
endfunction

nmap <F6> :call YankPythonFunction(1)<CR>
nmap <S-F6> :call YankPythonFunction(0)<CR>
nmap <F7> :call YankPythonBlock(1)<CR>
nmap <S-F7> :call YankPythonBlock(0)<CR>

"=============================================================
" functionalities for sending text to REPL pane
"=============================================================

function Set_Python_Pane_Prompt()
	if !exists("g:python_pane")
		" suggested default value
		let g:python_pane = "1"
	end

	let g:python_pane = input("tmux pane: ", g:python_pane)
endfunction


function Send_Clipboard_to_Pane()
	if !exists("g:python_pane")
		call Set_Python_Pane_Prompt()
	end

	" create a buffer in tmux called x-clip and copy contents from clipboard
	let xclipstr = "xclip -o -selection clipboard"
	" add # to empty lines
	let xclipstr .= " | sed \"s/^$/#/\""
	" turn #\n#\n...#\n[non-space] into \n[non-space], closes a scope
	let xclipstr .= " | perl -0pe \"s/(#\\n)+([^#\\s])/\\n\\2/g\""
	" if there are no other statements after the last scope,
	" we add a newline so that the REPL will close
	" (need the # after newline otherwise REPL ignores trailing newlines...?)
	" (also don't want to add this new line if last statement is not in a scope,
	" so check for leading whitespace character, \h)
	let xclipstr .= " | perl -0pe \"s/\\n(\\h)(.*)\\n(#\\n)*$/\\n\\1\\2\\n\\n#\\n/\""
	call system("tmux set-buffer -b x-clip \"$(" . xclipstr . ")\"")
	call system("tmux paste-buffer -b x-clip -t " . g:python_pane)
	call system("tmux send-keys -t " . g:python_pane . " 'Enter'")
endfunction

" send Enter keypress; needed if last thing had a scope
function Send_Enter_to_Pane()
	if !exists("g:python_pane")
		call Set_Python_Pane_Prompt()
	end
	call system("tmux send-keys -t " . g:python_pane . " 'Enter'")
endfunction

"nmap <F9> :call Send_to_Pane(@+)<CR>
"nmap <F9> :call Send_Clipboard_to_Pane()<CR>
"nmap <leader><F9> :call Send_Enter_to_Pane()<CR>

" maybe try to pipe into some buffer then pipe to tmux? or just to bash?


"=============================================================
" functionalities for sending text to terminal REPL buffer
"=============================================================

nmap <F9> :call PasteIntoREPL() <cr>
vmap <F9> "+y :call PasteIntoREPL() <cr>
nnoremap <F10> :call PasteEnterIntoREPL() <cr>
nnoremap <S-F10> :call GoToREPLEOF() <cr>
inoremap <C-J> <ESC>:call ActivateEnterPasteIntoREPLModel() <cr>a
inoremap <C-K> <ESC>:call DeactivateEnterPasteIntoREPLModel() <cr>a
nmap <S-F9> :call CreateREPLWindow() <cr>

function! CreateREPLWindow()
	let l:cur_win_id = win_getid()
	:set splitright
	:vsplit<cr>
	" already in new window
	let l:new_win_id = win_getid()
	execute "terminal"
	call win_gotoid(l:cur_win_id)
	let g:python_window = l:new_win_id
	call SetPythonREPLWindow(g:python_window)
	call PasteIntoREPL("python")
	call GoToREPLEOF()
endfunction

" sometimes want to do more experimental probing, but don't want to
" go back and copy the last few instructions back to the file for records
" sends the current line to the REPL and then goes to newline
function! ActivateEnterPasteIntoREPLModel()
	inoremap <CR> <ESC>V"+y:call PasteIntoREPL() <cr>A<cr>
endfunction
	
function! DeactivateEnterPasteIntoREPLModel()
	iunmap <CR>
endfunction
	

" a bit buggy, weird changing cursor position in target buffer
" but for current application to paste in python REPL should be ok
function! PasteIntoREPLFn(win_id, ...)
	let l:cur_win_id = win_getid()
	let l:contents = getreg("+")
	if a:0 > 0
		let l:contents = a:1
	end
	let l:tmp_register = getreg("z")
	let l:len = len(l:contents)
	echom "l:contents length: " . l:len
	if l:contents[l:len-1] == "\r"
		let @z=l:contents
	elseif l:contents[l:len-1] == "\n"
		let @z = substitute(l:contents, '\n$', '\r', '')	
		"let @z=l:contents[: l:len-2] . "\r"
	else
		let @z=l:contents . "\r"
	end
	call win_gotoid(a:win_id)
	execute "normal! \"zp"
	call win_gotoid(l:cur_win_id)
	let @z=l:tmp_register
endfunction

function! PasteEnterIntoREPLFn(win_id)
	let l:cur_win_id = win_getid()
	let l:tmp_register = getreg("z")
	let @z="\r"
	call win_gotoid(a:win_id)
	execute "normal! \"zp"
	call win_gotoid(l:cur_win_id)
	let @z=l:tmp_register
endfunction

function! GoToREPLEOFFn(win_id)
	let l:cur_win_id = win_getid()
	call win_gotoid(a:win_id)
	execute "normal! G"
	call win_gotoid(l:cur_win_id)
endfunction

" a:0 is num args, a:1,...,a:n the args;
" also can do get(a:, k, dflt_val) to get a:k if provided
function! SetPythonREPLWindow(...)
	if a:0 > 0
		let g:python_window = a:1
		return
	end
	let l:python_window_tmp = input("python window: ", "")
	if l:python_window_tmp == ""
		return
	end
	" maintains original g:python_window if nothing passed
	let g:python_window = l:python_window_tmp
endfunction

" send Enter keypress; needed if last thing had a scope
function! PasteIntoREPL(...)
	if !exists("g:python_window")
		call SetPythonREPLWindow()
	end
	if a:0 > 0
		call PasteIntoREPLFn(g:python_window, a:1)
		return
	end
	call PasteIntoREPLFn(g:python_window)
endfunction

function! PasteEnterIntoREPL()
	if !exists("g:python_window")
		call SetPythonREPLWindow()
	end
	call PasteEnterIntoREPLFn(g:python_window)
endfunction

function! GoToREPLEOF()
	if !exists("g:python_window")
		call SetPythonREPLWindow()
	end
	call GoToREPLEOFFn(g:python_window)
endfunction

"" redo properly with window number
"function! PasteEnterIntoREPLFn(buf_num)
"	let l:cur_buf = bufnr('%')
"	execute ":buffer " . a:buf_num
"	echom getcurpos()
"	execute "normal! G"
"	let l:tmp_register = getreg("z")
"	let @z="\n\n"
"	execute "normal! \"zp"
"	let @z=l:tmp_register
"	execute ":buffer " . l:cur_buf
"endfunction

"" a:0 is num args, a:1,...,a:n the args;
"" also can do get(a:, k, dflt_val) to get a:k if provided
"function! Set_Python_Buffer_Prompt(...)
"	echo a:0
"	if a:0 > 0
"		let g:python_buffer = a:1
"		return
"	end
"
"	let l:python_buffer_tmp = input("python buffer: ", "")
"	if l:python_buffer_tmp != ""
"		let g:python_buffer = l:python_buffer_tmp
"	end
"endfunction

"" send Enter keypress; needed if last thing had a scope
"function! PasteIntoREPL()
"	if !exists("g:python_buffer")
"		call Set_Python_Buffer_Prompt()
"	end
"	call PasteIntoREPLFn(g:python_buffer)
"endfunction

"" buggy, sends as many copies as there are lines in yanked
"function! PasteIntoREPLVMode()
"	execute "normal! gv\"+y"
"	call PasteIntoREPL()
"endfunction

"function! PasteEnterIntoREPL()
"	if !exists("g:python_buffer")
"		call Set_Python_Buffer_Prompt()
"	end
"	call PasteEnterIntoREPLFn(g:python_buffer)
"endfunction
