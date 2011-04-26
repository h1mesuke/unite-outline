"=============================================================================
" File    : autoload/unite/filters/outline_formatter.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-26
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

function! unite#filters#outline_formatter#define()
  return s:formatter
endfunction

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

function! s:formatter.filter(candidates, context)
  if empty(a:candidates) | return [] | endif

  let s:tree = unite#sources#outline#import('tree')
  let candidates = a:candidates

  let outline_context = a:context.source__outline_context
  let s:outline_info = outline_context.outline_info

  let do_insert_blank = has_key(s:outline_info, 'heading_groups')    ||
        \               has_key(s:outline_info, 'get_heading_group') ||
        \               has_key(s:outline_info, 'need_blank_between')

  if do_insert_blank
    let candidates = [a:candidates[0]]
    let prev_heading = a:candidates[0].source__heading

    let memo = {}
    for cand in a:candidates[1:]
      let heading = cand.source__heading
      if do_insert_blank && s:need_blank_between(prev_heading, heading, memo)
        call add(candidates, s:BLANK)
      endif
      call add(candidates, cand)
      let prev_heading = heading
    endfor
  endif
  unlet! s:outline_info

  return candidates
endfunction

function! s:need_blank_between(head1, head2, memo)
  if has_key(s:outline_info, 'need_blank_between')
    return s:outline_info.need_blank_between(a:head1, a:head2)
  elseif a:head1.level < a:head2.level
    return 0
  elseif a:head1.level == a:head2.level
    if has_key(s:outline_info, 'get_heading_group')
      let group1 = s:outline_info.get_heading_group(a:head1)
      let group2 = s:outline_info.get_heading_group(a:head2)
    else
      let group1 = s:get_heading_group(a:head1)
      let group2 = s:get_heading_group(a:head2)
    endif
    return (group1 != group2 ||
          \ s:tree.has_marked_child(a:head1, a:memo) ||
          \ s:tree.has_marked_child(a:head2, a:memo))
  else
    return 1
  endif
endfunction

function! s:get_heading_group(heading)
  let group_map = s:outline_info.heading_group_map
  return  get(group_map, a:heading.type, 0)
endfunction

" vim: filetype=vim
