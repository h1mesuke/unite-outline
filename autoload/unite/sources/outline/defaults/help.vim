"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-14
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim's help

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
      let h = a:context.heading_index
      if unite#sources#outline#neighbor_match(a:context.lines, h, '\*\S\+\*')
        let level += 1
      else
        let level = 0
      endif
    endif
  endif
  if level > 0
    let heading = unite#sources#outline#indent(level) . a:heading_line
    if a:heading_line =~ '^\u\u'
      let heading = unite#sources#outline#capitalize(heading)
    endif
    let heading = substitute(heading, '\(\~\|{{{\d\=\)\s*$', '', '')
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
