"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.2.0

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

let s:Ctags = unite#sources#outline#import('Ctags')
let s:Util  = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading_groups': {
      \   'namespace': ['namespace'],
      \   'type'     : ['class', 'enum', 'struct', 'typedef'],
      \   'function' : ['function', 'macro'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \   ' => .*',
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'   : 'parameter_list',
      \     'pattern': '/\%(=> .*\)\@<!\zs([^=]*)/' },
      \   { 'name'   : 'type',
      \     'pattern': '/\S\+\ze\%( #\d\+\)\= : \%(class\|enum\|struct\|typedef\)/' },
      \   { 'name'   : 'function',
      \     'pattern': '/\%(=> .*\)\@<!\(operator\>.*\|\h\w*\)\ze\s*(/' },
      \   { 'name'   : 'macro',
      \     'pattern': '/\h\w*\ze .*=> /' },
      \   { 'name'   : 'expanded',
      \     'pattern': '/ => \zs.*/' },
      \   { 'name'   : 'id',
      \     'pattern': '/ \zs#\d\+/' },
      \ ],
      \}

function! s:outline_info.extract_headings(context)
  return s:Ctags.extract_headings(a:context)
endfunction
