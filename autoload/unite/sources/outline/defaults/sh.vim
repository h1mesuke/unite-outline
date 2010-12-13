"=============================================================================
" File    : autoload/unite/sources/outline/defaults/sh.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Shell Scripts
" Version: 0.0.2

function! unite#sources#outline#defaults#sh#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\s*\(\w\+()\|function\>\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  let heading = substitute(a:heading_line, '^\s*', '', '')
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
    let heading = substitute(heading, '\s*{.*$', '', '')
  endif
  if level > 0
    let heading = unite#sources#outline#util#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
