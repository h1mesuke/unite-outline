"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-01
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby
" Version: 0.0.7

function! unite#sources#outline#defaults#ruby#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\%(\s*\%(module\|class\|def\|BEGIN\|END\)\>\|__END__$\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = unite#sources#outline#
        \util#get_indent_level(a:heading_line, a:context) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:matched_line, a:context)
  elseif a:which == 'heading'
    if a:heading_line =~ '^\s*\%(BEGIN\|END\)\>'
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
  endif

  return heading
endfunction

" vim: filetype=vim
