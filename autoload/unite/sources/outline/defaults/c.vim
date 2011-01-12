"=============================================================================
" File    : autoload/unite/sources/outline/defaults/c.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C
" Version: 0.0.2 (draft)

function! unite#sources#outline#defaults#c#outline_info()
  return s:outline_info
endfunction

" sub patterns
let s:define_macro = '\s*#\s*define\s\+\h\w*('
let s:func_def = '\(\h\w*\(\s\+\|\s*\*\s*\)\)*\h\w*\s*('

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('c', 'heading-1'),
      \ 'heading'  : '^\(' . s:define_macro . '\|' . s:func_def . '\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('c', 'header'),
      \ },
      \}

" FIXME: This implementation assumes that the source code is properly
" indented. Therefore, if the source code is not indented at all, function
" calls will matches as function definitions.

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1'
    let heading.type = 'comment'
    if a:matched_line =~ '^\s'
      let heading.level = 4
    elseif strlen(substitute(a:matched_line, '\s*', '', 'g')) > 40
      let heading.level = 1
    else
      let heading.level = 2
    endif
  elseif a:which == 'heading'
    let heading.level = 3
    if a:heading_line =~ '^\s*#\s*define\>'
      let heading.type = 'directive'
      let heading.word = s:normalize_define_macro_heading_word(heading.word)
    elseif a:heading_line =~ ';\s*$'
      " it's a declaration, not a definition
      let heading.level = 0
    else
      let heading.type = 'function'
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

function! s:normalize_define_macro_heading_word(heading_word)
  let heading_word = substitute(a:heading_word, '#\s*define', '#define', '')
  let heading_word = substitute(heading_word, ')\zs.*$', '', '')
  return heading_word
endfunction

" vim: filetype=vim
