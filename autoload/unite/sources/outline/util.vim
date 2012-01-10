"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
" Version : 0.5.1
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

let s:save_cpo = &cpo
set cpo&vim

let s:Util = unite#sources#outline#import('Util')

" NOTE: All of the functions in this file are obsolete now. If you need any of
" them, please import Util module and call them as Dictionary functions.

"-----------------------------------------------------------------------------
" Heading

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
  return call(s:Util.Path.normalize, a:000)
endfunction

"-----------------------------------------------------------------------------
" String

function! unite#sources#outline#util#capitalize(...)
  return call(s:Util.String.capitalize, a:000)
endfunction

function! unite#sources#outline#util#nr2roman(...)
  return call(s:Util.String.nr2roman, a:000)
endfunction

function! unite#sources#outline#util#shellescape(...)
  return call(s:Util.String.shellescape, a:000)
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
  return call(s:Util.List.sort_by_lnum, a:000)
endfunction

function! unite#sources#outline#util#_cpp_is_in_comment(...)
  return call(s:Util._cpp_is_in_comment, a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
