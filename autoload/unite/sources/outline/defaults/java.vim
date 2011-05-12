"=============================================================================
" File    : autoload/unite/sources/outline/defaults/java.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Java
" Version: 0.1.2

function! unite#sources#outline#defaults#java#outline_info()
  return s:outline_info
endfunction

let s:Ctags = unite#sources#outline#import('Ctags')
let s:Util  = unite#sources#outline#import('Util')

let s:outline_info = {
      \ 'heading_groups': {
      \   'package': ['package'],
      \   'type'   : ['interface', 'class', 'enum'],
      \   'method' : ['method'],
      \ },
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \}

function! s:outline_info.extract_headings(context)
  return s:Ctags.extract_headings(a:context)
endfunction

" vim: filetype=vim
