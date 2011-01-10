"=============================================================================
" File    : autoload/unite/sources/outline/defaults/vim.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for VimScript
" Version: 0.0.8

function! unite#sources#outline#defaults#vim#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': '^\s*"\s*[-=]\{10,}\s*$',
      \ 'heading'  : '^\s*fu\%[nction]!\= ',
      \ 'skip': { 'header': '^"' },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1'
    let heading.type = 'comment'
    if a:matched_line =~ '^\s'
      let heading.level = 4
    elseif strlen(substitute(a:matched_line, '\s*', '', 'g')) > 40
      let heading.level = 1
    else
      let heading.level = 2
    endif
  elseif a:which ==# 'heading'
    let heading.level = 3
    let heading.type = 'function'
  endif

  if heading.level > 0
    let heading.word = substitute(heading.word, '"\=\s*{{{\d\=\s*$', '', '')
    return heading
  else
    return {}
  endif
endfunction

" vim: filetype=vim
