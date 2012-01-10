"=============================================================================
" File    : autoload/unite/sources/outline/defaults/php.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Contributed by hamaco
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for PHP
" Version: 0.1.2

function! unite#sources#outline#defaults#php#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"---------------------------------------
" Sub Pattern

let s:pat_type = '\%(interface\|class\|function\)\>'

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\s*\%(\h\w*\s\+\)*' . s:pat_type,
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
      \     'pattern': '/\S\+\ze : \%(interface\|class\)/' },
      \   { 'name'   : 'function',
      \     'pattern': '/\h\w*\ze\s*(/' },
      \   { 'name'   : 'parameter_list',
      \     'pattern': '/(.*)/' },
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
  elseif a:which == 'heading'
    let modifiers = matchstr(heading.word, '^.*\ze' . s:pat_type)
    let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    if heading.word =~ '\<interface\>'
      " Interface
      let heading.type = 'interface'
      let heading.word = matchstr(heading.word, '\zs\<interface\s\+\zs\h\w*') . ' : interface'
    elseif heading.word =~ '\<class\>'
      " Class
      let heading.type = 'class'
      let heading.word = matchstr(heading.word, '\zs\<class\s\+\zs\h\w*') . ' : class'
    else
      " Function or Method
      let heading.type = 'function'
      let heading.word = matchstr(heading.word, '\<function\s*\zs.*', '', '')
      if modifiers =~ '\<public\>'
        let heading.word = '+ ' . heading.word
      elseif modifiers =~ '\<protected\>'
        let heading.word = '# ' . heading.word
      elseif modifiers =~ '\<private\>'
        let heading.word = '- ' . heading.word
      elseif heading.level > 3
        let heading.word = substitute(heading.word, '\%(&\|\h\)\@=', '+ ', '')
      endif
      let heading.word = substitute(heading.word, '\S\zs(', ' (', '')
    endif
    " Append modifiers.
    let modifiers = substitute(modifiers, '\%(public\|protected\|private\)', '', 'g')
    if modifiers !~ '^\s*$'
      let heading.word .= ' <' . join(split(modifiers, '\s\+'), ',') . '>'
    endif
  endif
  return heading
endfunction

function! s:outline_info.need_blank_between(cand1, cand2, memo)
  if a:cand1.source__heading_group == 'function' && a:cand2.source__heading_group == 'function'
    " Don't insert a blank between two sibling functions.
    return 0
  else
    return (a:cand1.source__heading_group != a:cand2.source__heading_group ||
          \ a:cand1.source__has_marked_child || a:cand2.source__has_marked_child)
  endif
endfunction
