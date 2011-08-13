"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-13
" Version : 0.3.6
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
  return { '__root__': 1, 'id': 0, 'level': 0, 'children': [] }
endfunction
call s:Tree.function('new')

function! s:Tree_get_root(node)
  let node = a:node
  while 1
    if has_key(node.parent, '__root__')
      return node.parent
    endif
    let node = node.parent
  endwhile
endfunction
call s:Tree.function('get_root')

function! s:Tree_append_child(node, child)
  if !has_key(a:node, 'children')
    let a:node.children = []
  endif
  call add(a:node.children, a:child)
  let a:child.parent = a:node
  " Ensure that all headings has 'children'.
  if !has_key(a:child, 'children')
    let a:child.children = []
  endif
endfunction
call s:Tree.function('append_child')

function! s:Tree_remove_child(node, child)
  call remove(a:node.children, index(a:node.children, a:child))
endfunction
call s:Tree.function('remove_child')

function! s:Tree_is_toplevel(node)
  return has_key(a:node.parent, '__root__')
endfunction
call s:Tree.function('is_toplevel')

function! s:Tree_is_leaf(node)
  return empty(a:node.children)
endfunction
call s:Tree.function('is_leaf')

" Builds the tree structure from a list of headings and then returns the root
" node of the tree.
"
function! s:Tree_build(headings, ...)
  let root = s:Tree_new()
  if empty(a:headings) | return root | endif

  " Ensure that all headings has 'children'.
  for heading in a:headings
    let heading.children = []
  endfor

  let context = [root] | " stack
  let prev_heading =  a:headings[0]
  for heading in a:headings
    while context[-1].level >= heading.level
      call remove(context, -1)
    endwhile
    call s:Tree_append_child(context[-1], heading)
    call add(context, heading)
  endfor
  return root
endfunction
call s:Tree.function('build')

" Flatten a tree into a List.
"
" NOTE: This function resets heading levels in accordance with the given
" tree's structure while flattening it.
"
"   1               1
"   +--3            +--2
"   |  +--5   =>    |  +--3
"   |  +--4         |  +--3 
"
function! s:Tree_flatten(node)
  let headings = []
  for child in a:node.children
    let child.level = a:node.level + 1
    call add(headings, child)
    let headings += s:Tree_flatten(child)
  endfor
  return headings
endfunction
call s:Tree.function('flatten')

" Marks nodes using {predicate}.
"
" A node is marked when it has any marked child or for which {predicate}
" returns True.
"
function! s:Tree_mark(node, predicate)
  let child_marked = 0
  for child in a:node.children
    if !child.is_marked
      continue
    endif
    let child.is_matched = a:predicate.call(child)
    let child.is_marked = (s:Tree_mark(child, a:predicate) || child.is_matched)
    if child.is_marked
      let child_marked = 1
    endif
  endfor
  return child_marked
endfunction
call s:Tree.function('mark')

function! s:Tree_has_marked_child(node)
  for child in a:node.children
    if child.is_marked
      return 1
    endif
  endfor
  return 0
endfunction
call s:Tree.function('has_marked_child')

" Remove nodes for which {predicate} returns True WITH their children.
"
function! s:Tree_remove(node, predicate, ...)
  for child in a:node.children
    if a:predicate.call(child)
      call s:Tree_remove_child(a:node, child)
      continue
    endif
    call s:Tree_remove(child, a:predicate)
  endfor
endfunction
call s:Tree.function('remove')

" vim: filetype=vim
