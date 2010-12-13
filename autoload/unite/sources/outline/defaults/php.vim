"=============================================================================
" File       : autoload/unite/sources/outline/defaults/php.vim
" Maintainer : h1mesuke <himesuke@gmail.com>
" Updated    : 2010-12-11
"
" Improved by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.0.2

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*[a-z ]*\(interface\|class\|function\)\>',
      \ 'skip': {
      \   'header': {
      \     'leading': '^\(<?php\|//\)',
      \     'block'  : unite#sources#outline#util#shared_pattern('c', 'header'),
      \   },
      \ },
      \}

" vim: filetype=vim
