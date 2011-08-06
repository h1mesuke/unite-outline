"=============================================================================
" File    : autoload/unite/sources/outline/defaults/python.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-06
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Python
" Version: 0.1.2

function! unite#sources#outline#defaults#python#outline_info()
  return s:outline_info
endfunction

let s:Ctags = unite#sources#outline#import('Ctags')
let s:Tree  = unite#sources#outline#import('Tree')
let s:Util  = unite#sources#outline#import('Util')

let s:outline_info = {
      \ 'heading_groups': {
      \   'type'     : ['class'],
      \   'function' : ['function', 'member'],
      \ },
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \}

function! s:outline_info.extract_headings(context)
  return s:Ctags.extract_headings(a:context)
endfunction

function! s:outline_info.need_blank_between(head1, head2, memo)
  if a:head1.level < a:head2.level
    return 0
  elseif a:head1.level == a:head2.level
    if a:head1.group == 'function' && a:head2.group == 'function'
      " Don't insert a blank line above a heading of a nested function.
      return 0
    else
      return (a:head1.group != a:head2.group ||
            \ s:has_marked_child(a:head1, a:memo) ||
            \ s:has_marked_child(a:head2, a:memo))
    endif
  else " if a:head1.level > a:head2.level
    return 1
  endif
endfunction

function! s:has_marked_child(heading, memo)
  if has_key(a:memo, a:heading.id)
    return a:memo[a:heading.id]
  endif
  let result = s:Tree.has_marked_child(a:heading)
  let a:memo[a:heading.id] = result
  return result
endfunction

" vim: filetype=vim
