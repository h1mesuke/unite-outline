"=============================================================================
" File: autoload/unite/sources/outline/defaults/jade.vim
" Author: Jens Himmelreich <jens.himmelreich@gmail.com>
" Version: 0.1.0
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"=============================================================================
let s:Util = unite#sources#outline#import('Util')
let s:MaxLevel = 4

let s:heading = '^\s\{,' . s:MaxLevel . '}\S\+'

let s:outline_info = {
      \ 'heading': s:heading
      \ }

function! unite#sources#outline#defaults#jade#outline_info()
  return s:outline_info
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  let level = s:Util.get_indent_level(a:context, h_lnum)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }
  return heading
endfunction
