"=============================================================================
" File    : autoload/unite/sources/outline/defaults/perl.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-16
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Perl
" Version: 0.0.2

function! unite#sources#outline#defaults#perl#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\(\s*\(sub\s\+\h\|\(package\|BEGIN\|CHECK\|INIT\|END\)\>\)\|__\(DATA\|END\)__$\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('sh', 'header'),
      \   'block' : ['^=\(cut\)\@!\w\+', '^=cut'],
      \ },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:heading_line =~ '^\s*package\>'
    return substitute(a:heading_line, ';\s*$', '', '')
  else
    return substitute(a:heading_line, '\s*{.*$', '', '')
  endif
endfunction

" vim: filetype=vim
