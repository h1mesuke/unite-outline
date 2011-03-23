"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-24
" Version : 0.3.2
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"   
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"   
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:Util = unite#sources#outline#get_module('Util')

" NOTE: All of the functions in this file are obsolete now. If you need to use
" any of them, please import Util module and call them via the module as
" Dictionary functions.

"-----------------------------------------------------------------------------
" Headings

function! unite#sources#outline#util#get_indent_level(...)
  return call(s:Util.get_indent_level, a:000)
endfunction

function! unite#sources#outline#util#get_comment_heading_level(...)
  return call(s:Util.get_comment_heading_level, a:000)
endfunction

"-----------------------------------------------------------------------------
" Matching

function! unite#sources#outline#util#join_to(...)
  return call(s:Util.join_to, a:000)
endfunction

function! unite#sources#outline#util#join_to_rparen(...)
  return call(s:Util.join_to_rparen, a:000)
endfunction

function! unite#sources#outline#util#neighbor_match(...)
  return call(s:Util.neighbor_match, a:000)
endfunction

function! unite#sources#outline#util#neighbor_matchstr(...)
  return call(s:Util.neighbor_matchstr, a:000)
endfunction

function! unite#sources#outline#util#shared_pattern(...)
  return call(s:Util.shared_pattern, a:000)
endfunction

"-----------------------------------------------------------------------------
" Path

function! unite#sources#outline#util#normalize_path(...)
  return call(s:Util.normalize_path, a:000)
endfunction

"-----------------------------------------------------------------------------
" Strings

function! unite#sources#outline#util#capitalize(...)
  return call(s:Util.capitalize, a:000)
endfunction

function! unite#sources#outline#util#nr2roman(...)
  return call(s:Util.nr2roman, a:000)
endfunction

function! unite#sources#outline#util#shellescape(...)
  return call(s:Util.shellescape, a:000)
endfunction

"-----------------------------------------------------------------------------
" Misc

function! unite#sources#outline#util#print_debug(...)
  return call(s:Util.print_debug, a:000)
endfunction

function! unite#sources#outline#util#print_progress(...)
  return call(s:Util.print_progress, a:000)
endfunction

function! unite#sources#outline#util#sort_by_lnum(...)
  return call(s:Util.sort_by_lnum, a:000)
endfunction

function! unite#sources#outline#util#_cpp_is_in_comment(...)
  return call(s:Util._cpp_is_in_comment, a:000)
endfunction

" vim: filetype=vim
