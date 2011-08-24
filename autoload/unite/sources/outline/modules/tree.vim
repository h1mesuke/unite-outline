"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-21
" Version : 0.3.8
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

" Tree module provides functions to build, to handle, to filter a tree
" structure.
"
" You can build a tree from a List, elements of which are Dictionaries with
" `level' attribute, using Tree.build() function. Or, you can also do it one
" node by one node manually using Tree.new() and Tree.append_child()
" functions.
"
" The following example show how to build a tree in the latter way.
"
" == Example
"
"   let s:Tree = unite#sources#outline#import('Tree')
"   
"   let root = s:Tree.new()
"   call s:Tree.append_child(root, heading_A)
"   call s:Tree.append_child(root, heading_B)
"   call s:Tree.append_child(heading_A, heading_1)
"   call s:Tree.append_child(heading_A, heading_2)
"   call s:Tree.append_child(heading_B, heading_3)
"
"     |/
"
"   root
"    |
"    +--heading_A
"    |   +--heading_1
"    |   +--heading_2
"    |
"    +--heading_B
"        +--heading_3
"
let s:Tree = unite#sources#outline#modules#base#new('Tree', s:SID)

" Creates a new root node.
"
function! s:Tree_new()
  return { '__root__': 1, 'id': 0, 'level': 0, 'children': [] }
endfunction
call s:Tree.function('new')

" Returns the root node of the tree to which {node} belongs.
"
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

" Append {child} to a List of children of {node}.
" The parent of {child} is set to {node}.
"
function! s:Tree_append_child(node, child)
  if !has_key(a:node, 'children')
    let a:node.children = []
  endif
  call add(a:node.children, a:child)
  let a:child.parent = a:node
  " Ensure that all nodes have 'children'.
  if !has_key(a:child, 'children')
    let a:child.children = []
    " NOTE: While building a tree, all nodes of the tree pass through this
    " function as a:child.
  endif
endfunction
call s:Tree.function('append_child')

" Remove {child} from a List of children of {node}.
"
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

" Builds a tree structure from a List of elements, which are Dictionaries with
" `level' attribute, and then returns the root node of the built tree.
"
" NOTE: This function allows discontinuous levels and build a tree from such
" a sequence of levels as shown below:
"
"                             root
"                              |
"                              +--1
"   [1, 3, 5, 5, 2, ...]  =>   |  +--3
"                              |  |  +--5
"                              |  |  +--5
"                              |  |
"                              :  +--2
"
" Tree.flatten() function can corrects these discontinuous levels.
"
function! s:Tree_build(elems)
  let root = s:Tree_new()
  if empty(a:elems) | return root | endif
  " Build a tree.
  let stack = [root]
  for elem in a:elems
    " Forget about the current children...
    let elem.children = []
    " Make the top of the stack point to the parent.
    while elem.level <= stack[-1].level
      call remove(stack, -1)
    endwhile
    call s:Tree_append_child(stack[-1], elem)
    call add(stack, elem)
  endfor
  return root
endfunction
call s:Tree.function('build')

" Flatten a tree into a List.
"
" NOTE: This function also corrects the level of nodes in accordance with the
" given tree's structure while flattening it.
"
"   root             root
"    |                |
"    +--1             +--1
"    |  +--3          |  +--2
"    |  |  +--5  =>   |  |  +--3  =>  [1, 2, 3, 3, 2, ...]
"    |  |  +--5       |  |  +--3
"    |  |             |  |
"    :  +--2          :  +--2
"
function! s:Tree_flatten(node)
  let nodes = []
  for child in a:node.children
    let child.level = a:node.level + 1
    call add(nodes, child)
    let nodes += s:Tree_flatten(child)
  endfor
  return nodes
endfunction
call s:Tree.function('flatten')

" Marks nodes for which or one of whose children {predicate} returns True.
"
" * A node is matched for which {predicate} returns True.
" * A node is marked when it has any marked child or is matched.
"
" NOTE: unite-outline's matcher see these flags to accomplish its tree-aware
" filtering task.
"
function! s:Tree_match(node, predicate, ...)
  let and = (a:0 ? a:1 : 0)
  if !and
    call s:init_marks(a:node)
  endif
  let child_marked = 0
  for child in a:node.children
    if !child.is_marked
      continue
    endif
    let child.is_matched = child.is_matched && a:predicate.call(child)
    let child.is_marked = (s:Tree_match(child, a:predicate, 1) || child.is_matched)
    if child.is_marked
      let child_marked = 1
    endif
  endfor
  return child_marked
endfunction
call s:Tree.function('match')

function! s:init_marks(node)
  for child in a:node.children
    let child.is_marked  = 1
    let child.is_matched = 1
    call s:init_marks(child)
  endfor
endfunction

function! s:Tree_has_marked_child(node)
  for child in a:node.children
    if child.is_marked
      return 1
    endif
  endfor
  return 0
endfunction
call s:Tree.function('has_marked_child')

" Remove nodes for which {predicate} returns True WITH their descendants.
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
