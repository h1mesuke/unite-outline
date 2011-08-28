"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby_rspec.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-29
"
" Contributed by kenchan
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby.RSpec
" Version: 0.1.0

function! unite#sources#outline#defaults#ruby_rspec#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

let headings  = ['module', 'class', 'def', 'BEGIN', 'END', '__END__']
let headings += ['before', 'context', 'describe', 'its\=', 'let!\=', 'specify', 'subject', 'after']

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\s*\zs\(' . join(headings, '\|') . '\)\>',
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \}
unlet headings

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  " Level 1 to 3 are reserved for comment headings.
  let level = s:Util.get_indent_level(a:context, h_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)
  elseif a:which == 'heading'
    let heading.type = matchstr(a:heading_line, self.heading)
    if heading.type =~ '^\%(BEGIN\|END\|let!\=\)$'
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
    let heading.word = substitute(heading.word, '\s*\%(do\|{\)\%(\s*|[^|]*|\)\=\s*$', '', '')
  endif
  return heading
endfunction

" vim: filetype=vim
