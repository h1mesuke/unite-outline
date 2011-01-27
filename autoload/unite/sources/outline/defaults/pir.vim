"=============================================================================
" File    : autoload/unite/sources/outline/defaults/pir.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-28
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PIR
" Version: 0.0.2 (draft)

function! unite#sources#outline#defaults#pir#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\.sub\>',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \   'block' : ['^=\%(cut\)\@!\w\+', '^=cut'],
      \ },
      \}

" vim: filetype=vim
