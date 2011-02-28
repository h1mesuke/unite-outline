"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-28
" Version : 0.3.1
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

"-----------------------------------------------------------------------------
" Indent

function! unite#sources#outline#util#get_indent_level(context, lnum)
  let line = a:context.lines[a:lnum]
  let sw = a:context.buffer.shiftwidth
  let ts = a:context.buffer.tabstop
  let indent = substitute(matchstr(line, '^\s*'), '\t', repeat(' ', ts), 'g')
  return strlen(indent) / sw + 1
endfunction

function! unite#sources#outline#util#get_comment_heading_level(context, lnum, ...)
  let line = a:context.lines[a:lnum]
  if line =~ '^\s'
    let level =  (a:0 ? a:1 : unite#sources#outline#util#get_indent_level(a:context, a:lnum) + 3)
  else
    let level = (strlen(substitute(line, '\s*', '', 'g')) > 40 ? 2 : 3)
    let level -= (line =~ '=')
  endif
  return level
endfunction

"-----------------------------------------------------------------------------
" Matching

" unite#sources#outline#util#join_to( {context}, {lnum}, {pattern} [, {limit}])
"
function! unite#sources#outline#util#join_to(context, lnum, pattern, ...)
  let lines = a:context.lines
  let limit = (a:0 ? a:1 : 3)
  if limit < 0
    return s:join_to_backward(lines, a:lnum, a:pattern, limit * -1)
  endif
  let lnum = a:lnum
  let limit = min([a:lnum + limit, len(lines) - 1])
  while lnum <= limit
    let line = lines[lnum]
    if line =~# a:pattern
      break
    endif
    let lnum += 1
  endwhile
  return join(lines[a:lnum : lnum], "\n")
endfunction

function! s:join_to_backward(context, lnum, pattern, limit)
  let lines = a:context.lines
  let limit = max(1, a:lnum - a:limit])
  while lnum > 0
    let line = lines[lnum]
    if line =~# a:pattern
      break
    endif
    let lnum -= 1
  endwhile
  return join(lines[lnum : a:lnum], "\n")
endfunction

function! unite#sources#outline#util#join_to_rparen(context, lnum, ...)
  let limit = (a:0 ? a:1 : 3)
  let line = unite#sources#outline#util#join_to(a:context, a:lnum, ')', limit)
  let line = substitute(line, "\\s*\n\\s*", ' ', 'g')
  let line = substitute(line, ')\zs.*$', '', '')
  return line
endfunction

" unite#sources#outline#util#neighbor_match(
"   {context}, {lnum}, {pattern} [, {range} [, {exclusive}])
"
function! unite#sources#outline#util#neighbor_match(context, lnum, pattern, ...)
  let lines = a:context.lines
  let range = get(a:000, 0, 1)
  let exclusive = !!get(a:000, 1, 0)
  if type(range) == type([])
    let [prev, next] = range
  else
    let [prev, next] = [range, range]
  endif
  let [bwd_range, fwd_range] = s:neighbor_ranges(a:context, a:lnum, prev, next, exclusive)
  for lnum in bwd_range
    if lines[lnum] =~# a:pattern
      return 1
    endif
  endfor
  for lnum in fwd_range
    if lines[lnum] =~# a:pattern
      return 1
    endif
  endfor
  return 0
endfunction

function! s:neighbor_ranges(context, lnum, prev, next, exclusive)
  let max_lnum = len(a:context.lines) - 1
  let bwd_range = range(max([1, a:lnum - a:prev]), max([1, a:lnum - a:exclusive]))
  let fwd_range = range(min([a:lnum + a:exclusive, max_lnum]), min([a:lnum + a:next, max_lnum]))
  return [bwd_range, fwd_range]
endfunction

" unite#sources#outline#util#neighbor_matchstr(
"   {context}, {lnum}, {pattern} [, {range} [, {exclusive}])
"
function! unite#sources#outline#util#neighbor_matchstr(context, lnum, pattern, ...)
  let lines = a:context.lines
  let range = get(a:000, 0, 1)
  let exclusive = !!get(a:000, 1, 0)
  if type(range) == type([])
    let [prev, next] = range
  else
    let [prev, next] = [range, range]
  endif
  let [bwd_range, fwd_range] = s:neighbor_ranges(a:context, a:lnum, prev, next, exclusive)
  for lnum in bwd_range
    let matched = matchstr(lines[lnum], a:pattern)
    if matched != ""
      return matched
    endif
  endfor
  for lnum in fwd_range
    let matched = matchstr(lines[lnum], a:pattern)
    if matched != ""
      return matched
    endif
  endfor
  return ""
endfunction

let s:shared_patterns = {
      \ 'c': {
      \   'heading-1': '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \   'header'   : ['^/\*', '\*/\s*$'],
      \ },
      \ 'cpp': {
      \   'heading-1': '^\s*/[/*]\s*[-=/*]\{10,}\s*$',
      \   'header'   : {
      \     'leading': '^//',
      \     'block'  : ['^/\*', '\*/\s*$'],
      \   },
      \ },
      \ 'sh': {
      \   'heading-1': '^\s*#\s*[-=#]\{10,}\s*$',
      \   'header'   : '^#',
      \ },
      \}

function! unite#sources#outline#util#shared_pattern(filetype, which)
  return s:shared_patterns[a:filetype][a:which]
endfunction

"-----------------------------------------------------------------------------
" String

" unite#sources#outline#util#capitalize( {str} [, {flag}])
"
function! unite#sources#outline#util#capitalize(str, ...)
  let flag = (a:0 ? a:1 : '')
  return substitute(a:str, '\<\(\u\)\(\u\+\)\>', '\u\1\L\2', flag)
endfunction

" ported from:
" Sample code from Programing Ruby, page 145
"
function! unite#sources#outline#util#nr2roman(nr)
  if a:nr <= 0 || 4999 < a:nr
    return string(a:nr)
  endif
  let factors = [
        \ ["M", 1000], ["CM", 900], ["D",  500], ["CD", 400],
        \ ["C",  100], ["XC",  90], ["L",   50], ["XL",  40],
        \ ["X",   10], ["IX",   9], ["V",    5], ["IV",   4],
        \ ["I",    1],
        \]
  let nr = a:nr
  let roman = ""
  for [code, factor] in factors
    let cnt = nr / factor
    let nr  = nr % factor
    if cnt > 0
      let roman .= repeat(code, cnt)
    endif
  endfor
  return roman
endfunction

"-----------------------------------------------------------------------------
" Tags

let s:CTAGS_OPTIONS = '--filter --fields=afiKmnsSzt --sort=no '

function! unite#sources#outline#util#get_tags(ctags_opts, context)
  let path = unite#util#substitute_path_separator(a:context.buffer.path)
  let tag_lines = split(system('ctags  ' . s:CTAGS_OPTIONS . a:ctags_opts, path), "\<NL>")

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

function! unite#sources#outline#util#has_exuberant_ctags()
  return executable('ctags') && split(system('ctags --version'), "\<NL>")[0] =~? '\<exuberant\>'
endfunction

let s:OOP_ACCESS_MARKS = { 'public': '+', 'protected': '#', 'private': '-' }

function! unite#sources#outline#util#get_access_mark(tag)
  let access = has_key(a:tag, 'access') ? a:tag.access : 'unknown'
  return get(s:OOP_ACCESS_MARKS, access, '_') . ' '
endfunction

"-----------------------------------------------------------------------------
" Misc

function! unite#sources#outline#util#print_debug(msg)
  if exists('g:unite_source_outline_debug') && g:unite_source_outline_debug
    echomsg "unite-outline: " . a:msg
  endif
endfunction

function! unite#sources#outline#util#_c_normalize_define_macro_heading_word(heading_word)
  let heading_word = substitute(a:heading_word, '#\s*define', '#define', '')
  let heading_word = substitute(heading_word, ')\zs.*$', '', '')
  return heading_word
endfunction

function! unite#sources#outline#util#_cpp_is_in_comment(heading_line, matched_line)
  return ((a:matched_line =~ '^\s*//'  && a:heading_line =~ '^\s*//') ||
        \ (a:matched_line =~ '^\s*/\*' && a:matched_line !~ '\*/\s*$'))
endfunction

" vim: filetype=vim
