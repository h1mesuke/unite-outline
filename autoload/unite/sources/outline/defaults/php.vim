"=============================================================================
" File       : autoload/unite/sources/outline/defaults/php.vim
" Maintainer : h1mesuke <himesuke@gmail.com>
" Updated    : 2011-01-09
"
" Improved by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.0.3

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

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': unite#sources#outline#util#get_indent_level(a:heading_line, a:context),
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1'
    let heading.type = 'comment'
  else
    let heading.word = substitute(a:heading_line, '\s*{.*$', '', '')
  endif

  return heading
endfunction

" vim: filetype=vim
