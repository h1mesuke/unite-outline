"=============================================================================
" File    : autoload/unite/filters/outline_matcher_glob.vim
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

function! unite#filters#outline_matcher_glob#define()
  return s:matcher
endfunction

let s:Tree = unite#sources#outline#import('Tree')

let s:matcher = {
      \ 'name'       : 'outline_matcher_glob',
      \ 'description': 'glob matcher for outline tree',
      \ }

" Derived from:
" unite/autoload/filters/matcher_glob.vim
"
function! s:matcher.filter(candidates, unite_context)
  if empty(a:candidates) | return a:candidates | endif

  call s:Tree.List.reset_marks(a:candidates)

  if a:unite_context.input == ''
    return a:candidates
  endif

  for input in split(a:unite_context.input, '\\\@<! ')
    let input = substitute(input, '\\ ', ' ', 'g')
    if input =~ '^!'
      if input == '!'
        continue
      endif
      " Exclusion
      let input = unite#escape_match(input)
      let pred = 'v:val.word !~ ' . string(input[1:])
    elseif input =~ '\\\@<!\*'
      " Wildcard
      let input = unite#escape_match(input)
      let pred = 'v:val.word =~ ' . string(input)
    else
      let input = substitute(input, '\\\(.\)', '\1', 'g')
      let pred = &ignorecase ?
            \ printf('stridx(tolower(v:val.word), %s) != -1', string(tolower(input))) :
            \ printf('stridx(v:val.word, %s) != -1', string(input))
    endif
    " Mark headings.
    call s:Tree.List.mark(a:candidates, pred)
  endfor

  " Filter headings.
  let candidates = filter(copy(a:candidates), 'v:val.source__is_marked')
  return candidates
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
