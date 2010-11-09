"=============================================================================
" File    : autoload/unite/sources/outline/defaults/python.vim
" Author  : h1mesuke
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Python

function! unite#sources#outline#defaults#python#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('sh', 'heading-1'),
      \ 'heading'  : '^\s*\(class\|def\)\>',
      \ 'skip': {
      \   'header': unite#sources#outline#shared#pattern('sh', 'header'),
      \ },
      \}

" vim: filetype=vim
