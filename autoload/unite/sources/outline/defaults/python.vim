"=============================================================================
" File    : autoload/unite/sources/outline/defaults/python.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Python
" Version: 0.1.5

function! unite#sources#outline#defaults#python#outline_info()
  return s:outline_info
endfunction

let s:Ctags = unite#sources#outline#import('Ctags')
let s:Util  = unite#sources#outline#import('Util')

let s:outline_info = {
      \ 'heading_groups': {
      \   'type'     : ['class'],
      \   'function' : ['function', 'member'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'   : 'type',
      \     'pattern': '/.*\ze : class/' },
      \   { 'name'   : 'function',
      \     'pattern': '/\h\w*\ze\s*(/' },
      \   { 'name'   : 'parameter_list',
      \     'pattern': '/(.*)/' },
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
      " Don't insert a blank between two headings of functions.
      return 0
    else
      return (a:head1.group != a:head2.group ||
            \ s:Util.has_marked_child(a:head1, a:memo) ||
            \ s:Util.has_marked_child(a:head2, a:memo))
    endif
  else " if a:head1.level > a:head2.level
    return 1
  endif
endfunction

" vim: filetype=vim
