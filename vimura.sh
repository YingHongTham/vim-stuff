#!/bin/bash

## expect one argument, the pdf filename
## zathura freezes; just calling zathura allows one way (from vim to pdf)
#zathura -x "vim --servername vim -c \"let g:syncPDFfile='$1'\" --remote +%{line} %{input}" $*
