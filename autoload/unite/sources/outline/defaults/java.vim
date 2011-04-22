"=============================================================================
" File    : autoload/unite/sources/outline/defaults/java.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-23
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Java
" Version: 0.1.1

function! unite#sources#outline#defaults#java#outline_info()
  return s:outline_info
endfunction

let s:util = unite#sources#outline#import('util')

let s:outline_info = {
      \ 'heading_groups': [
      \   ['package'],
      \   ['interface', 'class', 'enum'],
      \   ['method'],
      \ ],
      \ 'not_match_patterns': [
      \   s:util.shared_pattern('*', 'parameter_list'),
      \ ],
      \}

function! s:outline_info.extract_headings(context)
  let ctags = unite#sources#outline#import('ctags')
  return ctags.extract_headings(a:context)
endfunction

" vim: filetype=vim
