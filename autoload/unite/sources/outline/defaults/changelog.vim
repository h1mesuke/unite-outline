"=============================================================================
" File    : autoload/unite/sources/outline/defaults/changelog.vim
" Author  : sgur
" Updated : 2011-02-25
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for ChangeLog
" Version: 0.0.1

function! unite#sources#outline#defaults#changelog#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading': '^\s\+\*.\+',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  return substitute(a:heading_line, '\s\+\*\s*', '', '')
endfunction

" vim: filetype=vim
