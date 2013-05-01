" ------------- - ------------------------------------------------------------
" File          : autoload/unite/sources/outline/defaults/snippets.vim
" Author        : Zhao Cai
" Email         : caizhaoff@gmail.com
" Date Created  : Wed 01 May 2013 02:02:36 AM EDT
" Last Modified : Wed 01 May 2013 02:02:37 AM EDT
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
" ------------- - ------------------------------------------------------------

" Default outline info for snippets files


function! unite#sources#outline#defaults#snippets#outline_info()
  return s:outline_info
endfunction

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^snippet',
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 1,
        \ 'type' : 'snippetHeading'
        \ }

    return heading
endfunction
