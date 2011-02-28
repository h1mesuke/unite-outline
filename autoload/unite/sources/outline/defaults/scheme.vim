"=============================================================================
" File    : autoload/unite/sources/outline/defaults/scheme.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-01
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Scheme
" Version: 0.0.5 (draft)

function! unite#sources#outline#defaults#scheme#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': '^\s*;\+\s*[-=]\{10,}\s*$',
      \ 'heading'  : '^\s*(define\>',
      \ 'skip': { 'header': '^;' },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1' && a:heading_line =~ '^\s*;'
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:context, a:context.matched_lnum, 5)
  elseif a:which ==# 'heading'
    let heading.level = 4
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

" vim: filetype=vim
