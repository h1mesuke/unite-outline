"=============================================================================
" File    : autoload/unite/sources/outline/defaults/dosini.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Windows INI files
" Version: 0.0.1

function! unite#sources#outline#defaults#dosini#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading': '^\s*\[[^\]]\+\]',
      \ }

" vim: filetype=vim
