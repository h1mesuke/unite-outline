"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-28
" Version : 0.3.0
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

" unite#sources#outline#util#capitalize(str [, flag])
function! unite#sources#outline#util#capitalize(str, ...)
  let flag = (a:0 ? a:1 : '')
  return substitute(a:str, '\<\(\u\)\(\u\+\)\>', '\u\1\L\2', flag)
endfunction

function! unite#sources#outline#util#get_comment_heading_level(line, context)
  if a:line =~ '^\s'
    let level =  (type(a:context) == type({})
          \ ? unite#sources#outline#util#get_indent_level(a:line, a:context) + 3
          \ : a:context)
  else
    let level = (strlen(substitute(a:line, '\s*', '', 'g')) > 40 ? 2 : 3)
    let level -= (a:line =~ '=')
  endif
  return level
endfunction

function! unite#sources#outline#util#get_indent_level(line, context)
  let sw = a:context.buffer.shiftwidth
  let ts = a:context.buffer.tabstop
  let indent = substitute(matchstr(a:line, '^\s*'), '\t', repeat(' ', ts), 'g')
  return strlen(indent) / sw + 1
endfunction

" function! unite#sources#outline#util#indent(str, level)
" function! unite#sources#outline#util#indent(level)
function! unite#sources#outline#util#indent(...)
  let level = get(a:000, -1, 1)
  let indent = repeat(' ', (level - 1) * g:unite_source_outline_indent_width)
  if len(a:000) >= 2
    return indent . a:000[0]
  else
    " for backward compatibility
    return indent
  endif
endfunction

" unite#sources#outline#util#join_to(lines, idx, pattern [, limit])
function! unite#sources#outline#util#join_to(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  if limit < 0
    return s:join_to_backward(a:lines, a:idx, a:pattern, limit * -1)
  endif
  let idx = a:idx
  let lim_idx = min([a:idx + limit, len(a:lines) - 1])
  while idx <= lim_idx
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx += 1
  endwhile
  return join(a:lines[a:idx : idx], "\n")
endfunction

function! s:join_to_backward(lines, idx, pattern, limit)
  let idx = a:idx
  let lim_idx = max(0, a:idx - a:limit])
  while idx > 0
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx -= 1
  endwhile
  return join(a:lines[idx : a:idx], "\n")
endfunction

" unite#sources#outline#util#neighbor_match(lines, idx, pattern [, range [, exclusive])
function! unite#sources#outline#util#neighbor_match(lines, idx, pattern, ...)
  let range = get(a:000, 0, 1)
  let exclusive = !!get(a:000, 1, 0)
  if type(range) == type([])
    let [prev, next] = range
  else
    let [prev, next] = [range, range]
  endif
  let [bwd_range, fwd_range] = s:neighbor_ranges(a:lines, a:idx, prev, next, exclusive)
  for idx in bwd_range
    if a:lines[idx] =~ a:pattern
      return 1
    endif
  endfor
  for idx in fwd_range
    if a:lines[idx] =~ a:pattern
      return 1
    endif
  endfor
  return 0
endfunction

function! s:neighbor_ranges(lines, idx, prev, next, exclusive)
  let max_idx = len(a:lines) - 1
  let bwd_range = range(max([0, a:idx - a:prev]), max([0, a:idx - a:exclusive]))
  let fwd_range = range(min([a:idx + a:exclusive, max_idx]), min([a:idx + a:next, max_idx]))
  return [bwd_range, fwd_range]
endfunction

" unite#sources#outline#util#neighbor_matchstr(lines, idx, pattern [, range [, exclusive])
function! unite#sources#outline#util#neighbor_matchstr(lines, idx, pattern, ...)
  let range = get(a:000, 0, 1)
  let exclusive = !!get(a:000, 1, 0)
  if type(range) == type([])
    let [prev, next] = range
  else
    let [prev, next] = [range, range]
  endif
  let [bwd_range, fwd_range] = s:neighbor_ranges(a:lines, a:idx, prev, next, exclusive)
  for idx in bwd_range
    let matched = matchstr(a:lines[idx], a:pattern)
    if matched != ""
      return matched
    endif
  endfor
  for idx in fwd_range
    let matched = matchstr(a:lines[idx], a:pattern)
    if matched != ""
      return matched
    endif
  endfor
  return ""
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
  let ft_patterns = s:shared_patterns[a:filetype]
  return ft_patterns[a:which]
endfunction

function! unite#sources#outline#util#print_debug(msg)
  if exists('g:unite_source_outline_debug') && g:unite_source_outline_debug
    echomsg "unite-outline: " . a:msg
  endif
endfunction

" vim: filetype=vim
