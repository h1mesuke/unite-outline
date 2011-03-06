"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-06
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.3

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {}

function! s:outline_info.extract_headings(context)
  return unite#sources#outline#lib#ctags#extract_headings(a:context)
endfunction

function! s:init_heading_group_map(spec_dict)
  let s:HEADING_GROUP = { 'UNKNOWN': 0 }
  let s:HEADING_GROUP_MAP = {}
  let group_id = 1
  for group_name in keys(a:spec_dict)
    let s:HEADING_GROUP[group_name] = group_id
    for heading_type in a:spec_dict[group_name]
      let s:HEADING_GROUP_MAP[heading_type] = group_id
    endfor
    let group_id += 1
  endfor
endfunction
call s:init_heading_group_map({
      \ 'MACRO': ['macro'],
      \ 'TYPE' : ['class', 'enum', 'struct', 'typedef'],
      \ 'PROC' : ['function'],
      \ })

function! s:get_heading_group(heading)
  return  get(s:HEADING_GROUP_MAP, a:heading.type, s:HEADING_GROUP.UNKNOWN)
endfunction

function! s:outline_info.need_blank(head1, head2)
  if a:head1.level < a:head2.level
    return 0
  elseif a:head1.level == a:head2.level
    return (s:get_heading_group(a:head1) != s:get_heading_group(a:head2) ||
          \ has_key(a:head1, 'children') || has_key(a:head2, 'children'))
  else
    return 1
  endif
endfunction

" vim: filetype=vim
