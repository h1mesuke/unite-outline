"=============================================================================
" File    : autoload/unite/source/outline/modules/tree.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-11
" Version : 0.3.3
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
  return s:tree
endfunction

"-----------------------------------------------------------------------------

function! s:get_SID()
  return str2nr(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_'))
endfunction

let s:tree = unite#sources#outline#modules#base#new(s:get_SID(), 'Tree')

function! s:Tree_append_child(parent, child)
  if !has_key(a:parent, 'source__children')
    let a:parent.source__children = []
  endif
  call add(a:parent.source__children, a:child)
  let a:child.source__parent = a:parent
endfunction
call s:tree.bind('append_child')

function! s:Tree_remove_child(parent, child)
  call remove(a:parent.source__children, index(a:parent.source__children, a:child))
endfunction
call s:tree.bind('remove_child')

function! s:Tree_has_parent(node)
  let cand = has_key(a:node, 'candidate') ? a:node.candidate : a:node
  return has_key(cand, 'source__parent')
endfunction
call s:tree.bind('has_parent')

function! s:Tree_has_children(node)
  let cand = has_key(a:node, 'candidate') ? a:node.candidate : a:node
  return has_key(cand, 'source__children')
endfunction
call s:tree.bind('has_children')

function! s:Tree_get_parent(node)
  if has_key(a:node, 'candidate')
    let cand = a:node.candidate
    return cand.source__parent.source__heading
  else
    return get(a:node, 'source__parent')
  endif
endfunction
call s:tree.bind('get_parent')

function! s:Tree_get_children(node)
  if has_key(a:node, 'candidate')
    let cand = a:node.candidate
    return map(get(cand, 'source__children', []), 'v:val.source__heading')
  else
    return get(a:node, 'source__children', [])
  endif
endfunction
call s:tree.bind('get_children')

function! s:Tree_is_toplevel(node)
  let cand = has_key(a:node, 'candidate') ? a:node.candidate : a:node
  return !has_key(cand, 'source__parent')
endfunction
call s:tree.bind('is_toplevel')

function! s:Tree_is_leaf(node)
  let cand = has_key(a:node, 'candidate') ? a:node.candidate : a:node
  return !has_key(cand, 'source__children')
endfunction
call s:tree.bind('is_leaf')

function! s:Tree_build(headings)
  let root = { 'level': 0, 'source__children': [] }
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

  return s:Tree_normalize(root)
endfunction
call s:tree.bind('build')

function! s:Tree_filter(treed_list, pred, ...)
  if empty(a:treed_list) | return a:treed_list | endif

  let do_remove_child = (a:0 ? a:1 : 0)
  let marked = {}
  for node in filter(copy(a:treed_list), 's:Tree_is_toplevel(v:val)')
    call s:mark(node, a:pred, marked, do_remove_child)
  endfor

  return filter(a:treed_list, 'marked[v:val.source__id]')
endfunction
call s:tree.bind('filter')

function! s:mark(node, pred, marked, do_remove_child)
  let child_marked = 0
  if has_key(a:node, 'source__children')
    for child in a:node.source__children
      if s:mark(child, a:pred, a:marked, a:do_remove_child)
        let child_marked = 1
      elseif a:do_remove_child
        call s:Tree_remove_child(a:node, child)
      endif
    endfor
  endif
  let self_marked = (child_marked || a:pred.call(a:node))
  let a:marked[a:node.source__id] = self_marked
  return self_marked
endfunction

function! s:Tree_flatten(tree)
  " Flatten a tree of headings into a liner List of the headings.
  let headings = []
  if has_key(a:tree, 'source__children')
    for node in a:tree.source__children
      let node.level = s:Tree_is_toplevel(node) ? 1 : node.source__parent.level + 1
      call add(headings, node)
      let headings += s:Tree_flatten(node)
    endfor
  endif
  return headings
endfunction
call s:tree.bind('flatten')

function! s:Tree_normalize(root)
  call extend(a:root, { 'source__id': 0, 'level': 0 })
  if has_key(a:root, 'source__children')
    " unlink the references to the root node
    for node in a:root.source__children
      if has_key(node, 'source__parent')
        unlet node.source__parent
      endif
    endfor
  endif
  return a:root
endfunction
call s:tree.bind('normalize')

" vim: filetype=vim
