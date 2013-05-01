" ------------- - ------------------------------------------------------------
" File          : autoload/unite/sources/outline/defaults/cram.vim
" Author        : Zhao Cai
" Email         : caizhaoff@gmail.com
" URL           : http://bitbucket.org/brodie/cram
" Version       : 0.1
" Date Created  : Wed 25 Jul 2012 03:28:54 PM EDT
" Last Modified : Sat 04 Aug 2012 05:47:45 PM EDT
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
" ------------- - ------------------------------------------------------------

" Default outline info for cram test files
"

function! unite#sources#outline#defaults#cram#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^[a-zA-Z][a-zA-Z ]*[a-zA-Z]:$',
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 1,
        \ 'type' : 'cramSectionHeading'
        \ }

    return heading
endfunction
