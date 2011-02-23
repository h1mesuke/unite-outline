" unite-outline's info for Scala.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#outline#defaults#scala#outline_info()
  return s:info
endfunction

let s:header_pattern = '\v^\s*%(\w+\s+)*\zs<%(class|object|trait|def)>'
let s:info = {
\   'heading': s:header_pattern,
\   'skip': {
\     'header': unite#sources#outline#util#shared_pattern('cpp', 'header'),
\   },
\ }

function! s:info.create_heading(which, heading_line, matched_line, context)
  let word = matchstr(a:heading_line, '^.\{-}\ze\%(\s\+=\%(\s.*\)\?\|\s*{\s*\)\?$')
  let type = matchstr(a:matched_line, s:header_pattern)
  return {
  \   'word': word,
  \   'level': unite#sources#outline#util#get_indent_level(
  \                          a:heading_line, a:context),
  \   'type': type,
  \ }
endfunction


let &cpo = s:save_cpo
