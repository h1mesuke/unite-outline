"=============================================================================
" File    : autoload/unite/sources/outline/defaults/markdown.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-22
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Markdown
" Version: 0.0.2

function! unite#sources#outline#defaults#markdown#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : '^#\+',
      \ 'heading+1': '^[-=]\+$',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = 0
  if a:which ==# 'heading'
    let level = strlen(matchstr(a:heading_line, '^#\+'))
    let heading = substitute(a:heading_line, '^#\+\s*', '', '')
    let heading = substitute(heading, '\s*#\+\s*$', '', '')
  elseif a:which ==# 'heading+1'
    if a:matched_line =~ '^='
      let level = 1
    else
      let level = 2
    endif
    let heading = a:heading_line
  endif
  if level > 0
    let heading = substitute(heading, '\s*<a[^>]*>\s*\(</a>\s*\)\=$', '', '')
    return unite#sources#outline#util#indent(level) . heading
  else
    return ""
  endif
endfunction

" vim: filetype=vim
