"=============================================================================
" File    : autoload/unite/sources/outline/defaults/conf.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-22
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Conf files
" Version: 0.0.2

function! unite#sources#outline#defaults#conf#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1'
    let heading.type = 'comment'
    if a:matched_line =~ '^#\s*='
      let heading.level = 1
    elseif strlen(substitute(a:matched_line, '\s*', '', 'g')) > 40
      let heading.level = 2
    else
      let heading.level = 3
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

" vim: filetype=vim
