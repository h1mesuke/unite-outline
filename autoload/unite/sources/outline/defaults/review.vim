"=============================================================================
" File    : autoload/unite/sources/outline/defaults/review.vim
" Author  : AKAMATSU Yuki <y.akamatsu@ukstudio.jp>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for ReVIEW
" Version: 0.0.2

function! unite#sources#outline#defaults#review#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^=\+',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : substitute(a:heading_line, '^=\+\s*', '', ''),
        \ 'level': strlen(matchstr(a:heading_line, '^=\+')),
        \ 'type' : 'generic',
        \ }
  if heading.word !~ '^\[/'
    return heading
  else
    return {}
  endif
endfunction
