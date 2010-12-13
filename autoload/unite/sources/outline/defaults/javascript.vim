"=============================================================================
" File       : autoload/unite/sources/outline/defaults/javascript.vim
" Maintainer : h1mesuke <himesuke@gmail.com>
" Updated    : 2010-12-13
"
" Improved by hamaco, h1mesuke
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for JavaScript
" Version: 0.0.3

function! unite#sources#outline#defaults#javascript#outline_info()
  return s:outline_info
endfunction

" patterns
let s:ident  = '\<\h\w*\>'

let s:assign = '\%(var\s\+\)\=\('.s:ident.'\%(\.'.s:ident.'\)*\)\s*='
" NOTE: This pattern contains 1 capture;  1:lvalue

let s:label  = '\('.s:ident.'\)\s*:'
" NOTE: This pattern contains 1 capture;  1:label

let s:rvalue = '\(function\s*(\([^)]*\))\|{\)'
" NOTE: This pattern contains 2 captures; 1:rvalue [, 2:arg_list]

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#shared#pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*\(function\>\|\('.s:assign.'\|'.s:label.'\)\s*'.s:rvalue.'\)',
      \ 'skip': {
      \   'header': unite#sources#outline#shared#pattern('cpp', 'header'),
      \ },
      \}

let s:leading_mark = {
      \ 'constructor': 'c ',
      \ 'function'   : 'f ',
      \ 'method'     : 'm ',
      \ 'object'     : 'o ',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:which ==# 'heading-1'
    return a:heading_line

  elseif a:which ==# 'heading'

    let matched_list = matchlist(a:heading_line,
          \ '^\(\s*\)function\s\+\('.s:ident.'\)\s*(\(.*\))')
    if len(matched_list) > 0
      " function Foo(...) -> c Foo(...)
      " function foo(...) -> f foo(...)
      let [indent, func_name, arg_list] = matched_list[1:3]
      let kind = (func_name =~ '^\u' ? s:leading_mark.constructor : s:leading_mark.function)
      return indent . kind . func_name . '(' . arg_list . ')'
    endif

    let matched_list = matchlist(a:heading_line,
          \ '^\(\s*\)\%('.s:assign.'\|'.s:label.'\)\s*'.s:rvalue)
    if len(matched_list) > 0
      let [indent, lvalue, label, rvalue, arg_list] = matched_list[1:5]
      if lvalue =~ '\S'
        "---------------------------------------
        " Assign =
        if lvalue =~ '\.'
          " property
          let prop_chain = split(lvalue, '\.')
          let prop_name = prop_chain[-1]
          if rvalue =~ '^f'
            if prop_name =~ '^\u'
              " Foo.Bar = function(...) -> c Foo.Bar(...)
              return indent . s:leading_mark.constructor . lvalue . '(' . arg_list . ')'
            else
              " Foo.bar = function(...) -> m bar(...)
              let indent .= repeat(' ', a:context.buffer.shiftwidth)
              return indent . s:leading_mark.method . prop_name . '(' . arg_list . ')'
            endif
          else
            if match(prop_chain, '^\u') >= 0
              " Foo.Bar = { -> o Foo.Bar
              " Foo.bar = { -> o Foo.bar
              return indent . s:leading_mark.object . lvalue
            else
              " foo.bar = { -> TOO SMALL GRANULARITY
            endif
          endif
        elseif lvalue =~ '^\u'
          " variale
          if rvalue =~ '^f'
            " var Foo = function(...) -> c Foo(...)
            return indent . s:leading_mark.constructor . lvalue . '(' . arg_list . ')'
          else
            " var Foo = { -> o Foo
            return indent . s:leading_mark.object . lvalue
          endif
        endif
      else
        "---------------------------------------
        " Label
        if rvalue =~ '^f'
          " foo: function(...) -> m foo(...)
          return indent . s:leading_mark.method . label . '(' . arg_list . ')'
        else
          " foo: { -> TOO SMALL GRANULARITY
        endif
      endif
    endif
  endif

  return ""
endfunction

" vim: filetype=vim
