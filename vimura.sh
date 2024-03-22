#!/bin/bash

## expect one argument, the pdf filename
echo $1
zathura -x "gvim --servername $1 -c \"let g:syncpdf='$1'\" --remote +%{line} %{input}" $*

