"=============================================================================
" File    : autoload/unite/filters/outline_formatter.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-09-04
" Version : 0.5.0
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
    let matches = filter(copy(a:candidates), 'v:val.source__heading.is_matched')
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
  let outline_info = a:context.outline_info
  if a:context.extract_method !=# 'filetype' ||
        \ (empty(outline_info.heading_groups) && !has_key(outline_info, 'need_blank_between'))
    return a:candidates
  endif

  if !has_key(outline_info, 'need_blank_between')
    " Use the default implementation.
    let outline_info.need_blank_between = function('s:need_blank_between')
  endif
  let candidates = []
  let prev_sibling = {} | let prev_level = 0
  let memo = {} | " for memoization
  for cand in a:candidates
    let heading = cand.source__heading
    if heading.level <= prev_level  &&
          \ outline_info.need_blank_between(prev_sibling[heading.level], heading, memo)
        call add(candidates, s:BLANK)
    endif
    call add(candidates, cand)
    let prev_sibling[heading.level] = heading
    let prev_level = heading.level
  endfor
  return candidates
endfunction

function! s:need_blank_between(head1, head2, memo) dict
  return (a:head1.group != a:head2.group ||
        \ s:Util.has_marked_child(a:head1, a:memo) ||
        \ s:Util.has_marked_child(a:head2, a:memo))
endfunction

" vim: filetype=vim
