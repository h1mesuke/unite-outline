"=============================================================================
" File    : autoload/unite/sources/outline/defaults/java.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-14
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Java
" Version: 0.1.0

function! unite#sources#outline#defaults#java#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading_groups': [
      \   ['package'],
      \   ['interface', 'class', 'enum'],
      \   ['method'],
      \ ]
      \}

function! s:outline_info.extract_headings(context)
  return unite#sources#outline#lib#ctags#extract_headings(a:context)
endfunction

" vim: filetype=vim
