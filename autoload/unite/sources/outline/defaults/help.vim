"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-15
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim Help

function! unite#sources#outline#defaults#help#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\(\d\+\.\d\+\s\|\u\u.*\(\*\S\+\*\|\~\)\)',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  if a:which ==# 'heading-1'
    if a:matched_line =~ '^='
      let level = 1
    elseif a:matched_line =~ '^-' && strlen(a:matched_line) > 30
      let level = 2
    endif
  elseif a:which ==# 'heading'
    let level = 2
    if a:heading_line =~ '\~\s*$'
      let lines = a:context.lines | let h = a:context.heading_index
      if a:heading_line =~ '^\d\+\.\d\+\s'
        " keep this level
      elseif unite#sources#outline#neighbor_match(lines, h, '\*\S\+\*')
        let level += 1
      else
        let level = 0
      endif
    endif
  endif
  if level > 0
    let heading = substitute(a:heading_line, '\(\~\|{{{\d\=\)\s*$', '', '')
    if a:heading_line =~ '^\u\u'
      let heading = unite#sources#outline#capitalize(heading, 'g')
    endif
    let heading = unite#sources#outline#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
