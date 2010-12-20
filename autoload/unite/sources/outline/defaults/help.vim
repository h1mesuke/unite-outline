"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-21
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim Help
" Version: 0.0.8

function! unite#sources#outline#defaults#help#outline_info()
  return s:outline_info
endfunction

" HEADING SAMPLES:
"
"== Level 1
"
"   ==========================================================================
"   Heading
"
"== Level 2-1
"
"   --------------------------------------------------------------------------
"   Heading
"
"== Level 2-2
"
"   1.1 Heading
"
"== Level X-1
"
"   HEADING                                         *tag*
"
"== Level X-2
"
"   HEADING ~
"                                                   *tag*

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

" patterns
let s:section_number = '\d\+\.\d\+\s\+\S'
let s:upper_word = '\u[[:upper:][:digit:]_]\+\>'
let s:helptag = '\*\S\+\*'

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\('.s:section_number.'\|'.s:upper_word.'.*\('.s:helptag.'\|\~\)\)',
      \ }

function! s:outline_info.initialize(context)
  let s:level_x = 1
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
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
      " NOTE: If the line contains a timestamp, it is a changelog maybe.
      if a:heading_line !~ '\d\{2}:\d\{2}:\d\{2}'
        let level = 2 | let s:level_x = 3
      endif
    elseif a:heading_line =~ s:helptag
      " X-1
      let level = s:level_x
    else
      let h = a:context.heading_index
      if unite#sources#outline#util#neighbor_match(lines, h, s:helptag)
        " X-2
        let level = s:level_x
      endif
    endif
  endif
  if level > 0
    let heading = substitute(a:heading_line, '\(\~\|{{{\d\=\)\s*$', '', '')
    let heading = substitute(heading, s:helptag, '', 'g')
    if a:heading_line =~ s:upper_word
      let heading = unite#sources#outline#util#capitalize(heading, 'g')
    endif
    return unite#sources#outline#util#indent(level) . heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
