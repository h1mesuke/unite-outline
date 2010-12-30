"=============================================================================
" File    : autoload/unite/source/outline/_cache.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-31
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

function! unite#sources#outline#_cache#instance()
  return s:cache
endfunction

" singleton
let s:cache = { 'data': {} }

function! s:cache.has_data(path)
  return has_key(self.data, a:path)
endfunction

function! s:cache.get_data(path)
  let item = self.data[a:path]
  let item.touched = localtime()
  return item.candidates
endfunction

function! s:cache.set_data(path, cands)
  let self.data[a:path] = {
        \ 'candidates': a:cands,
        \ 'touched'   : localtime(),
        \ }
  if len(self.data) > g:unite_source_outline_cache_buffers
    let oldest = sort(items(self.data), 's:compare_timestamp')[0]
    unlet self.data[oldest[0]]
  endif
endfunction

function! s:compare_timestamp(item1, item2)
  let t1 = a:item1[1].touched
  let t2 = a:item2[1].touched
  return t1 == t2 ? 0 : t1 > t2 ? 1 : -1
endfunction

" vim: filetype=vim
