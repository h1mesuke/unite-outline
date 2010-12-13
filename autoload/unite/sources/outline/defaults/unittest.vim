"=============================================================================
" File    : autoload/unite/sources/outline/defaults/unittest.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for UnitTest results
" Version: 0.0.2

function! unite#sources#outline#defaults#unittest#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'is_volatile': 1,
      \ 'heading-1': '^[-=]\{10,}',
      \ 'heading'  : '^\s*\d\+) \(Failure\|Error\): ',
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  if a:which ==# 'heading-1'
    if a:matched_line =~ '^='
      let level = 1
    elseif a:matched_line =~ '^-'
      let level = 2
    endif
  elseif a:which ==# 'heading'
    let level = 3
  endif
  if level > 0
    let heading = unite#sources#outline#util#indent(level) . a:heading_line
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
