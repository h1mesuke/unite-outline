"=============================================================================
" File    : autoload/unite/sources/outline/defaults/scheme.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-30
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Scheme
" Version: 0.0.1 (draft)

function! unite#sources#outline#defaults#scheme#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : '^\s*(define\>',
      \}

" vim: filetype=vim
