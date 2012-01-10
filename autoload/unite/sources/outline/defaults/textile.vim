"=============================================================================
" File       : autoload/unite/sources/outline/defaults/textile.vim
" Author     : basyura
" Maintainer : h1mesuke <himesuke@gmail.com>
" Updated    : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Textile
" Version: 0.0.2

function! unite#sources#outline#defaults#textile#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^h[1-6]\.\s',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : substitute(a:heading_line, '^h[1-6]\.\s\+', '', ''),
        \ 'level': str2nr(matchstr(a:heading_line, '^h\zs[1-6]\ze\.\s')),
        \ 'type' : 'generic',
        \ }
  return heading
endfunction
