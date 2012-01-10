"=============================================================================
" File       : autoload/unite/sources/outline/defaults/changelog.vim
" Author     : sgur
" Maintainer : h1mesuke <himesuke@gmail.com>
" Updated    : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for ChangeLog
" Version: 0.0.2

function! unite#sources#outline#defaults#changelog#outline_info()
  return s:outline_info
endfunction

"---------------------------------------
" Sub Patterns

let s:pat_date = '\(\S.*\)\=\d\+[-:]\d\+[-:]\d\+'
let s:pat_item = '\s\+\*\s\+'

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^\(' . s:pat_date . '\|' . s:pat_item . '\)',
      \
      \ 'highlight_rules': [
      \   { 'name'     : 'level_1',
      \     'pattern'  : '/' . s:pat_date . '.*/' },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:heading_line =~ '^' . s:pat_date
    let heading.level = 1
  elseif a:heading_line =~ '^' . s:pat_item
    let heading.level = 2
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction
