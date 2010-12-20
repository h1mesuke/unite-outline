"=============================================================================
" File    : autoload/unite/sources/outline/text.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-21
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Text (dotted outline style)
" Version: 0.0.1

" USAGE:
" 1. Place  this file in '~/.vim/autoload/unite/sources/outline'
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
  let heading = substitute(a:heading_line, '^\.\+\s*', '', '')
  return unite#sources#outline#util#indent(level) . heading
endfunction

" vim: filetype=vim
