"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-18
" Version : 0.2.0
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

function! unite#sources#outline#util#capitalize(str, ...)
  let flag = (a:0 ? a:1 : '')
  return substitute(a:str, '\<\(\u\)\(\u\+\)\>', '\u\1\L\2', flag)
endfunction

function! unite#sources#outline#util#indent(level)
  return repeat(' ', (a:level - 1) * g:unite_source_outline_indent_width)
endfunction

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

function! s:join_to_backward(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  let idx = a:idx
  let lim_idx = max(0, a:idx - limit])
  while idx > 0
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx -= 1
  endwhile
  return join(a:lines[idx : a:idx], "\n")
endfunction

function! unite#sources#outline#util#neighbor_match(lines, idx, pattern, ...)
  let neighbor = (a:0 ? a:1 : 1)
  if type(neighbor) == type([])
    let [prev, next] = neighbor
  else
    let [prev, next] = [neighbor, neighbor]
  endif
  let neighbor_range = range(max([0, a:idx - prev]), min([a:idx + next, len(a:lines) - 1]))
  for idx in neighbor_range
    if a:lines[idx] =~ a:pattern
      return 1
    endif
  endfor
  return 0
endfunction

function! unite#sources#outline#util#neighbor_matchstr(lines, idx, pattern, ...)
  let neighbor = (a:0 ? a:1 : 1)
  if type(neighbor) == type([])
    let [prev, next] = neighbor
  else
    let [prev, next] = [neighbor, neighbor]
  endif
  let neighbor_range = range(max([0, a:idx - prev]), min([a:idx + next, len(a:lines) - 1]))
  for idx in neighbor_range
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
      \   'heading-1': '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
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

" vim: filetype=vim
