"=============================================================================
" File: autoload/unite/sources/outline/defaults/haskell.vim
" Author: igrep <whosekiteneverfly@gmail.com>
" Updated: 2013-01-03
" Version: 0.1.1
" TODO:
"     - support hspec, lhs, etc.
"     - how to handle comments?
" Referred To:
"     - http://www.cs.utep.edu/cheon/cs3360/pages/haskell-syntax.html
"     - http://www.sampou.org/haskell/report-revised-j/syntax-iso.html
"     - http://www.haskell.org/haskellwiki/Keywords
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

"*** for extracting headers
let s:type_declaration = 'data\|type\|newtype\|class\|instance'

let s:non_op_name = '\l[\w'']*'
let s:operator_name = '([!#$%&*+./<=>?@\\^|\-~]\+)'

let s:function_name = '\%(\%(' . s:non_op_name . '\)\|\%(' . s:operator_name . '\)\)'
let s:signature = s:function_name . '.*::'

let s:heading = '^\%(\%(' . s:type_declaration . '\)\|\%(' . s:signature . '\)\)'

" Don't need to skip line comment.
" Because the header starts with '^'
let s:skip = { 'block': ['{-', '-}'] }

let s:outline_info = {
      \ 'heading': s:heading,
      \ 'skip': s:skip
      \ }

"*** for extracting name
let s:type_name = '\u[\w]*'
let s:beginning_function_name = '^' . s:function_name

function! s:outline_info.create_heading( which, heading_line, matched_line, context )
  return { 'word': a:heading_line }
endfunction

function! unite#sources#outline#defaults#haskell#outline_info()
  return s:outline_info
endfunction
