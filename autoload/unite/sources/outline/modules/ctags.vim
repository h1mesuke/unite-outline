"=============================================================================
" File    : autoload/unite/source/outline/lib/ctags.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-09-03
" Version : 0.5.0
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

function! unite#sources#outline#modules#ctags#import()
  return s:Ctags
endfunction

"-----------------------------------------------------------------------------

let s:Tree  = unite#sources#outline#import('Tree')
let s:Util  = unite#sources#outline#import('Util')
let s:Vital = vital#of('unite')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

" Ctags module provides a function to extract headings from a file using the Exuberant
" Ctags. It executes the Ctags and parses its output and build a tree of
" headings.
"
let s:Ctags = unite#sources#outline#modules#base#new('Ctags', s:SID)

" Find the Exuberant Ctags and identify its binary name. If not found, returns
" empty String.
"
function! s:find_exuberant_ctags()
  let ctags_exe_names = [
        \ 'ctags-exuberant',
        \ 'exctags',
        \ 'ctags',
        \ 'tags',
        \ ]
  if exists('g:neocomplcache_ctags_program') && !empty(g:neocomplcache_ctags_program)
    let ctags_exe_names = [g:neocomplcache_ctags_program] + ctags_exe_names
  endif
  for ctags in ctags_exe_names
    if executable(ctags)
      " Make sure it is Exuberant.
      let ctags_out = unite#util#system(ctags . ' --version')
      if split(ctags_out, "\<NL>")[0] =~? '\<Exuberant Ctags\>'
        return ctags
      endif
    endif
  endfor
  return ''
endfunction 

let s:Ctags.exe = s:find_exuberant_ctags()
let s:Ctags.lang_info = {}

" Returns True if the Exuberant Ctags is available.
"
function! s:Ctags_exists()
  return !empty(s:Ctags.exe)
endfunction
call s:Ctags.function('exists')

" Returns True if the Exuberant Ctags supports {filetype}.
"
function! s:Ctags_supports(filetype)
  if !has_key(s:Ctags.lang_info, a:filetype)
    return 0
  else
    let lang_info = s:Ctags.lang_info[a:filetype]
    let ctags_out = unite#util#system(s:Ctags.exe . ' --list-languages')
    return index(split(ctags_out, "\<NL>"), lang_info.name, 1) >= 0
  endif
endfunction
call s:Ctags.function('supports')

" Executes the Ctags and returns a List of tag objects.
"
function! s:execute_ctags(context)
  " Write the current content of the buffer to a temporary file.
  let input = join(a:context.lines[1:], "\<NL>")
  let input = s:Vital.iconv(input, &encoding, &termencoding)
  let temp_file = tempname()
  if writefile(split(input, "\<NL>"), temp_file) == -1
    call unite#util#print_message(
          \ "[unite-outline] Couldn't make a temporary file at " . temp_file)
    return []
  endif
  " NOTE: If the auto-update is enabled, the buffer may have been changed
  " since the last write. Because the user expects the headings to be
  " extracted from the buffer which he/she is watching now, we need to process
  " the buffer's content not its file's content.

  let filetype = a:context.buffer.major_filetype
  " Assemble the command-line.
  let lang_info = s:Ctags.lang_info[filetype]
  let opts  = ' -f - --excmd=number --fields=afiKmsSzt --sort=no '
  let opts .= ' --language-force=' . lang_info.name . ' '
  let opts .= lang_info.ctags_options

  let path = s:Util.Path.normalize(temp_file)
  let path = s:Util.String.shellescape(path)

  let cmdline = s:Ctags.exe . opts . path

  " Execute the Ctags.
  let ctags_out = unite#util#system(cmdline)
  let status = unite#util#get_last_status()
  if status != 0
    call unite#util#print_message(
          \ "[unite-outline] ctags failed with status " . status . ".")
    return []
  endif

  " Delete the used temporary file.
  if delete(temp_file) != 0
    call unite#util#print_error(
          \ "unite-outline: Couldn't delete a temporary file: " . temp_file)
  endif

  let tag_lines = split(ctags_out, "\<NL>")
  try
    " Convert tag lines into tag objects.
    let tags = map(tag_lines, 's:create_tag(v:val, lang_info)')
    call filter(tags, '!empty(v:val)')
    return tags
  catch
    " The first line of the output often contains a hint of an error.
    throw tag_lines[0]
  endtry
endfunction

" Creates a tag object from a tag line. If the line is not a tag line, for
" example, a warning message from the standard error, returns an empty
" Dictionary.
"
" TAG FILE FORMAT:
"
"   tag_line
"     := tag_name<Tab>file_name<Tab>ex_cmd;"<Tab>{extension_fields}
"
"   extension_fields
"     := key:value<Tab>key:value<Tab>...
"
function! s:create_tag(tag_line, lang_info)
  let fields = split(a:tag_line, "\<Tab>")
  if len(fields) < 3
    " The line doesn't seem a tag line, so ignore it.
    " Example: ctags: Warning: {message}
    return {}
  endif
  let tag = {}
  let tag.name = fields[0]
  let tag.lnum = str2nr(fields[2])
  for ext_fld in fields[3:-1]
    let [key, value] = matchlist(ext_fld, '^\([^:]\+\):\(.*\)$')[1:2]
    let tag[key] = value
  endfor
  for scope_kind in a:lang_info.scope_kinds
    if has_key(tag, scope_kind)
      let tag.scope_kind = scope_kind
      let tag.scope = tag[scope_kind]
    endif
  endfor
  if has_key(tag, 'scope')
    let tag.qualified_name = tag.scope . a:lang_info.scope_delim . tag.name
  else
    let tag.qualified_name = tag.name
  endif
  return tag
endfunction

" Extract headings from the context buffer's file using the Ctags and then
" returns a tree of the headings.
"
function! s:Ctags_extract_headings(context)
  let filetype = a:context.buffer.major_filetype
  if !s:Ctags_exists()
    call unite#print_message("[unite-outline] Sorry, Exuberant Ctags required.")
    return []
  elseif !s:Ctags_supports(filetype)
    call unite#print_message("[unite-outline] " .
          \ "Sorry, your ctags doesn't support " . toupper(filetype))
    return []
  endif

  " Execute the Ctags and get a List of tag objects.
  let tags = s:execute_ctags(a:context)

  let lang_info = s:Ctags.lang_info[filetype]
  let scope_kinds_pattern = '^\%(' . join(lang_info.scope_kinds, '\|') . '\)$'
  let scope_table = {}
  let tag_name_counter = {}

  " Build a heading tree processing a List of tag objects.
  let root = s:Tree.new()
  for tag in tags
    " Create a heading from the tag object.
    if has_key(lang_info, 'create_heading')
      let heading = lang_info.create_heading(tag, a:context)
    else
      let heading = s:create_heading(tag, a:context)
    endif
    if empty(heading) | continue | endif

    " Remove extra spaces to normalize the parameter list.
    let heading.word = substitute(substitute(heading.word, '(\s*', '(', ''), '\s*)', ')', '')
    " Append an ID suffix (#2, #3, ...) to the heading word if the heading is
    " the second or subsequent one that has the tag's name.
    call s:count_tag_name(tag, tag_name_counter)
    let heading.word .= s:get_tag_name_id_suffix(tag, tag_name_counter)

    if tag.kind =~# scope_kinds_pattern
      " The heading has its scope, in other words, it is able to have child
      " headings. To append its children that come after to it, register it to
      " the table.
      " Example: a class, a module, etc
      if !has_key(scope_table, tag.qualified_name)
        let scope_table[tag.qualified_name] = heading
      elseif has_key(scope_table[tag.qualified_name], '__pseudo__')
        " Replace the pseudo heading with the actual one.
        let heading.children = scope_table[tag.qualified_name].children
        let scope_table[tag.qualified_name] = heading
      endif
    endif

    if has_key(tag, 'scope')
      " Group_A: The heading belongs to a scope, in other words, it has
      " a parent heading.
      " Example: a method in class, an inner class, etc
      if !has_key(scope_table, tag.scope)
        " If the parent heading hasn't registered to the table yet, create
        " a pseudo heading as a place holder.
        let pseudo_heading = s:create_pseudo_heading(tag)
        let scope_table[tag.scope] = pseudo_heading
      endif
      " Prepend a symbol character (+, #, -) to show the accessibility to the
      " heading word.
      let heading.word = s:get_tag_access_mark(tag) . heading.word
      call s:Tree.append_child(scope_table[tag.scope], heading)
    else
      " Group_B: The heading belongs to the toplevel.
      call s:Tree.append_child(root, heading)
    endif
  endfor

  " Merge orphaned pseudo headings.
  let pseudo_headings = filter(values(scope_table), 'has_key(v:val, "__pseudo__")')
  if len(pseudo_headings) > 0
    for heading in pseudo_headings
      call s:Tree.append_child(root, heading)
    endfor
    call s:Util.List.sort_by_lnum(root.children)
  endif
  return root
endfunction
call s:Ctags.function('extract_headings')

" Creates a heading from {tag}.
"
function! s:create_heading(tag, context)
  let line = a:context.lines[a:tag.lnum]
  let heading = {
        \ 'word' : a:tag.name,
        \ 'type' : a:tag.kind,
        \ "lnum" : a:tag.lnum,
        \ }
  if has_key(a:tag, 'signature')
    let heading.word .= ' ' . a:tag.signature
  else
    let heading.word .= ' : ' . a:tag.kind
  endif
  if has_key(a:tag, 'implementation')
    let heading.word .= ' <' . a:tag.implementation . '>'
  endif
  return heading
endfunction

" Creates a pseudo heading from {tag}.
" Pseudo headings are the headings whose tags don't exists actually because
" they are ones of the other file.
"
function! s:create_pseudo_heading(tag)
  let heading = {
        \ 'word' : '(' . a:tag.scope . ') : ' . a:tag.scope_kind,
        \ 'type' : a:tag.scope_kind,
        \ 'lnum' : a:tag.lnum,
        \ '__pseudo__': 1,
        \ }
  return heading
endfunction

" Gets a full parameter list from the context buffer's line.
"
function! s:get_param_list(context, lnum)
  let line = s:Util.join_to_rparen(a:context, a:lnum)
  return matchstr(line, '([^)]*)')
endfunction

" Returns a symbol character (+, #, -) to show the accessibility of {tag}.
"
let s:OOP_ACCESS_MARKS = {
      \ 'public'   : '+',
      \ 'protected': '#',
      \ 'private'  : '-'
      \ }
function! s:get_tag_access_mark(tag)
  let access = has_key(a:tag, 'access') ? a:tag.access : 'unknown'
  return get(s:OOP_ACCESS_MARKS, access, '_') . ' '
endfunction

function! s:count_tag_name(tag, counter)
  let name = a:tag.qualified_name
  if has_key(a:counter, name)
    let a:counter[name] += 1
  else
    let a:counter[name] = 1
  endif
endfunction

" Returns an ID suffix (#2, #3, ...) of {tag}.
" If the tag is the first one that has its name, returns empty String.
"
function! s:get_tag_name_id_suffix(tag, counter)
  let name = a:tag.qualified_name
  if has_key(a:tag, 'signature')
    let name .= a:tag.signature
  endif
  if has_key(a:counter, name) && a:counter[name] > 1
    return ' #' . a:counter[name]
  else
    return ''
  endif
endfunction

"-----------------------------------------------------------------------------
" C/C++
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
let s:Ctags.lang_info.cpp = {
      \ 'name': 'C++',
      \ 'ctags_options': ' --c++-kinds=cdfgnstu ',
      \ 'scope_kinds'  : ['namespace', 'class', 'struct'],
      \ 'scope_delim'  : '::',
      \ }
function! s:Ctags.lang_info.cpp.create_heading(tag, context)
  let line = a:context.lines[a:tag.lnum]
  let heading = {
        \ 'word' : a:tag.name,
        \ 'type' : a:tag.kind,
        \ 'lnum' : a:tag.lnum,
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
      elseif line =~# a:tag.name . '('
        let heading.word .= ' ' . s:get_param_list(a:context, a:tag.lnum)
        let heading.group = 'function'
      endif
    endif
    let heading.word .= ' : ' . a:tag.kind
  endif
  if has_key(a:tag, 'implementation')
    let heading.word .= ' <' . a:tag.implementation . '>'
  endif
  return ignore ? {} : heading
endfunction

let s:Ctags.lang_info.c = copy(s:Ctags.lang_info.cpp)
call extend(s:Ctags.lang_info.c, {
      \ 'name': 'C',
      \ 'ctags_options': ' --c-kinds=cdfgnstu '
      \ }, 'force')

"-----------------------------------------------------------------------------
" Java
"
"  [c] classes
"   e  enum constants
"   f  fields
"  [g] enum types
"  [i] interfaces
"   l  local variables
"  [m] methods
"  [p] packages
"
let s:Ctags.lang_info.java = {
      \ 'name': 'Java',
      \ 'ctags_options': ' --java-kinds=cgimp ',
      \ 'scope_kinds'  : ['interface', 'class', 'enum'],
      \ 'scope_delim'  : '.',
      \ }

"-----------------------------------------------------------------------------
" Python
"
"  [c] classes
"  [f] functions
"  [m] class members
"   v  variables
"   i  imports
"
let s:Ctags.lang_info.python = {
      \ 'name': 'Python',
      \ 'ctags_options': ' --python-kinds=cfm ',
      \ 'scope_kinds'  : ['function', 'class', 'member'],
      \ 'scope_delim'  : '.',
      \ }
function! s:Ctags.lang_info.python.create_heading(tag, context)
  let heading = {
        \ 'word' : a:tag.name,
        \ 'type' : a:tag.kind,
        \ 'lnum' : a:tag.lnum,
        \ }
  let ignore = 0
  if heading.type =~# '^\%(function\|member\)'
    let heading.word .= ' ' . s:get_param_list(a:context, a:tag.lnum)
  elseif heading.type ==# 'variable'
    " NOTE: ctags always generates tags for variables.
    let ignore = 1
  else
    let heading.word .= ' : ' . a:tag.kind
  endif
  return ignore ? {} : heading
endfunction

" vim: filetype=vim
