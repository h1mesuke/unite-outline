"=============================================================================
" File    : autoload/unite/sources/outline/defaults/css.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for CSS
" Version: 0.0.3

function! unite#sources#outline#defaults#css#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('c', 'heading-1'),
      \
      \ 'skip': {
      \   'header': {
      \     'leading': '^@charset',
      \     'block'  : s:Util.shared_pattern('c', 'header'),
      \   },
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1'
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum, 4)
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction
