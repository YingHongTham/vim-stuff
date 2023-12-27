" meant to sit at ~/.config/nvim/ftplugin/julia.vim
" see also default /usr/local/share/nvim/runtime/ftplugin/julia.vim
" TODO: search for function might fail; attempt down search;
" display message if fail, don't yank anything

" yank current function into clipboard (register "+)
function YankJuliaFunction()
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
function YankJuliaBlock()
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

nmap <F6> :call YankJuliaFunction()<CR>
nmap <F7> :call YankJuliaBlock()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" modified from Slime Vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"let output = substitute(a:text, " ", "\\\\ ", "g")

function Send_Clipboard_to_Pane()
	if !exists("g:julia_pane")
		call Set_Julia_Pane_Prompt()
	end

	" create a buffer in tmux called x-clip and copy contents from clipboard
	call system("tmux set-buffer -b x-clip \"$(xclip -o -selection clipboard)\"")
	call system("tmux paste-buffer -b x-clip -t " . g:julia_pane)
	call system("tmux send-keys -t " . g:julia_pane . " 'Enter'")
endfunction

function Set_Julia_Pane_Prompt()
	if !exists("g:julia_pane")
		" suggested default value
		let g:julia_pane = "%1"
	end

	let g:julia_pane = input("tmux pane: ", g:julia_pane)
endfunction

"nmap <F9> :call Send_to_Pane(@+)<CR>
nmap <F9> :call Send_Clipboard_to_Pane()<CR>


" maybe try to pipe into some buffer then pipe to tmux? or just to bash?


"let wordUnderCursor = expand("<cword>")
