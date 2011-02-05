"=============================================================================
" File    : autoload/unite/sources/outline/defaults/java.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-06
"
" Contributed by basyura
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Java
" Version: 0.0.7

function! unite#sources#outline#defaults#java#outline_info()
  return s:outline_info
endfunction

" sub patterns
let s:modifiers = '\%(\h\w*\s\+\)*'
let s:method_def = '\h\w*\s\+\h\w*\s*('

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '__dummy__',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('cpp', 'header'),
      \ },
      \}

function! s:outline_info.initialize(context)
  let s:class_names = []
  call self.rebuild_heading_pattern()
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = unite#sources#outline#
        \util#get_indent_level(a:heading_line, a:context) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && unite#sources#outline#
        \util#_cpp_is_in_comment(a:heading_line, a:matched_line)
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:matched_line, a:context)
  elseif a:which == 'heading'
    if a:heading_line =~ '\<\%(new\|return\|throw\)\>'
      let heading.level = 0
    else
      if a:heading_line =~ '\<class\>'
        " class
        let class_name = matchstr(a:heading_line, '\<class\s\+\zs\h\w*')
        call self.rebuild_heading_pattern(class_name)
        " rebuild the heading pattern to extract constructor definitions
        " with no modifiers
      elseif a:heading_line =~ '\<interface\>'
        " interface
      else
        " method
        let heading.word = s:normalize_method_heading_word(heading.word)
      endif
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

function! s:normalize_method_heading_word(heading_word)
  let heading_word = substitute(substitute(a:heading_word, '{.*$', '', ''), ';.*$', '', '')
  let matched_list = matchlist(heading_word,
        \ '^\s*\(public\|private\|protected\)\=\s\+\(\%(\h\w*\s\+\)*\)\(\h\w*\s*(.*$\)')
  let [scope, type, method] = matched_list[1:3]

  if scope == ''
    let scope = '~'
  else
    let scope = { 'public': '+', 'private': '-', 'protected': '#' }[scope]
  endif

  return scope . ' ' . method . (type == '' ? '' : ' : ' . type)
endfunction

function! s:outline_info.rebuild_heading_pattern(...)
  let sub_patterns = [s:modifiers . '\%(\%(class\|interface\)\>\|' . s:method_def . '\)']

  if a:0
    let class_name = a:1
    call add(s:class_names, class_name)
  endif
  if !empty(s:class_names)
    let ctors_def = '\%(' . join(s:class_names, '\|') . '\)\s*('
    call add(sub_patterns, ctors_def)
  endif
  let self.heading = '^\s*\%(' . join(sub_patterns, '\|') . '\)'
endfunction

" vim: filetype=vim
