"=============================================================================
" File    : autoload/unite/sources/outline/defaults/python.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-09-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Python
" Version: 0.2.0

function! unite#sources#outline#defaults#python#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading'  : '^\s*\%(class\|def\)\>',
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('sh', 'header'),
      \   'block' : ['^\s*r\="""', '^\s*"""'],
      \ },
      \
      \ 'heading_groups': {
      \   'type'     : ['class'],
      \   'function' : ['function'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'   : 'type',
      \     'pattern': '/\S\+\ze : class/' },
      \   { 'name'   : 'function',
      \     'pattern': '/\h\w*\ze\s*(/' },
      \   { 'name'   : 'parameter_list',
      \     'pattern': '/(.*)/' },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  let level = s:Util.get_indent_level(a:context, h_lnum)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if heading.word =~ '^\s*class\>'
    " Class
    let heading.type = 'class'
    let heading.word = matchstr(heading.word, '^\s*class\s\+\zs\h\w*') . ' : class'
  elseif heading.word =~ '^\s*def\>'
    " Function
    let heading.type = 'function'
    let heading.word = substitute(heading.word, '\<def\s*', '', '')
    let heading.word = substitute(heading.word, '\S\zs(', ' (', '')
    let heading.word = substitute(heading.word, '\%(:\|#\).*$', '', '')
  endif
  return heading
endfunction

function! s:outline_info.need_blank_between(head1, head2, memo)
  if a:head1.group == 'function' && a:head2.group == 'function'
    " Don't insert a blank between two sibling functions.
    return 0
  else
    return (a:head1.group != a:head2.group ||
          \ s:Util.has_marked_child(a:head1, a:memo) ||
          \ s:Util.has_marked_child(a:head2, a:memo))
  endif
endfunction

" vim: filetype=vim
