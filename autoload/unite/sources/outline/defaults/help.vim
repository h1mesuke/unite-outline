"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-09
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim Help
" Version: 0.1.0

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
"== Level 2
"
"   --------------------------------------------------------------------------
"   Heading
"
"== Level 3
"
"   1.1 Heading
"
"== Level 4-1
"
"   HEADING                                         *tag*
"
"== Level 4-2
"
"   HEADING ~
"                                                   *tag*

" patterns
let s:section_number = '\d\+\.\d\+\s\+\S'
let s:upper_word = '\u[[:upper:][:digit:]_]\+\>'
let s:helptag = '\*[^*]\+\*'

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\('.s:section_number.'\|'.s:upper_word.'.*\('.s:helptag.'\|\~\)\)',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  let lines = a:context.lines

  if a:which ==# 'heading-1'
    let m = a:context.matched_index
    if a:matched_line =~ '^='
      let heading.level = 1
    elseif a:matched_line =~ '^-' && lines[m-1] !~ '\S'
      let heading.level = 2
    endif
  elseif a:which ==# 'heading'
    let h = a:context.heading_index
    if a:heading_line =~ '^'.s:section_number
      if a:heading_line =~ '\~\s*$'
        let heading.level = 3
      endif
    elseif a:heading_line =~ s:helptag ||
          \ unite#sources#outline#util#neighbor_match(lines, h, s:helptag)
      let heading.level = 4
    endif
  endif

  if heading.level > 0
    let heading.word = s:normalize_heading_word(heading.word)
    if heading.word =~? '^Contents\s*$'
      let heading.level = 1
    endif
    return heading
  else
    return {}
  endif
endfunction

function! s:normalize_heading_word(str)
  let str = substitute(a:str, '\(\~\|{{{\d\=\)\s*$', '', '')
  let str = substitute(str, s:helptag, '', 'g')
  if str !~ '\l'
    let str = unite#sources#outline#util#capitalize(str, 'g')
  endif
  return str
endfunction

" vim: filetype=vim
