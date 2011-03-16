"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby_rspec.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-16
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby.RSpec
" Version: 0.0.8

function! unite#sources#outline#defaults#ruby_rspec#outline_info()
  return s:outline_info
endfunction

let headings  = ['module', 'class', 'def', 'BEGIN', 'END', '__END__']
let headings += ['before', 'describe', 'it', 'after']

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\s*\(' . join(headings, '\|') . '\)\%(\s\|$\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \}
unlet headings

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = unite#sources#outline#
        \util#get_indent_level(a:context, a:context.heading_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:context, a:context.matched_lnum)
  elseif a:which == 'heading'
    let heading.type = matchstr(a:heading_line, self.heading)
    if a:heading_line =~ '^\s*\%(BEGIN\|END\)\>'
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
    let heading.word = substitute(heading.word, '\s*\%(do\|{\)\%(\s*|[^|]*|\)\=\s*$', '', '')
  endif

  return heading
endfunction

" vim: filetype=vim
