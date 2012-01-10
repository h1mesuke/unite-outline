"=============================================================================
" File    : autoload/unite/sources/outline/defaults/dosini.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Windows INI files
" Version: 0.0.2

function! unite#sources#outline#defaults#dosini#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^\s*\[[^\]]\+\]',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 1,
        \ 'type' : 'generic',
        \ }
  return heading
endfunction
