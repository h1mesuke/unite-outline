"=============================================================================
" File    : autoload/unite/sources/outline/defaults/scala.vim
" Author  : thinca <thinca+vim@gmail.com>
" Updated : 2012-01-11
"
" License : Creative Commons Attribution 2.1 Japan License
"           <http://creativecommons.org/licenses/by/2.1/jp/deed.en>
"
"=============================================================================

" Default outline info for Scala
" Version: 0.1.3

function! unite#sources#outline#defaults#scala#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"---------------------------------------
" Sub Pattern

let s:pat_heading = '^\s*\%(\h\w*\s\+\)*\zs\<\%(class\|object\|trait\|def\)\>'

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \  'heading-1': s:Util.shared_pattern('cpp', 'heading-1'),
      \  'heading'  : s:pat_heading,
      \
      \  'skip': {
      \    'header': s:Util.shared_pattern('cpp', 'header'),
      \  },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'after_lbracket'),
      \   s:Util.shared_pattern('*', 'after_lparen'),
      \   s:Util.shared_pattern('*', 'after_colon'),
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  " Level 1 to 3 are reserved for comment headings.
  let level = s:Util.get_indent_level(a:context, h_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && s:Util._cpp_is_in_comment(a:heading_line, a:matched_line)
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)
  elseif a:which == 'heading'
    let heading.type = matchstr(a:matched_line, s:pat_heading)
    let heading.word = matchstr(a:heading_line, '^.\{-}\ze\%(\s\+=\%(\s.*\)\?\|\s*{\s*\)\?$')
  endif
  return heading
endfunction
