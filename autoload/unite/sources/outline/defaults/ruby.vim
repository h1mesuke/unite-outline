"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-15
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby
" Version: 0.0.2

function! unite#sources#outline#defaults#ruby#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\(\s*\(module\|class\|def\|BEGIN\|END\)\>\|__END__$\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:which == 'heading' && a:heading_line =~ '^\s*\(BEGIN\|END\)\>'
    return substitute(a:heading_line, '\s*{.*$', '', '')
  else
    return a:heading_line
  endif
endfunction

" vim: filetype=vim
