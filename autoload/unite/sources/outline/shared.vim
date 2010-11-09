"=============================================================================
" File    : autoload/unite/source/outline/shared.vim
" Author  : h1mesuke
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Shared pattenrs

function! unite#sources#outline#shared#pattern(filetype, name)
    return s:shared_pattern[a:filetype][a:name]
endfunction

let s:shared_pattern = {
      \ 'c': {
      \   'header'   : ['^/\*', '\*/\s*$'],
      \   'heading-1': '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \ },
      \ 'cpp': {
      \   'header'   : {
      \     'leading': '^//',
      \     'block'  : ['^/\*', '\*/\s*$'],
      \   },
      \ },
      \   'heading-1': '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
      \ },
      \ 'sh': {
      \   'header'   : '^#',
      \   'heading-1': '^\s*#\s*[-=#]\{10,}\s*$',
      \ },
      \}

" vim: filetype=vim
