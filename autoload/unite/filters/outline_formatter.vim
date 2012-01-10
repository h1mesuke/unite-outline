"=============================================================================
" File    : autoload/unite/filters/outline_formatter.vim
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

function! unite#filters#outline_formatter#define()
  return s:formatter
endfunction

let s:Util = unite#sources#outline#import('Util')

let s:BLANK = {
      \ 'word': '',
      \ 'source': 'outline',
      \ 'kind'  : 'common',
      \ 'is_dummy': 1,
      \ }

let s:formatter = {
      \ 'name'       : 'outline_formatter',
      \ 'description': 'view formatter for outline tree',
      \ }

function! s:formatter.filter(candidates, unite_context)
  if empty(a:candidates) | return a:candidates | endif

  let bufnr = a:unite_context.source__outline_source_bufnr
  let context = unite#sources#outline#get_outline_data(bufnr, 'context')

  " Insert blanks for readability.
  let candidates = s:insert_blanks(a:candidates, context)

  " Turbo Jump
  if len(a:candidates) < 10
    let matches = filter(copy(a:candidates), 'v:val.is_matched')
    if len(matches) == 1 " Bingo!
      let bingo = copy(matches[0])
      if bingo != a:candidates[0]
        " Prepend a copy of the only one matched heading to the narrowing
        " results for jumping to its position with one <Enter>.
        let bingo.abbr = substitute(bingo.abbr, '^ \=', '!', '')
        let candidates = [bingo, s:BLANK] + candidates
      endif
    endif
  endif
  return candidates
endfunction

function! s:insert_blanks(candidates, context)
  let oinfo = a:context.outline_info
  if a:context.extracted_by !=# 'filetype' ||
        \ (empty(oinfo.heading_groups) && !has_key(oinfo, 'need_blank_between'))
    return a:candidates
  endif

  if !has_key(oinfo, 'need_blank_between')
    " Use the default implementation.
    let oinfo.need_blank_between = function('s:need_blank_between')
  endif
  let candidates = []
  let prev_sibling = {} | let prev_level = 0
  let memo = {} | " for memoization
  for cand in a:candidates
    if cand.source__heading_level <= prev_level  &&
          \ oinfo.need_blank_between(prev_sibling[cand.source__heading_level], cand, memo)
        call add(candidates, s:BLANK)
    endif
    call add(candidates, cand)
    let prev_sibling[cand.source__heading_level] = cand
    let prev_level = cand.source__heading_level
  endfor
  return candidates
endfunction

function! s:need_blank_between(cand1, cand2, memo) dict
  return (a:cand1.source__heading_group != a:cand2.source__heading_group ||
        \ a:cand1.source__has_marked_child || a:cand2.source__has_marked_child)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
