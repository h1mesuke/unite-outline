"=============================================================================
" File    : autoload/unite/sources/outline/defaults/rst.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for reStructuredText
" Version: 0.0.3

function! unite#sources#outline#defaults#rst#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading+1': '^[[:punct:]]\{4,}$',
      \ }

function! s:outline_info.before(context)
  let s:adornment_levels = {}
  let s:adornment_id = 2
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  let lines  = a:context.lines
  let h_lnum = a:context.heading_lnum

  " Check the matching strictly.
  if a:matched_line =~ '^\([[:punct:]]\)\1\{3,}$'
    if h_lnum > 1 && lines[h_lnum - 1] == a:matched_line
      " Title
      let heading.level = 1
    else
      " Sections
      let adchar = a:matched_line[0]
      if !has_key(s:adornment_levels, adchar)
        let s:adornment_levels[adchar] = s:adornment_id
        let s:adornment_id += 1
      endif
      let heading.level = s:adornment_levels[adchar]
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction
