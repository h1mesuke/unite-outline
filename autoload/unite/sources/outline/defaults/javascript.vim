"=============================================================================
" File    : autoload/unite/sources/outline/defaults/javascript.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for JavaScript

function! unite#sources#outline#defaults#javascript#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*\(var\s\+\u\w*\s\+=\s\+{\|function\>\)',
      \ 'skip': {
      \   'header': unite#sources#outline#shared#pattern('cpp', 'header'),
      \ },
      \}

" vim: filetype=vim
