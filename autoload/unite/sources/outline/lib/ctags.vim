"=============================================================================
" File    : autoload/unite/source/outline/lib/ctags.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-02
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

let s:CTAGS_OPTIONS = '--filter --fields=afiKmnsSzt --sort=no'

function! unite#sources#outline#lib#ctags#get_tags(ctags_opts, context)
  let path = unite#util#substitute_path_separator(a:context.buffer.path)
  let tag_lines = split(system('ctags  ' . s:CTAGS_OPTIONS . ' '. a:ctags_opts, path), "\<NL>")

  if v:shell_error
    call unite#util#print_error("unite-outline: Ctags command failed. [" . v:shell_error . "]")
    return []
  else
    return map(tag_lines, 's:create_tag(v:val, a:context)')
  endif
endfunction

function! s:create_tag(tag_line, context)
  let fields = split(a:tag_line, "\<Tab>")
  let tag = {}
  let tag.name = fields[0]
  for ext_fld in fields[3:-1]
    let [key, value] = matchlist(ext_fld, '^\([^:]\+\):\(.*\)$')[1:2]
    let tag[key] = value
  endfor
  let tag.lnum = tag.line
  let tag.line = a:context.lines[tag.lnum]
  return tag
endfunction

function! unite#sources#outline#lib#ctags#exists(...)
  let lang = (a:0 ? a:1 : 'C')
  return executable('ctags') &&
        \ split(system('ctags --version'), "\<NL>")[0] =~? '\<Exuberant Ctags\>' &&
        \ match(split(system('ctags --list-languages'), "\<NL>"), '\c' . lang) >= 0
endfunction

let s:OOP_ACCESS_MARKS = { 'public': '+', 'protected': '#', 'private': '-' }

function! unite#sources#outline#lib#ctags#get_access_mark(tag)
  let access = has_key(a:tag, 'access') ? a:tag.access : 'unknown'
  return get(s:OOP_ACCESS_MARKS, access, '_') . ' '
endfunction

" vim: filetype=vim
