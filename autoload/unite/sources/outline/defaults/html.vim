"=============================================================================
" File    : autoload/unite/sources/outline/defaults/html.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-10-15
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for HTML
" Version: 0.0.8

function! unite#sources#outline#defaults#html#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"---------------------------------------
" Patterns

let s:heading_tags = ['head', '[hH][1-6]']

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '<\%(' . join(s:heading_tags, '\|') . '\)[^>]*>',
      \
      \ 'highlight_rules': [
      \   { 'name'   : 'level_1',
      \     'pattern': '/H1\. .*/' },
      \   { 'name'   : 'level_2',
      \     'pattern': '/H2\. .*/' },
      \   { 'name'   : 'level_3',
      \     'pattern': '/H3\. .*/' },
      \   { 'name'   : 'level_4',
      \     'pattern': '/H4\. .*/' },
      \   { 'name'   : 'level_5',
      \     'pattern': '/H5\. .*/' },
      \   { 'name'   : 'level_6',
      \     'pattern': '/H6\. .*/' },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }
  if heading.word =~ '<head[^>]*>'
    let heading.level = 1
    let heading.word = 'Head'
  else
    let level = str2nr(matchstr(a:heading_line, '<[hH]\zs[1-6]\ze[^>]*>'))
    let heading.level = level
    let heading.word = 'H' . level . '. ' . s:get_text_content(level, a:context)
  endif
  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

function! s:get_text_content(level, context)
  let h_lnum = a:context.heading_lnum
  let text = s:Util.join_to(a:context, h_lnum, '</[hH]' . a:level . '[^>]*>')
  let text = substitute(text, '\n', '', 'g')
  let text = substitute(text, '<[^>]*>', '', 'g')
  return text
endfunction

" vim: filetype=vim
