"=============================================================================
" File    : autoload/unite/sources/outline/defaults/vim.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-24
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
  let level = 0
  if a:which ==# 'heading-1'
    if a:matched_line =~ '^\s'
      let level = 4
    elseif strlen(substitute(a:matched_line, '\s*', '', 'g')) > 40
      let level = 1
    else
      let level = 2
    endif
  elseif a:which ==# 'heading'
    let level = 3
  endif
  if level > 0
    let heading = substitute(a:heading_line, '^\s*', '', '')
    let heading = substitute(heading, '"\=\s*{{{\d\=\s*$', '', '')
    let heading = unite#sources#outline#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
