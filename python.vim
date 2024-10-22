if exists("b:mypython_ftplugin")
  finish
endif
let b:mypython_ftplugin = 1

" basic stuff
set expandtab
" these seems to be overriden by /usr/local/share/nvim/runtime/ftplugin/python.vim
set shiftwidth=2
set tabstop=2
set softtabstop=2



"=============================================================
" functionalities for selection and copying text
"=============================================================

" still doesn't work, this is a copy of YankJuliaFunction()
" python vim default doesn't have matchit?
" yank current function into clipboard (register "+)
function YankPythonFunction()
	" save current cursor and screen position
	let save_cursor = getcurpos()
	let save_winview = winsaveview()

	" search for the latest function above cursor, then delete search record
	call search("function", "bc")
	call histdel("search", -1)

	" use % to move to end; default julia.vim already handles with matchit
	execute "norm 0V%"
	redraw
	sleep 50ms
	execute "norm \"+y"
	echom matchstr(@+, "[^\n\r]*")

	" return cursor and screen to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
endfunction

" yank current block into clipboard (register "+)
" blocks are delineated with markers #++#
function YankPythonBlock()
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
	redraw
	sleep 50ms
	call histdel("search", -1)
	execute "norm \"+y"

	" return cursor to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
endfunction

nmap <F6> :call YankPythonFunction()<CR>
nmap <F7> :call YankPythonBlock()<CR>

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
nmap <F9> :call Send_Clipboard_to_Pane()<CR>
nmap <leader><F9> :call Send_Enter_to_Pane()<CR>


" maybe try to pipe into some buffer then pipe to tmux? or just to bash?


"let wordUnderCursor = expand("<cword>")

