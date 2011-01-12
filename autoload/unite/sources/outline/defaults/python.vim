"=============================================================================
" File    : autoload/unite/sources/outline/defaults/python.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Python
" Version: 0.0.1 (draft)

function! unite#sources#outline#defaults#python#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\s*\(class\|def\)\>',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \ },
      \}

" vim: filetype=vim
