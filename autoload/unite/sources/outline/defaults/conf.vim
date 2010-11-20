"=============================================================================
" File    : autoload/unite/sources/outline/defaults/conf.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-21
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Conf files

function! unite#sources#outline#defaults#conf#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('sh', 'heading-1'),
      \ 'skip': {
      \   'header': unite#sources#outline#shared#pattern('sh', 'header'),
      \ },
      \}

" vim: filetype=vim
