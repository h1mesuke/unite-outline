"=============================================================================
" File    : autoload/unite/sources/outline/defaults/html.vim
" Author  : h1mesuke
" Updated : 2010-11-10
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for HTML

function! unite#sources#outline#defaults#html#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading' : '<[hH][1-6][^>]*>',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  if a:which ==# 'heading'
    let level = str2nr(matchstr(a:heading_line, '<[hH]\zs[1-6]\ze[^>]*>'))
    let text = substitute(substitute(a:heading_line, '<[^>]*>', '', 'g'), '^\s*', '', '')
    return unite#sources#outline#indent(level) . "h" . level. ". " . text
  endif
  return ""
endfunction

" vim: filetype=vim
