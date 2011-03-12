"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-13
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.3

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading_groups': {
      \   'MACRO': ['macro'],
      \   'TYPE' : ['class', 'enum', 'struct', 'typedef'],
      \   'PROC' : ['function'],
      \ }
      \}

function! s:outline_info.extract_headings(context)
  return unite#sources#outline#lib#ctags#extract_headings(a:context)
endfunction

" vim: filetype=vim
