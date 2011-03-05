"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-05
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.3

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
  if !unite#sources#outline#lib#ctags#exists()
    call unite#util#print_error("unite-outline: Sorry, Exuberant Ctags required.")
    return []
  elseif !unite#sources#outline#lib#ctags#has('C++')
    call unite#util#print_error(
          \ "unite-outline: Sorry, your ctags doesn't support C++.")
    return []
  endif
  let ctags_opts = '--c++-kinds=cdfgnstu'
  return self.extract_headings_by_ctags(ctags_opts, a:context)
endfunction

function! s:init_heading_group_map(spec_dict)
  let s:HEADING_GROUP = { 'UNKNOWN': 0 }
  let s:HEADING_GROUP_MAP = {}
  let group_id = 1
  for group_name in keys(a:spec_dict)
    let s:HEADING_GROUP[group_name] = group_id
    for heading_type in a:spec_dict[group_name]
      let s:HEADING_GROUP_MAP[heading_type] = group_id
    endfor
    let group_id += 1
  endfor
  echomsg "s:HEADING_GROUP = " . string(s:HEADING_GROUP)
  echomsg "s:HEADING_GROUP_MAP = " . string(s:HEADING_GROUP_MAP)
endfunction
call s:init_heading_group_map({
      \ 'MACRO': ['macro'],
      \ 'TYPE' : ['class', 'enum', 'struct', 'typedef'],
      \ 'PROC' : ['function'],
      \ })

function! s:outline_info.extract_headings_by_ctags(ctags_opts, context)
  let tags = unite#sources#outline#lib#ctags#get_tags(a:ctags_opts, a:context)
  let num_tags = len(tags)

  let headings = [] | let scope_table = {}
  let name_counter = {}
  
  let idx = 0
  while idx < num_tags
    let tag = tags[idx]
    let heading = s:create_heading(tag, a:context)
    if empty(heading) | let idx += 1 | continue | endif

    let heading.word .= s:get_tag_name_id_suffix(tag, name_counter)

    if heading.type =~# '^\%(class\|struct\)$'
      " class/struct
      if !has_key(scope_table, tag.name)
        let scope_table[tag.name] = heading
      elseif scope_table[tag.name].word =~ '^('
        let heading.children = scope_table[tag.name].children
        let scope_table[tag.name] = heading
      endif
    endif

    let scope = s:get_tag_scope(tag)
    if scope !=# 'top'
      " a child of something
      if !has_key(scope_table, tag[scope])
        let pseudo_heading = {
              \ 'word' : '(' . tag[scope] . ') : ' . scope,
              \ 'level': 1,
              \ 'type' : scope,
              \ 'lnum' : tag.lnum,
              \ }
        let scope_table[tag[scope]] = pseudo_heading
      endif

      let heading.word = unite#sources#outline#
            \lib#ctags#get_access_mark(tag) . heading.word

      call unite#sources#outline#
            \lib#heading#append_child(scope_table[tag[scope]], heading)

    elseif !has_key(scope_table, tag.name)
      " others
      call add(headings, heading)
    endif

    if idx % 50 == 0
      call unite#sources#outline#util#print_progress(
            \ "Extracting headings..." . idx * 100 / num_tags . "%")
    endif

    let idx += 1
  endwhile
  call unite#sources#outline#util#print_progress("Extracting headings...done.")

  let headings += filter(values(scope_table), '!has_key(v:val, "parent")')
  call unite#sources#outline#util#sort_by_lnum(headings)

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
    if a:tag.name =~# '^[[:upper:]_]\{3,}$'
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

function! s:get_param_list(context, lnum)
  let line = unite#sources#outline#util#join_to_rparen(a:context, a:lnum)
  return matchstr(line, '([^)]*)')
endfunction

function! s:get_heading_group(heading)
  return  get(s:HEADING_GROUP_MAP, a:heading.type, s:HEADING_GROUP.UNKNOWN)
endfunction

function! s:get_tag_name_id_suffix(tag, name_counter)
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

function! s:get_tag_scope(tag)
  for scope in ['class', 'struct']
    if has_key(a:tag, scope) | return scope | endif
  endfor
  return 'top'
endfunction

function! s:outline_info.need_blank(head1, head2)
  if a:head1.level < a:head2.level
    return 0
  elseif a:head1.level == a:head2.level
    return (s:get_heading_group(a:head1) != s:get_heading_group(a:head2) ||
          \ has_key(a:head1, 'children') || has_key(a:head2, 'children'))
  else
    return 1
  endif
endfunction

" vim: filetype=vim
