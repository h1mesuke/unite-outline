"=============================================================================
" File    : autoload/unite/sources/outline/defaults/php.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-08
"
" Contributed by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.1.0

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*\%(interface\|class\|\%(\h\w*\s\+\)\=function\)\>',
      \
      \ 'skip': {
      \   'header': {
      \     'leading': '^\%(<?php\|//\)',
      \     'block'  : s:Util.shared_pattern('c', 'header'),
      \   },
      \ },
      \
      \ 'heading_groups': {
      \   'type'     : ['interface', 'class'],
      \   'function' : ['function'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'   : 'comment',
      \     'pattern': "'/[/*].*'" },
      \   { 'name'   : 'type',
      \     'pattern': '/.*\ze: \%(interface\|class\)/' },
      \   { 'name'   : 'function',
      \     'pattern': '/\h\w*\ze\s*(/' },
      \   { 'name'   : 'parameter_list',
      \     'pattern': '/(.*)/' },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
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
  elseif a:which == 'heading'
    let heading.word = substitute(a:heading_line, '\s*{.*$', '', '')
    if heading.word =~ '^\s*interface\>'
      " interface
      let heading.type = 'interface'
      let heading.word = matchstr(heading.word, '^\s*interface\s\+\zs\h\w*') . ' : interface'
    elseif heading.word =~ '^\s*class\>'
      " class
      let heading.type = 'class'
      let heading.word = matchstr(heading.word, '^\s*class\s\+\zs\h\w*') . ' : class'
    else
      " function or method
      let heading.type = 'function'
      let heading.word = substitute(heading.word, '\<function\s*', '', '')
      if heading.word =~ '^\s*public\>'
        let heading.word = substitute(heading.word, '\<public\s*', '+ ', '')
      elseif heading.word =~ '^\s*protected\>'
        let heading.word = substitute(heading.word, '\<protected\s*', '# ', '')
      elseif heading.word =~ '^\s*private\>'
        let heading.word = substitute(heading.word, '\<private\s*', '- ', '')
      elseif heading.level > 3
        let heading.word = substitute(heading.word, '\%(&\|\h\)\@=', '+ ', '')
      endif
      let heading.word = substitute(heading.word, '\S\zs(', ' (', '')
    endif
  endif

  return heading
endfunction

" vim: filetype=vim
