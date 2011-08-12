"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-12
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

function! s:Tree_append_child(heading, child)
  if !has_key(a:heading, 'children')
    let a:heading.children = []
  endif
  call add(a:heading.children, a:child)
  let a:child.parent = a:heading
  " Ensure that all headings has 'children'.
  if !has_key(a:child, 'children')
    let a:child.children = []
  endif
endfunction
call s:Tree.function('append_child')

function! s:Tree_remove_child(heading, child)
  call remove(a:heading.children, index(a:heading.children, a:child))
endfunction
call s:Tree.function('remove_child')

function! s:Tree_is_toplevel(heading)
  return has_key(a:heading.parent, '__root__')
endfunction
call s:Tree.function('is_toplevel')

function! s:Tree_is_leaf(heading)
  return empty(a:heading.children)
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

" Tree-aware Filter
"
" NOTE: This function filters the given list of headings, that've been
" tree-structrued, but doesn't destroy the tree structure of them. The
" filtering process only set `is_marked' and `is_matched' flags for each
" headings.
"
" unite-outline's matcher see these flags to accomplish its tree-aware
" filtering task.
"
function! s:Tree_filter(headings, predicate)
  if empty(a:headings) | return a:headings | endif
  for heading in a:headings
    if s:Tree_is_toplevel(heading)
      call s:mark(heading, a:predicate)
    endif
  endfor
  " The given list is filtered, but the tree structure is kept.
  let filtered = filter(a:headings, 'v:val.is_marked')
  return filtered
endfunction
call s:Tree.function('filter')

" NOTE: A heading is marked when it has any marked child or the given
" predicate yields True for the heading. Marked headings will be displayed at
" the unite.vim's buffer as the results of narrowing.
"
function! s:mark(heading, predicate)
  let child_marked = 0
  for child in a:heading.children
    if !child.is_marked
      continue
    endif
    if s:mark(child, a:predicate)
      let child_marked = 1
    endif
  endfor
  let a:heading.is_matched = a:predicate.call(a:heading)
  let a:heading.is_marked = (child_marked || a:heading.is_matched)
  return a:heading.is_marked
endfunction

" Flatten a tree into a List.
"
" NOTE: This function resets heading levels in accordance with the given
" tree's structure.
"
function! s:Tree_flatten(tree)
  let headings = []
  for node in a:tree.children
    let node.level = s:Tree_is_toplevel(node) ? 1 : node.parent.level + 1
    call add(headings, node)
    let headings += s:Tree_flatten(node)
  endfor
  return headings
endfunction
call s:Tree.function('flatten')

" Returns the root node of the tree that consists of the given headings.
"
function! s:Tree_get_root(headings)
  if empty(a:headings) | return s:Tree_new() | endif
  let heading = a:headings[0]
  while 1
    if has_key(heading.parent, '__root__')
      return heading.parent
    endif
    let heading = heading.parent
  endwhile
  let root = s:Tree.new()
  let top_headings = filter(copy(a:headings), 's:Tree_is_toplevel(v:val)')
  for heading in top_headings
    call s:Tree_append_child(root, heading)
  endfor
  return root
endfunction
call s:Tree.function('get_root')

function! s:Tree_has_marked_child(heading)
  let result = 0
  for child in a:heading.children
    if child.is_marked
      let result = 1
      break
    endif
  endfor
  return result
endfunction
call s:Tree.function('has_marked_child')

" Remove headings for which the given predicate returns True WITH their
" children.
"
function! s:Tree_remove(headings, predicate, ...)
  if empty(a:headings) | return a:headings | endif
  let root = s:Tree_get_root(a:headings)
  call s:remove(root, a:predicate)
  let headings = s:Tree_flatten(root)
  return headings
endfunction
call s:Tree.function('remove')

function! s:remove(heading, predicate)
  let children = copy(a:heading.children)
  for child in children
    if a:predicate.call(child)
      call s:Tree_remove_child(a:heading, child)
      continue
    endif
    call s:remove(child, a:predicate)
  endfor
endfunction

" vim: filetype=vim
