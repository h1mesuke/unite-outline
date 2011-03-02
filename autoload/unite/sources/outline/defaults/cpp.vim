"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-02
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.1.0

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {}

let s:CATEGORY_ORDER = ['namespace', 'macro', 'enum', 'struct', 'union', 'typedef', 'function']

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
  endif

  let tags = unite#sources#outline#lib#ctags#get_tags('--c++-kinds=cdfgnstu', a:context)

  let categories = {} | let classes = {}
  let name_counter = {}

  for tag in tags
    let heading = s:create_heading(tag, a:context)
    if empty(heading) | continue | endif

    if tag.kind ==# 'class'
      " classes
      let heading.word .= ' : ' . heading.type
      let classes[tag.name] = heading

    elseif has_key(tag, 'class')
      " class members
      if !has_key(classes, tag.class)
        let classes[tag.class] = unite#sources#outline#
              \lib#heading#create_pseudo('(' . tag.class . ') : class', 'class', tag.lnum)
      endif

      let heading.word = unite#sources#outline#lib#ctags#get_access_mark(tag) . heading.word
      if heading.type !=# 'function'
        let heading.word .= ' : ' . heading.type
      endif

      call unite#sources#outline#
            \lib#heading#append_child(classes[tag.class], heading)

    else
      " other category members
      if !has_key(categories, heading.type)
        let cat_name = unite#sources#outline#util#capitalize(heading.type)
        let categories[heading.type] = unite#sources#outline#
              \lib#heading#create_pseudo(cat_name, heading.type, tag.lnum)
      endif

      call unite#sources#outline#
            \lib#heading#append_child(categories[heading.type], heading)
    endif

    let heading.word .= s:get_name_id_suffix(name_counter, tag)
  endfor

  let headings = []
  let blank_heading = unite#sources#outline#lib#heading#create_blank()

  if has_key(categories, 'macro')
    let categories.macro.word = '#define'
  endif
  for cat_name in s:CATEGORY_ORDER
    if !has_key(categories, cat_name) | continue | endif
    let category = categories[cat_name]
    if len(category.children) > 1 | let category.word .= 's' | endif
    let headings += [categories[cat_name], blank_heading]
  endfor

  for class in unite#sources#outline#util#sort_by_lnum(values(classes))
    let headings += [class, blank_heading]
  endfor

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
    else
      let heading.word .= a:tag.signature
    endif

  elseif heading.type ==# 'macro'
    if line =~# '#undef\>'
      let ignore = 1
    elseif line =~# a:tag.name . '\s*('
      let line = unite#sources#outline#util#join_to_rparen(a:context, a:tag.lnum)
      let param_list = matchstr(line, '([^)]*)')
      let heading.word .= param_list
    endif
  endif

  return ignore ? {} : heading
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
