"=============================================================================
" File    : autoload/unite/sources/outline/defaults/c.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-04
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C
" Version: 0.1.2

function! unite#sources#outline#defaults#c#outline_info()
  return s:outline_info
endfunction

let s:outline_info = copy(unite#sources#outline#get_outline_info('cpp', 1))

" TAG KINDS:
"
"  [c] classes
"  [d] macro definitions
"   e  enumerators (values inside an enumeration)
"  [f] function definitions
"  [g] enumeration names
"   l  local variables
"   m  class, struct, and union members
"  [n] namespaces
"   p  function prototypes
"  [s] structure names
"  [t] typedefs
"  [u] union names
"   v  variable definitions
"   x  external and forward variable declarations
"
function! s:outline_info.extract_headings(context)
  if !unite#sources#outline#lib#ctags#exists('C')
    call unite#util#print_error("unite-outline: Sorry, Exuberant Ctags required.")
    return []
  endif
  let ctags_opts = '--c-kinds=cdfgnstu'
  return self.extract_cpp_headings(ctags_opts, a:context)
endfunction

function! s:outline_info.need_blank(head1, head2)
  return a:head1.type !=# a:head2.type
endfunction

" vim: filetype=vim
