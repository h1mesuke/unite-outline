"=============================================================================
" File    : autoload/unite/sources/outline/defaults/vim.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for VimScript

function! unite#sources#outline#defaults#vim#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': '^\s*"\s*[-=]\{10,}\s*$',
      \ 'heading'  : '^\s*fu\%[nction]!\= ',
      \ 'skip': {
      \   'header': '^"',
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:which ==# 'heading-1'
    return unite#sources#outline#indent(1) . a:heading_line
  elseif a:which ==# 'heading'
    return unite#sources#outline#indent(3) . a:heading_line
  endif
  return ""
endfunction

" vim: filetype=vim
