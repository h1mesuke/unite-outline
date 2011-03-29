"=============================================================================
" File    : autoload/unite/filters/outline_matcher_glob_tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-29
" Version : 0.3.3
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

function! unite#filters#outline_matcher_glob_tree#define()
  return s:matcher
endfunction

let s:matcher = {
      \ 'name'       : 'outline_matcher_glob_tree',
      \ 'description': 'glob matcher for outline tree',
      \ }

" Derived from:
" unite/autoload/filters/matcher_glob.vim
"
function! s:matcher.filter(candidates, context)
  if a:context.input == ''
    return a:candidates
  endif

  let tree = unite#sources#outline#import('tree')

  let candidates = copy(a:candidates)

  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(input, '\\ ', ' ', 'g')

    " something like closure
    let pred = {}

    if input =~ '^!'
      " exclusion
      let pred.input = unite#escape_match(input)
      function pred.call(cand)
        return (a:cand.word !~ self.input[1:])
      endfunction
    elseif input =~ '\\\@<!\*'
      " wildcard
      let pred.input = unite#escape_match(input)
      function pred.call(cand)
        return (a:cand.word =~ self.input)
      endfunction
    else
      let pred.input = substitute(input, '\\\(.\)', '\1', 'g')
      if &ignorecase
        function pred.call(cand)
          return (stridx(tolower(a:cand.word), self.input) != -1)
        endfunction
      else
        function pred.call(cand)
          return (stridx(a:cand.word, self.input) != -1)
        endfunction
      endif

      let candidates = tree.filter(candidates, pred)
    endif
  endfor

  return candidates
endfunction

" vim: filetype=vim
