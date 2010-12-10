"=============================================================================
" File    : autoload/unite/sources/outline/defaults/css.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for CSS
" Version: 0.0.2

function! unite#sources#outline#defaults#css#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('c', 'heading-1'),
      \ 'skip': {
      \   'header': {
      \     'leading': '^@charset',
      \     'block'  : unite#sources#outline#shared#pattern('c', 'header'),
      \   },
      \ },
      \}

" vim: filetype=vim
