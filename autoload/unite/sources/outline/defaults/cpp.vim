"=============================================================================
" File    : autoload/unite/sources/outline/defaults/cpp.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-27
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for C++
" Version: 0.0.6

function! unite#sources#outline#defaults#cpp#outline_info()
  return s:outline_info
endfunction

"---------------------------------------
" Sub Patterns

let s:func_macro = '#\s*define\s\+\h\w*('
let s:typedef = '\%(typedef\|enum\)\>'

let s:class_def = '\%(template\s*<[^>]*>\s*\)\=class\>'

let s:ret_type = '\%(\%(<[^>]*>\|\h\w*\)\%(\s\+\|\s*[*&]\s*\)\)*'
let s:func_def = s:ret_type . '\~\=\h\w*\%(::\%(operator\S\+\|\~\=\h\w*\)\)*\s*('

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': unite#sources#outline#util#shared_pattern('cpp', 'heading-1'),
      \ 'heading'  : '^\(\s*\(' . s:func_macro . '\|' . s:typedef . '\)\|\(' . s:class_def . '\|' . s:func_def . '\)\)',
      \ 'skip': {
      \   'header': unite#sources#outline#util#shared_pattern('cpp', 'header'),
      \ },
      \}

" FIXME: This implementation assumes that the source code is properly
" indented. Therefore, if the source code is not indented at all, function
" calls will matches as function definitions.

function! s:outline_info.initialize(context)
  let s:class_names = []
  let s:class_names_pattern = ''
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && unite#sources#outline#
        \util#_cpp_is_in_comment(a:heading_line, a:matched_line)
    let heading.type = 'comment'
    let heading.level = unite#sources#outline#
          \util#get_comment_heading_level(a:matched_line, 6)
  elseif a:which == 'heading'
    let heading.level = 4
    let lines = a:context.lines | let h = a:context.heading_lnum
    if a:heading_line =~ '^\s*#\s*define\>'
      " #define ()
      let heading.type = '#define'
      let heading.word = unite#sources#outline#
            \util#_c_normalize_define_macro_heading_word(heading.word)
    elseif a:heading_line =~ '\<typedef\>'
      " typedef
      if a:heading_line =~ '{\s*$'
        let heading.type = 'typedef'
        let indent = matchstr(a:heading_line, '^\s*')
        let closing = unite#sources#outline#
              \util#neighbor_matchstr(lines, h, '^' . indent . '}.*$', [0, 50])
        let heading.word = substitute(heading.word, '{\s*$', '{...' . closing, '')
      else
        let heading.level = 0
      endif
    elseif a:heading_line =~ '\<enum\>'
      " enum
      if a:heading_line =~ '{\s*$'
        let heading.type = 'enum'
        let first_symbol_def = unite#sources#outline#
              \util#neighbor_matchstr(lines, h, '^\s*\zs\S.\{-},\=\ze\s*\%(/[/*]\|$\)', [0, 3], 1)
        let closing = (first_symbol_def =~ ',$' ? ' ...}' : ' }')
        let heading.word = substitute(heading.word, '{\s*$', '{ ' . first_symbol_def . closing, '')
      else
        let heading.level = 0
      endif
    elseif a:heading_line =~ '^class\>'
      " class
      let heading.type = 'class'
      let class_name = matchstr(a:heading_line, '^class\s\+\zs\h\w*\%(::\h\w*\)*')
      call s:rebuild_class_names_pattern(class_name)
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    else
      " function
      if a:heading_line =~ ';\s*$' || a:heading_line =~ '\<[[:upper:]_]\+\s*('
        " this is a function prototype or a functional macro application, not
        " a function definition
        let heading.level = 0
      else
        let heading.type = 'function'
        if !empty(s:class_names) && a:heading_line =~ s:class_names_pattern
          let heading.level += 1
        endif
        let heading.word = substitute(heading.word, '\s*{.*$', '', '')
      endif
    endif
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

function! s:rebuild_class_names_pattern(class_name)
  call add(s:class_names, a:class_name)
  let s:class_names_pattern = '\<\%(' . join(s:class_names, '\|') . '\)::'
endfunction

" vim: filetype=vim
