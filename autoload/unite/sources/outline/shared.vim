"=============================================================================
" File    : autoload/unite/source/outline/shared.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Shared pattenrs

function! unite#sources#outline#shared#pattern(filetype, name)
  let ft_pattern = s:shared_pattern[a:filetype]
  return ft_pattern[a:name]
endfunction

let s:shared_pattern = {
      \ 'c': {
      \   'heading-1': '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \   'header'   : ['^/\*', '\*/\s*$'],
      \ },
      \ 'cpp': {
      \   'heading-1': '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
      \   'header'   : {
      \     'leading': '^//',
      \     'block'  : ['^/\*', '\*/\s*$'],
      \   },
      \ },
      \ 'sh': {
      \   'heading-1': '^\s*#\s*[-=#]\{10,}\s*$',
      \   'header'   : '^#',
      \ },
      \}

" vim: filetype=vim
