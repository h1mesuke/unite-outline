"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-03
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.1

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {}

" TAG KINDS:
"
"  [c] classes
"  [d] macro definitions
"   e  enumerators (values inside an enumeration)
"  [f] function definitions
"  [g] enumeration names
"   l  local variables
"   m  class, struct, and union members
"  [n] namespaces
"   p  function prototypes
"  [s] structure names
"  [t] typedefs
"  [u] union names
"   v  variable definitions
"   x  external and forward variable declarations
"
function! s:outline_info.extract_headings(context)
  let ctags_opts = '--c++-kinds=cdfgnstu'
  return unite#sources#outline#defaults#cpp#extract_headings(ctags_opts, a:context)
endfunction

let s:SCOPE_TYPES = ['class', 'struct']
let s:SCOPE_TYPES_PATTERN = '\%(' . join(s:SCOPE_TYPES, '\|') . '\)'

function! unite#sources#outline#defaults#cpp#extract_headings(ctags_opts, context)
  if !unite#sources#outline#lib#ctags#exists()
    call unite#util#print_error("unite-outline: Sorry, Exuberant Ctags required.")
    return []
  endif

  let tags = unite#sources#outline#lib#ctags#get_tags(a:ctags_opts, a:context)

  let headings = [] | let class_table = {}
  let name_counter = {}

  for tag in tags
    let heading = s:create_heading(tag, a:context)
    if empty(heading) | continue | endif

    let heading.word .= s:get_name_id_suffix(name_counter, tag)

    if tag.kind =~# s:SCOPE_TYPES_PATTERN
      " class/struct
      if has_key(class_table, tag.name)
        let heading.children = class_table[tag.name].children
      endif
      let class_table[tag.name] = heading

    else
      let scope = s:get_scope(tag)

      if scope != 'top'
        " class/struct members
        if !has_key(class_table, tag[scope])
          let class_table[tag[scope]] = unite#sources#outline#
                \lib#heading#new('(' . tag[scope] . ') : ' . scope, scope, tag.lnum)
        endif

        let heading.word = unite#sources#outline#lib#ctags#get_access_mark(tag) . heading.word

        call unite#sources#outline#
              \lib#heading#append_child(class_table[tag[scope]], heading)
      else
        " others
        call add(headings, heading)
      endif
    endif
  endfor

  let headings = unite#sources#outline#util#sort_by_lnum(headings + values(class_table))
  let headings = s:insert_blanks(headings)

  return headings
endfunction

function! s:create_heading(tag, context)
  let line = a:tag.line
  let heading = {
        \ 'word' : a:tag.name,
        \ 'type' : a:tag.kind,
        \ "lnum" : a:tag.lnum,
        \ }
  let ignore = 0

  if heading.type ==# 'function'
    if a:tag.name =~# '^\u\{2,}$'
      let ignore = 1
    elseif has_key(a:tag, 'signature')
      let heading.word .= ' ' . a:tag.signature
    else
      let heading.word .= ' ' . s:get_param_list(a:context, a:tag.lnum)
    endif

  else
    if heading.type ==# 'macro'
      if line =~# '#undef\>'
        let ignore = 1
      elseif line =~# a:tag.name . '\s*('
        let heading.word .= ' ' . s:get_param_list(a:context, a:tag.lnum)
      endif
    endif
    let heading.word .= ' : ' . a:tag.kind
  endif

  return ignore ? {} : heading
endfunction

function! s:insert_blanks(headings)
  let blank = unite#sources#outline#lib#heading#create_blank()
  let headings = [] | let prev_heading = blank
  for heading in a:headings
    if heading.type =~# s:SCOPE_TYPES_PATTERN
      if !empty(headings) | call add(headings, blank) | endif
      call add(headings, heading)
    else
      if prev_heading.type =~# s:SCOPE_TYPES_PATTERN | call add(headings, blank) | endif
      call add(headings, heading)
    endif
    let prev_heading = heading
  endfor
  return headings
endfunction

function! s:get_scope(tag)
  for scope in s:SCOPE_TYPES
    if has_key(a:tag, scope) | return scope | endif
  endfor
  return 'top'
endfunction

function! s:get_param_list(context, lnum)
  let line = unite#sources#outline#util#join_to_rparen(a:context, a:lnum)
  return matchstr(line, '([^)]*)')
endfunction

function! s:get_name_id_suffix(name_counter, tag)
  let namespace = has_key(a:tag, 'class') ? a:tag.class : a:tag.kind
  if !has_key(a:name_counter, namespace)
    let a:name_counter[namespace] = {}
  endif

  let counter = a:name_counter[namespace]
  let name = has_key(a:tag, 'signature') ? a:tag.name . a:tag.signature : a:tag.name
  if has_key(counter, name)
    let counter[name] += 1
    return ' [' . counter[name] . ']'
  else
    let counter[name] = 1
    return ''
  endif
endfunction

" vim: filetype=vim
