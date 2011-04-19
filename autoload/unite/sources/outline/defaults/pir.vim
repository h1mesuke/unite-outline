"=============================================================================
" File    : autoload/unite/sources/outline/defaults/pir.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-19
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PIR
" Version: 0.0.3 (draft)

function! unite#sources#outline#defaults#pir#outline_info()
  return s:outline_info
endfunction

let s:util = unite#sources#outline#import('util')

let s:outline_info = {
      \ 'heading-1': s:util.shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\.sub\>',
      \ 'skip': {
      \   'header': s:util.shared_pattern('sh', 'header'),
      \   'block' : ['^=\%(cut\)\@!\w\+', '^=cut'],
      \ },
      \}

" vim: filetype=vim
