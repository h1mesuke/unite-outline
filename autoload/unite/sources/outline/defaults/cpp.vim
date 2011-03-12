"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-13
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.4

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading_groups': {
      \   'MACRO': ['macro'],
      \   'TYPE' : ['class', 'enum', 'struct', 'typedef'],
      \   'PROC' : ['function'],
      \ }
      \}

function! s:outline_info.extract_headings(context)
  return unite#sources#outline#lib#ctags#extract_headings(a:context)
endfunction

function! s:outline_info.get_heading_group(heading)
  let GROUP = self.heading_group_map
  let group = get(GROUP, a:heading.type, GROUP.UNKNOWN)
  if group == GROUP.MACRO
    if matchstr(a:heading.word, '^\zs\h\w*\ze') =~# '\l'
      return GROUP.PROC
    endif
  endif
  return group
endfunction

" vim: filetype=vim
