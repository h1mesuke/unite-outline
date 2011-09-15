"=============================================================================
" File    : autoload/unite/sources/outline/defaults/textile.vim
" Author  : basyura
" Updated : 2011-09-15
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Textile
" Version: 0.0.1

function! unite#sources#outline#defaults#textile#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^h\d',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word'  : substitute(a:heading_line, 'h\d\+\.\s\+', '', '') ,
        \ 'level' : matchstr(a:heading_line, '^h\zs\d\+\ze') ,
        \ 'type' : 'generic',
        \ }
  return heading
endfunction

" vim: filetype=vim
