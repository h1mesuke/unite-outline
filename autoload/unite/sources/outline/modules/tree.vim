"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-15
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

function! unite#sources#outline#modules#tree#import()
  return s:Tree
endfunction

"-----------------------------------------------------------------------------

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:Tree = unite#sources#outline#modules#base#new('Tree', s:SID)

function! s:Tree_new()
  return { 'id': 0, 'level': 0, 'children': [] }
endfunction
call s:Tree.function('new')

function! s:Tree_append_child(heading, child)
  if !has_key(a:heading, 'children')
    let a:heading.children = []
  endif
  call add(a:heading.children, a:child)
  let a:child.parent = a:heading
endfunction
call s:Tree.function('append_child')

function! s:Tree_remove_child(heading, child)
  call remove(a:heading.children, index(a:heading.children, a:child))
endfunction
call s:Tree.function('remove_child')

function! s:Tree_is_toplevel(heading)
  return !has_key(a:heading, 'parent')
endfunction
call s:Tree.function('is_toplevel')

function! s:Tree_is_leaf(heading)
  return !has_key(a:heading, 'children')
endfunction
call s:Tree.function('is_leaf')

function! s:Tree_build(headings)
  let root = s:Tree_new()
  if empty(a:headings) | return root | endif

  let context = [root] | " stack
  let prev_heading =  a:headings[0]
  for heading in a:headings
    while context[-1].level >= heading.level
      call remove(context, -1)
    endwhile
    call s:Tree_append_child(context[-1], heading)
    call add(context, heading)
  endfor
  let root = s:Tree_normalize(root)
  return root
endfunction
call s:Tree.function('build')

function! s:Tree_filter(headings, predicate, ...)
  if empty(a:headings)
    return a:headings
  endif
  let do_remove_child = (a:0 ? a:1 : 0)
  for heading in a:headings
    if s:Tree_is_toplevel(heading)
      call s:mark(heading, a:predicate, do_remove_child)
    endif
  endfor
  let filtered = filter(a:headings, 'v:val.is_marked')
  return filtered
endfunction
call s:Tree.function('filter')

function! s:mark(heading, predicate, do_remove_child)

  " NOTE: A heading is marked when it has any marked child or the given
  " predicate yields True for the heading. Marked headings will be displayed
  " at the unite.vim's buffer as the results of narrowing.

  let child_marked = 0
  if has_key(a:heading, 'children')
    for child in a:heading.children
      if !child.is_marked
        continue
      endif
      if s:mark(child, a:predicate, a:do_remove_child)
        let child_marked = 1
      elseif a:do_remove_child
        call s:Tree_remove_child(a:heading, child)
      endif
    endfor
  endif
  let a:heading.is_matched = a:predicate.call(a:heading)
  let a:heading.is_marked = (child_marked || a:heading.is_matched)
  return a:heading.is_marked
endfunction

function! s:Tree_flatten(tree)
  let headings = []
  if has_key(a:tree, 'children')
    for node in a:tree.children
      let node.level = s:Tree_is_toplevel(node) ? 1 : node.parent.level + 1
      call add(headings, node)
      let headings += s:Tree_flatten(node)
    endfor
  endif
  return headings
endfunction
call s:Tree.function('flatten')

function! s:Tree_has_marked_child(heading)
  let result = 0
  if has_key(a:heading, 'children')
    for child in a:heading.children
      if child.is_marked
        let result = 1
        break
      endif
    endfor
  endif
  return result
endfunction
call s:Tree.function('has_marked_child')

function! s:Tree_normalize(root)
  if has_key(a:root, 'children')
    " unlink the references to the root node
    for node in a:root.children
      if has_key(node, 'parent')
        unlet node.parent
      endif
    endfor
  endif
  return a:root
endfunction
call s:Tree.function('normalize')

" vim: filetype=vim
