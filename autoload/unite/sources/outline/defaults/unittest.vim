"=============================================================================
" File    : autoload/unite/sources/outline/defaults/unittest.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for UnitTest results
" Version: 0.0.5

" h1mesuke/vim-unittest - GitHub
" https://github.com/h1mesuke/vim-unittest

function! unite#sources#outline#defaults#unittest#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'is_volatile': 1,
      \
      \ 'heading-1': '^[-=]\{10,}',
      \ 'heading'  : '^\s*\d\+) \%(Failure\|Error\): ',
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1'
    if a:matched_line =~ '^=' || a:heading_line =~ '^\d\+ tests,'
      let heading.level = 1
    elseif a:matched_line =~ '^-'
      let heading.level = 2
    endif
  elseif a:which ==# 'heading'
    let heading.level = 3
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction
