"=============================================================================
" File    : autoload/unite/sources/outline/defaults/scala.vim
" Author  : thinca <thinca+vim@gmail.com>
" Updated : 2011-02-24
"
" License : Creative Commons Attribution 2.1 Japan License
"           <http://creativecommons.org/licenses/by/2.1/jp/deed.en>
"
"=============================================================================

" Default outline info for Scala
" Version: 0.1.0

function! unite#sources#outline#defaults#scala#outline_info()
  return s:outline_info
endfunction

let s:header_pattern = '\v^\s*%(\w+\s+)*\zs<%(class|object|trait|def)>'
let s:outline_info = {
      \  'heading-1': unite#sources#outline#util#shared_pattern('cpp', 'heading-1'),
      \  'heading'  : s:header_pattern,
      \  'skip': {
      \    'header': unite#sources#outline#util#shared_pattern('cpp', 'header'),
      \  },
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let level = unite#sources#outline#
        \util#get_indent_level(a:context, a:context.heading_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && unite#sources#outline#
        \util#_cpp_is_in_comment(a:heading_line, a:matched_line)
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:context, a:context.matched_lnum)
  elseif a:which == 'heading'
    let heading.type = matchstr(a:matched_line, s:header_pattern)
    let heading.word = matchstr(a:heading_line, '^.\{-}\ze\%(\s\+=\%(\s.*\)\?\|\s*{\s*\)\?$')
  endif

  return heading
endfunction

" vim: filetype=vim
