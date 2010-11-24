"=============================================================================
" File    : autoload/unite/sources/outline/defaults/php.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*[a-z ]*\(interface\|class\|function\)\>',
      \ 'skip': {
      \   'header': {
      \     'leading': '^\(<?php\|//\)',
      \     'block'  : unite#sources#outline#shared#pattern('c', 'header'),
      \   },
      \ },
      \}

" vim: filetype=vim
