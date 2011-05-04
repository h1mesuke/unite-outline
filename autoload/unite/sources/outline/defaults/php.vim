"=============================================================================
" File    : autoload/unite/sources/outline/defaults/php.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-23
"
" Contributed by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.0.8

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*[a-z ]*\%(interface\|class\|function\)\>',
      \ 'skip': {
      \   'header': {
      \     'leading': '^\%(<?php\|//\)',
      \     'block'  : s:Util.shared_pattern('c', 'header'),
      \   },
      \ },
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  let level = s:Util.get_indent_level(a:context, h_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && s:Util._cpp_is_in_comment(a:heading_line, a:matched_line)
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)
  else
    let heading.word = substitute(a:heading_line, '\s*{.*$', '', '')
  endif

  return heading
endfunction

" vim: filetype=vim
