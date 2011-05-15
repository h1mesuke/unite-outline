"=============================================================================
" File    : autoload/unite/sources/outline/defaults/help.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-19
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim Help
" Version: 0.1.2

function! unite#sources#outline#defaults#help#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

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

"---------------------------------------
" Sub Patterns

let s:section_number = '\d\+\.\d\+\s\+\S'
let s:upper_word = '\u[[:upper:][:digit:]_]\+\>'
let s:helptag = '\*[^*]\+\*'

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': '^[-=]\{10,}\s*$',
      \ 'heading'  : '^\%(' . s:section_number . '\|' . s:upper_word . '.*\%(' . s:helptag . '\|\~\)\)',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  let lines = a:context.lines

  if a:which ==# 'heading-1'
    let m_lnum = a:context.matched_lnum
    if a:matched_line =~ '^='
      let heading.level = 1
    elseif a:matched_line =~ '^-' && lines[m_lnum-1] !~ '\S'
      let heading.level = 2
    endif
  elseif a:which ==# 'heading'
    let h_lnum = a:context.heading_lnum
    if a:heading_line =~ '^' . s:section_number
      if a:heading_line =~ '\~\s*$'
        let heading.level = 3
      endif
    elseif a:heading_line =~ s:helptag ||
          \ s:Util.neighbor_match(a:context, h_lnum, s:helptag)
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

function! s:normalize_heading_word(heading_word)
  let heading_word = substitute(a:heading_word, '\%(\~\|{{{\d\=\)\s*$', '', '')
  let heading_word = substitute(heading_word, s:helptag, '', 'g')
  if heading_word !~ '\l'
    let heading_word = s:Util.String.capitalize(heading_word, 'g')
  endif
  return heading_word
endfunction

" vim: filetype=vim
