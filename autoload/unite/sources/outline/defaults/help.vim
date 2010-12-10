"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim Help
" Version: 0.0.6

function! unite#sources#outline#defaults#help#outline_info()
  return s:outline_info
endfunction

" Heading Samples:
"
" ==============================================================================
" Level 1
"
" ------------------------------------------------------------------------------
" Level 2-1
"
" 1.1 Level 2-2
"
" LEVEL X-1                                       *tag*
"
" LEVEL X-2 ~
"                                                 *tag*

" Level Shifting:
"
" +---------+---------+---------+
" | Level 1 | Level 2 | Level X |
" +---------+---------+---------+
" |  exist  |  exist  |    3    |
" |  exist  |  none   |    2    |
" |  none   |  none   |    1    |
" |  none   |  exist  |    3    |
" +---------+---------+---------+

" patterns
let s:section_number = '\d\+\.\d\+\s\+\S'
let s:upper_word = '\u[[:upper:][:digit:]_]\+\>'
let s:helptag = '\*\S\+\*'

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\('.s:section_number.'\|'.s:upper_word.'.*\('.s:helptag.'\|\~\)\)',
      \ }

function! s:initialize()
  let s:level_x = 1
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:context.heading_id == 1
    call s:initialize()
  endif
  let level = 0
  let lines = a:context.lines
  if a:which ==# 'heading-1'
    let m = a:context.matched_index
    if a:matched_line =~ '^='
      let level = 1 | let s:level_x = 2
    elseif a:matched_line =~ '^-' && lines[m-1] !~ '\S'
      " 2-1
      let level = 2 | let s:level_x = 3
    endif
  elseif a:which ==# 'heading'
    if a:heading_line =~ '^'.s:section_number
      " 2-2
      let level = 2 | let s:level_x = 3
    elseif a:heading_line =~ s:helptag
      " X-1
      let level = s:level_x
    else
      let h = a:context.heading_index
      if unite#sources#outline#neighbor_match(lines, h, s:helptag)
        " X-2
        let level = s:level_x
      endif
    endif
  endif
  if level > 0
    let heading = substitute(a:heading_line, '\(\~\|{{{\d\=\)\s*$', '', '')
    let heading = substitute(heading, s:helptag, '', 'g')
    if a:heading_line =~ s:upper_word
      let heading = unite#sources#outline#capitalize(heading, 'g')
    endif
    let heading = unite#sources#outline#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
