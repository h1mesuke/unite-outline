"=============================================================================
" File    : autoload/unite/sources/outline/defaults/html.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-28
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for HTML
" Version: 0.0.5

function! unite#sources#outline#defaults#html#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading': '<[hH][1-6][^>]*>',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = str2nr(matchstr(a:heading_line, '<[hH]\zs[1-6]\ze[^>]*>'))
  let heading = {
        \ 'word' : "h" . level . ". " . s:get_text_content(level, a:context),
        \ 'level': level,
        \ 'type' : 'generic',
        \ }
  return heading
endfunction

function! s:get_text_content(level, context)
  let text = unite#sources#outline#
        \util#join_to(a:context, a:context.heading_lnum, '</[hH]' . a:level . '[^>]*>')
  let text = substitute(text, '\n', '', 'g')
  let text = substitute(text, '<[^>]*>', '', 'g')
  return text
endfunction

" vim: filetype=vim
