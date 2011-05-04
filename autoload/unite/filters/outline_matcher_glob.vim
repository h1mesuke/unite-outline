"=============================================================================
" File    : autoload/unite/filters/outline_matcher_glob.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-05
" Version : 0.3.4
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
  for cand in a:candidates
    let cand.source__is_marked  = 1
    let cand.source__is_matched = 0
  endfor
  if a:context.input == ''
    let g:unite_source_outline_input = ''
    return a:candidates
  endif

  let candidates = copy(a:candidates)

  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(input, '\\ ', ' ', 'g')

    " something like closure
    let pred = {}

    if input =~ '^!'
      " exclusion
      let pred.input = unite#escape_match(input)
      let g:unite_source_outline_input = ''
      function pred.call(cand)
        return (a:cand.word !~ self.input[1:])
      endfunction
    elseif input =~ '\\\@<!\*'
      " wildcard
      let pred.input = unite#escape_match(input)
      let g:unite_source_outline_input = pred.input
      function pred.call(cand)
        return (a:cand.word =~ self.input)
      endfunction
    else
      let pred.input = substitute(input, '\\\(.\)', '\1', 'g')
      let g:unite_source_outline_input = pred.input
      if &ignorecase
        function pred.call(cand)
          return (stridx(tolower(a:cand.word), self.input) != -1)
        endfunction
      else
        function pred.call(cand)
          return (stridx(a:cand.word, self.input) != -1)
        endfunction
      endif
    endif
    let candidates = s:Tree.filter(candidates, pred)
  endfor

  return candidates
endfunction

" vim: filetype=vim
