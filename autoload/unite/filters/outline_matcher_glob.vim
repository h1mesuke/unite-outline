"=============================================================================
" File    : autoload/unite/filters/outline_matcher_glob.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-11
" Version : 0.3.5
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
function! s:matcher.filter(candidates, context)
  let headings = map(copy(a:candidates), 'v:val.source__heading')
  for heading in headings
    let heading.is_marked  = 1
    let heading.is_matched = 0
  endfor
  if a:context.input == ''
    let g:unite_source_outline_input = ''
    return a:candidates
  elseif empty(a:candidates)
    return a:candidates
  endif

  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(input, '\\ ', ' ', 'g')

    " something like closure
    let predicate = {}

    if input =~ '^!'
      " Exclusion
      let predicate.input = unite#escape_match(input)
      let g:unite_source_outline_input = ''
      function predicate.call(heading)
        return (a:heading.keyword !~ self.input[1:])
      endfunction
    elseif input =~ '\\\@<!\*'
      " Wildcard
      let predicate.input = unite#escape_match(input)
      let g:unite_source_outline_input = predicate.input
      function predicate.call(heading)
        return (a:heading.keyword =~ self.input)
      endfunction
    else
      let predicate.input = substitute(input, '\\\(.\)', '\1', 'g')
      let g:unite_source_outline_input = predicate.input
      if &ignorecase
        function predicate.call(heading)
          return (stridx(tolower(a:heading.keyword), self.input) != -1)
        endfunction
      else
        function predicate.call(heading)
          return (stridx(a:heading.keyword, self.input) != -1)
        endfunction
      endif
    endif
    let headings = s:Tree.filter(headings, predicate)
  endfor
  let candidates = map(headings, 'v:val.__unite_candidate__')
  return candidates
endfunction

" vim: filetype=vim
