"=============================================================================
" File    : autoload/unite/sources/outline/defaults/text.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Text

function! unite#sources#outline#defaults#text#outline_info()
  return s:outline_info
endfunction

let s:assigned = 0

if has("multi_byte")
  scriptencoding utf-8
  try
    let s:outline_info = {
          \ 'heading' : '^\s*\([■□●○◎▲△▼▽★☆]\|[１２３４５６７８９０]\+、\|\d\+\. \|\a\. \)',
          \ }
    let s:assigned = 1
  endtry
  scriptencoding
endif

if !s:assigned
  " fallback
  let s:outline_info = {
        \ 'heading' : '^\s*\(\d\+\. \|\a\. \)',
        \ }
endif

" vim: filetype=vim
