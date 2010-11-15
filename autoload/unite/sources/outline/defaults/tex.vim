"=============================================================================
" File    : autoload/unite/sources/outline/defaults/tex.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-16
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for TeX

function! unite#sources#outline#defaults#tex#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : '^\\\(title\|part\|chapter\|section\|subsection\|subsubsection\){',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  if a:which ==# 'heading'
    let cmd = matchstr(a:heading_line, '^\\\zs\w\+\ze{')
    if cmd ==# 'title'
      let level = 1
    elseif cmd ==# 'part'
      let level = 2
    elseif cmd ==# 'chapter'
      let level = 3
    elseif cmd ==# 'section'
      let level = 4
    elseif cmd ==# 'subsection'
      let level = 5
    elseif cmd ==# 'subsubsection'
      let level = 6
    endif
  endif
  if level > 0
    let heading = matchstr(a:heading_line, '^\\\w\+{\zs.*\ze}\s*$')
    let heading = unite#sources#outline#indent(level) . heading
    return heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
