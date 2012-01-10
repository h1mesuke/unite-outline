"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
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

function! unite#sources#outline#modules#tree#import()
  return s:Tree
endfunction

"-----------------------------------------------------------------------------

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

" Tree module provides functions to build a tree structure.
" There are two ways to build a Tree:
"
"   A.  Build a Tree from a List of objects with the level attribute using
"       Tree.build(). 
"
"   B.  Build a Tree one node by one node manually using Tree.new() and
"       Tree.append_child().
"
" The following example shows how to build a Tree in the latter way.
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
let s:Tree.MAX_DEPTH = 20

" Creates a new root node.
"
function! s:Tree_new()
  return { '__root__': 1, 'id': 0, 'level': 0, 'children': [] }
endfunction
call s:Tree.function('new')

" Append {child} to a List of children of {node}.
"
function! s:Tree_append_child(node, child)
  if !has_key(a:node, 'children')
    let a:node.children = []
  endif
  call add(a:node.children, a:child)
  " Ensure that all nodes have `children'.
  if !has_key(a:child, 'children')
    let a:child.children = []
    " NOTE: While building a Tree, all nodes of the Tree pass through this
    " function as a:child.
  endif
endfunction
call s:Tree.function('append_child')

" Builds a tree structure from a List of elements, which are Dictionaries with
" `level' attribute, and then returns the root node of the built Tree.
"
" NOTE: This function allows discontinuous levels and can build a Tree from such
" a sequence of levels well.
"
"                                root              root
"                                 |                 |
"                                 +--1              +--1
"    [1, 3, 5, 5, 2, ...]   =>    |  +--3      =>   |  +--2
"                                 |  |  +--5        |  |  +--3
"                                 |  |  +--5        |  |  +--3
"                                 |  |              |  |
"                                 :  +--2           :  +--2
"
function! s:Tree_build(elems)
  let root = s:Tree_new()
  if empty(a:elems) | return root | endif
  " Build a Tree.
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
  call s:normalize_levels(root)
  return root
endfunction
call s:Tree.function('build')

" Normalize the level of nodes in accordance with the given Tree's structure.
"
"   root             root
"    |                |
"    +--1             +--1
"    |  +--3          |  +--2
"    |  |  +--5  =>   |  |  +--3
"    |  |  +--5       |  |  +--3
"    |  |             |  |
"    :  +--2          :  +--2
"
function! s:normalize_levels(node)
  for child in a:node.children
    let child.level = a:node.level + 1
    call s:normalize_levels(child)
  endfor
endfunction

" Flattens a Tree into a List with setting the levels of nodes.
"
function! s:Tree_flatten(node)
  let elems = []
  for child in a:node.children
    let child.level = a:node.level + 1
    call add(elems, child)
    let elems += s:Tree_flatten(child)
  endfor
  return elems
endfunction
call s:Tree.function('flatten')

"-----------------------------------------------------------------------------
" Tree.List

" Tree.List module provides functions to process a List of objects with the
" level attribute in tree-aware way. 
"
let s:List = unite#sources#outline#modules#base#new('List', s:SID)
let s:Tree.List = s:List

" Normalize the levels of {objs}.
"
function! s:List_normalize_levels(objs)
  let tree = s:Tree_build(a:objs)
  let objs = s:fast_flatten(tree)
  return objs
endfunction
call s:List.function('normalize_levels')

" Flattens a Tree into a List without setting the levels of nodes.
"
function! s:fast_flatten(node)
  let objs = []
  " Push toplevel nodes.
  let stack = reverse(copy(a:node.children))
  while !empty(stack)
    " Pop a node.
    let node = remove(stack, -1)
    call add(objs, node)
    " Push the node's children.
    let stack += reverse(copy(node.children))
  endwhile
  return objs
endfunction

" Resets the matched-marks of the candidates.
"
function! s:List_reset_marks(candidates)
  if empty(a:candidates) | return a:candidates | endif
  let prev_cand = {
        \ 'is_matched': 1, 'source__is_marked': 1,
        \ 'source__heading_level': 0,
        \ }
  for cand in a:candidates
    let cand.is_matched = 1
    let cand.source__is_marked = 1
    let prev_cand.source__has_marked_child =
          \ prev_cand.source__heading_level < cand.source__heading_level
    let prev_cand = cand
  endfor
  let cand.source__has_marked_child = 0
endfunction
call s:List.function('reset_marks')

" Marks the matched candidates and their ancestors.
"
" * A candidate is MATCHED for which eval({pred}) returns True.
" * A candidate is MARKED when any its child has been marked.
"
" NOTE: unite-outline's matcher and formatter see these flags to accomplish
" their tree-aware filtering and formatting tasks.
"
function! s:List_mark(candidates, pred, ...)
  let pred = substitute(a:pred, '\<v:val\>', 'cand', 'g')
  let mark_reserved = map(range(0, s:Tree.MAX_DEPTH), 0)
  for cand in reverse(copy(a:candidates))
    if !cand.source__is_marked
      continue
    endif
    let cand.is_matched = cand.is_matched && eval(pred)
    if cand.is_matched
      let matched_level = cand.source__heading_level
      if 1 < matched_level
        let mark_reserved[1 : matched_level - 1] = map(range(matched_level - 1), 1)
      endif
    endif
    let cand.source__is_marked = cand.is_matched
    if mark_reserved[cand.source__heading_level]
      let cand.source__is_marked = 1
      let cand.source__has_marked_child = 1
      let mark_reserved[cand.source__heading_level] = 0
    else
      let cand.source__has_marked_child = 0
    endif
  endfor
endfunction
call s:List.function('mark')

" Remove the matched headings and their descendants.
"
function! s:List_remove(headings, pred)
  let pred = substitute(a:pred, '\<v:val\>', 'head', 'g')
  let matched_level = s:Tree.MAX_DEPTH + 1
  let headings = []
  for head in a:headings
    if head.level <= matched_level
      if eval(pred)
        let matched_level = head.level
      else
        let matched_level = s:Tree.MAX_DEPTH + 1
        call add(headings, head)
      endif
    endif
  endfor
  return headings
endfunction
call s:List.function('remove')

unlet s:List

let &cpo = s:save_cpo
unlet s:save_cpo
