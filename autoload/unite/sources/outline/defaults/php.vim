"=============================================================================
" File    : autoload/unite/sources/outline/defaults/php.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-02
"
" Contributed by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.0.7

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*[a-z ]*\%(interface\|class\|function\)\>',
      \ 'skip': {
      \   'header': {
      \     'leading': '^\%(<?php\|//\)',
      \     'block'  : unite#sources#outline#util#shared_pattern('c', 'header'),
      \   },
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = unite#sources#outline#
        \util#get_indent_level(a:context, a:context.heading_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && unite#sources#outline#
        \util#_cpp_is_in_comment(a:heading_line, a:matched_line)
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:context, a:context.matched_lnum)
  else
    let heading.word = substitute(a:heading_line, '\s*{.*$', '', '')
  endif

  return heading
endfunction

" vim: filetype=vim
