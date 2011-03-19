"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-19
" Version : 0.3.2
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

function! unite#sources#outline#modules#tree#module()
  return s:Tree
endfunction

function! s:Tree_append_child(parent, child)
  if !has_key(a:parent, 'children')
    let a:parent.children = []
  endif
  call add(a:parent.children, a:child)
  let a:child.parent = a:parent
endfunction

function! s:Tree_build(headings)
  if empty(a:headings) | return | endif
  let context   = [{ 'level': -1 }] | " stack
  let prev_node =  a:headings[0]
  for node in a:headings
    while context[-1].level >= node.level
      call remove(context, -1)
    endwhile
    if context[-1].level > 0
      call s:Tree_append_child(context[-1], node)
    endif
    call add(context, node)
  endfor
  let is_toplevel = '!has_key(v:val, "parent")'
  let root = {}
  let root.children = filter(copy(a:headings), is_toplevel)
  return root
endfunction

function! s:Tree_convert_id_to_ref(candidates)
  let cand_table = {}
  for cand in a:candidates
    let cand_table[cand.source__heading_id] = cand
  endfor
  for cand in a:candidates
    if has_key(cand, 'source__heading_parent')
      let cand.source__heading_parent = cand_table[cand.source__heading_parent]
    endif
    if has_key(cand, 'source__heading_children')
      let cand.source__heading_children = map(cand.source__heading_children, 'cand_table[v:val]')
    endif
  endfor
endfunction

function! s:Tree_convert_ref_to_id(candidates)
endfunction

function! s:Tree_flatten(tree)
  let headings = []
  for node in get(a:tree, 'children', [])
    let node.level = s:is_toplevel(node) ? 1 : node.parent.level + 1
    call add(headings, node)
    let headings += s:Tree_flatten(node)
  endfor
  return headings
endfunction

function! s:is_leaf(node)
  return !has_key(a:node, 'children')
endfunction

function! s:is_toplevel(node)
  return !has_key(a:node, 'parent')
endfunction

function! s:Tree_normalize(root)
  " unlink the references to the root node
  for node in get(a:root, 'children', [])
    if has_key(node, 'parent') | unlet node.parent | endif
  endfor
  return a:root
endfunction

"-----------------------------------------------------------------------------

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_') - 0
endfunction

let s:Tree = unite#sources#outline#define_module(s:get_SID(), 'Tree')

" vim: filetype=vim
