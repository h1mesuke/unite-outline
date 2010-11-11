"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim's help

function! unite#sources#outline#defaults#help#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\d\+\.\d\+\s',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:which ==# 'heading-1'
    if a:matched_line =~ '^='
      return unite#sources#outline#indent(1) . a:heading_line
    elseif a:matched_line =~ '^-' && strlen(a:matched_line) > 30
      return unite#sources#outline#indent(2) . a:heading_line
    endif
  elseif a:which ==# 'heading'
    let next_line = a:context.lines[a:context.matched_index + 1]
    if next_line =~ '\*\S\+\*'
      return unite#sources#outline#indent(2) . a:heading_line
    endif
  endif
  return ""
endfunction

" vim: filetype=vim
