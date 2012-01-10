"=============================================================================
" File    : autoload/unite/sources/outline/text.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Text (WzMemo style)
" Version: 0.0.2

" USAGE:
" 1. Copy   this file to '~/.vim/autoload/unite/sources/outline'
" 2. Rename this file to 'text.vim'
"
" If needed:
" 3. Make a ftdetect file for text filetype at '~/.vim/ftdetect/text.vim'
"    and write this:
"
"    autocmd BufRead,BufNewFile *.txt  set filetype=text

function! unite#sources#outline#defaults#text#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : '^\.\+',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = strlen(matchstr(a:heading_line, '^\.\+'))
  let heading = {
        \ 'word' : substitute(a:heading_line, '^\.\+\s*', '', ''),
        \ 'level': level,
        \ 'type' : 'generic',
        \ }
  return heading
endfunction
