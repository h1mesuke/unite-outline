"=============================================================================
" File    : autoload/unite/sources/outline/defaults/markdown.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Markdown
" Version: 0.0.5

function! unite#sources#outline#defaults#markdown#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading'  : '^#\+',
      \ 'heading+1': '^[-=]\+$',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading'
    let heading.level = strlen(matchstr(a:heading_line, '^#\+'))
    let heading.word = substitute(heading.word, '^#\+\s*', '', '')
    let heading.word = substitute(heading.word, '\s*#\+\s*$', '', '')
  elseif a:which ==# 'heading+1'
    if a:matched_line =~ '^='
      let heading.level = 1
    else
      let heading.level = 2
    endif
  endif

  if heading.level > 0
    let heading.word = substitute(heading.word, '\s*<a[^>]*>\s*\%(</a>\s*\)\=$', '', '')
    return heading
  else
    return {}
  endif
endfunction
