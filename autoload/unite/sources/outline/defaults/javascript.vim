"=============================================================================
" File    : autoload/unite/sources/outline/defaults/javascript.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Contributed by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for JavaScript
" Version: 0.1.1

" TODO: Use jsctags for much better heading list!

function! unite#sources#outline#defaults#javascript#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"---------------------------------------
" Sub Patterns

let s:pat_indent  = '\<\h\w*\>'

let s:pat_assign = '\%(var\s\+\)\=\(' . s:pat_indent . '\%(\.' . s:pat_indent . '\)*\)\s*='
" NOTE: This sub pattern contains 1 capture;  1:lvalue

let s:pat_label  = '\(' . s:pat_indent . '\)\s*:'
" NOTE: This sub pattern contains 1 capture;  1:label

let s:pat_rvalue = '\(function\s*(\([^)]*\))\|{\)'
" NOTE: This sub pattern contains 2 captures; 1:rvalue [, 2:arg_list]

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*\%(function\>\|' .
      \   '\%(' . s:pat_assign . '\|' . s:pat_label . '\)\s*' . s:pat_rvalue . '\)',
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('cpp', 'header'),
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  " Level 1 to 3 are reserved for comment headings.
  let level = s:Util.get_indent_level(a:context, h_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && s:Util._cpp_is_in_comment(a:heading_line, a:matched_line)
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)

  elseif a:which ==# 'heading'

    let matched_list = matchlist(a:heading_line,
          \ '^\s*function\s\+\(' . s:pat_indent . '\)\s*(\(.*\))')
    if len(matched_list) > 0
      " function Foo(...) -> Foo(...)
      " function foo(...) -> foo(...)
      let [func_name, arg_list] = matched_list[1:2]
      let heading.word = func_name . '(' . arg_list . ')'
    endif

    let matched_list = matchlist(a:heading_line,
          \ '^\s*\%(' . s:pat_assign . '\|' . s:pat_label . '\)\s*' . s:pat_rvalue)
    if len(matched_list) > 0
      let [lvalue, label, rvalue, arg_list] = matched_list[1:4]
      if lvalue =~ '\S'
        " Assign
        if lvalue =~ '\.'
          " Property
          let prop_chain = split(lvalue, '\.')
          let prop_name = prop_chain[-1]
          if rvalue =~ '^f'
            if prop_name =~ '^\u'
              " Foo.Bar = function(...) -> Foo.Bar(...)
              let heading.word = lvalue . '(' . arg_list . ')'
            else
              " Foo.bar = function(...) -> bar(...)
              let heading.level += 1
              let heading.word = prop_name . '(' . arg_list . ')'
            endif
          else
            if match(prop_chain, '^\u') >= 0
              " Foo.Bar = { -> Foo.Bar
              " Foo.bar = { -> Foo.bar
              let heading.word = lvalue
            else
              " foo.bar = {
              let heading.level = 0
            endif
          endif
        elseif lvalue =~ '^\u'
          " Variale
          if rvalue =~ '^f'
            " var Foo = function(...) -> Foo(...)
            let heading.word = lvalue . '(' . arg_list . ')'
          else
            " var Foo = { -> Foo
            let heading.word = lvalue
          endif
        else
          " var foo = ...
          let heading.level = 0
        endif
      else
        " Label
        if rvalue =~ '^f'
          " foo: function(...) -> foo(...)
          let heading.word = label . '(' . arg_list . ')'
        else
          " foo: {
          let heading.level = 0
        endif
      endif
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction
