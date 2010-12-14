"=============================================================================
" File    : autoload/unite/sources/outline/defaults/vim.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-15
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for VimScript
" Version: 0.0.7

function! unite#sources#outline#defaults#vim#outline_info()
  return s:outline_info
endfunction

" LEVEL SHIFTING:
"
" +---------+---------+---------+
" | Level 1 | Level 2 | Level X |
" +---------+---------+---------+
" |    1    |    2    |    3    |
" |    1    |  none   |    2    |
" |  none   |  none   |    1    |
" |  none   |    2    |    3    |
" +---------+---------+---------+

let s:outline_info = {
      \ 'heading-1': '^\s*"\s*[-=]\{10,}\s*$',
      \ 'heading'  : '^\s*fu\%[nction]!\= ',
      \ 'skip': {
      \   'header': '^"',
      \ },
      \}

function! s:outline_info.initialize(context)
  let s:level_x = 1
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  let heading = substitute(a:heading_line, '^\s*', '', '')
  if a:which ==# 'heading-1'
    if a:matched_line =~ '^\s'
      let level = s:level_x + 1
    elseif strlen(substitute(a:matched_line, '\s*', '', 'g')) > 40
      let level = 1 | let s:level_x = 2
    else
      let level = 2 | let s:level_x = 3
    endif
  elseif a:which ==# 'heading'
    let level = s:level_x
  endif
  if level > 0
    let heading = substitute(heading, '"\=\s*{{{\d\=\s*$', '', '')
    let heading = unite#sources#outline#util#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
