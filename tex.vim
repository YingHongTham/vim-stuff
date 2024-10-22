" soft-linked from ~/.config/nvim/ftplugin/tex.vim
" see also default /usr/local/share/nvim/runtime/ftplugin/tex.vim 

if exists("b:mytex_ftplugin")
  finish
endif
let b:mytex_ftplugin = 1

"nmap <F3> :!pdflatex main.tex<CR>
nmap <F4> :!pdflatex -synctex=1 %<CR>

"===========================================================
" compiling only section of tex file
" creates a tmp file in /run/user/<user-id>
" in folder called mylatextmp
" and filename currently hardcoded...
" don't see any reason for now to make a new tmp file for each session..
" maybe delete the tmpfile when close vim? hmmm
" anyway when that time comes, use mktmp
"
" TODO save the YankPreDocument content to a different tmp file,
" then combine with the other part

function YankPreDocument()
	let save_cursor = getcurpos()
	let save_winview = winsaveview()

	execute "norm ggV"
	if search("\\\\begin{document}", "c") == 0
		execute "norm <Esc>"
		return 1
	end
	call histdel("search", -1)
	execute "norm \"+y"

	" return cursor to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
	return 0
endfunction

" assumes YankPreDocument succeeded
function YankTexSection()
	let save_cursor = getcurpos()
	let save_winview = winsaveview()

	if search("%++%", "cbW") == 0
		call histdel("search", -1)
		call search("\\\\begin{document}", "cbW")
	end
	call histdel("search", -1)
	execute "norm 0Vj"
	if search("%++%", "cW") == 0
		call histdel("search", -1)
		call search("\\\\end{document}", "cW")
		execute "norm k"
	end
	redraw
	sleep 50ms
	call histdel("search", -1)
	execute "norm \"+y"

	" return cursor to start position
	call setpos('.', save_cursor)
	call winrestview(save_winview)
endfunction

function SetTmpTexFile()
	let g:tmp_tex_snippet_dir = "/run/user/" . system("echo -n $(id -u)")
	let g:tmp_tex_snippet_dir = g:tmp_tex_snippet_dir . "/mylatextmp"
	if system("if [ -d \"" . g:tmp_tex_snippet_dir . "\" ]; then echo 0; else echo 1; fi") == 1
		call system("mkdir " . g:tmp_tex_snippet_dir)
	end
	let g:tmp_tex_snippet_pdf = g:tmp_tex_snippet_dir . "/tmp_tex_snippet.pdf"
	let g:tmp_tex_snippet = g:tmp_tex_snippet_dir . "/tmp_tex_snippet.tex"
endfunction

function SendTextToTmpTexFile()
	if !exists("g:tmp_tex_snippet")
		call SetTmpTexFile()
	end

	if YankPreDocument() == 1
		return 1
	end
	call system("xclip -o -selection \"clipboard\" > " . g:tmp_tex_snippet)
	call YankTexSection()
	call system("xclip -o -selection \"clipboard\" >> " . g:tmp_tex_snippet)
	let @+ = "\\end{document}"
	call system("xclip -o -selection \"clipboard\" >> " . g:tmp_tex_snippet)
	return 0
endfunction

function CompileSnippet()
	call system("pdflatex -output-directory " . g:tmp_tex_snippet_dir . " " . g:tmp_tex_snippet)
endfunction

function SendCompileSnippet()
	if SendTextToTmpTexFile() == 1
		return 1
	end
	call CompileSnippet()
endfunction

function OpenTmpPDFViewer()
	call system("evince " . g:tmp_tex_snippet_pdf . " &")
endfunction

nmap <F7> :call SendCompileSnippet()<CR>
nmap <F9> :call OpenTmpPDFViewer()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vimura
" uses SyncTex to send navigation between vim and zathura..
" https://gist.github.com/vext01/16df5bd48019d451e078

function SetPDFFilePrompt()
	if !exists("g:syncPDFfile")
		" suggested default value
		let g:syncPDFfile = expand('%:r') . ".pdf"
	end

	let g:syncPDFfile = input("PDF File: ", g:syncPDFfile)
endfunction

" default is current filename.tex -> filename.pdf
function OpenZathura()
	if !exists("g:syncPDFfile")
		call SetPDFFilePrompt()
	end
	echo "\~/Documnets/coding-stuff/vim-stuff/vimura.sh " . g:syncPDFfile
	call system("\~/Documnets/coding-stuff/vim-stuff/vimura.sh " . g:syncPDFfile)
endfunction

function Synctex()
	if !exists("g:syncPDFfile")
		call SetPDFFilePrompt()
	end
	" remove 'silent' for debugging
	execute "silent !zathura --synctex-forward " . line('.') . ":" . col('.') . ":" . bufname('%') . " " . g:syncPDFfile
endfunction

map <F5> :call Synctex()<cr>

