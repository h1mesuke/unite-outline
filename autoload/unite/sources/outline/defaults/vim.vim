"=============================================================================
" File    : autoload/unite/sources/outline/defaults/vim.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Vim script
" Version: 0.1.5

function! unite#sources#outline#defaults#vim#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': '^\s*"\s*[-=]\{10,}\s*$',
      \ 'heading'  : '^\%(augroup\s\+\%(END\>\)\@!\|\s*fu\%[nction]!\= \)',
      \
      \ 'skip': { 'header': '^"' },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'     : 'comment',
      \     'pattern'  : '/".*/' },
      \   { 'name'     : 'augroup',
      \     'pattern'  : '/\S\+\ze : augroup/',
      \     'highlight': unite#sources#outline#get_highlight('type') },
      \   { 'name'     : 'function',
      \     'pattern'  : '/\S\+\ze\s*(/' },
      \   { 'name'     : 'parameter_list',
      \     'pattern'  : '/(.*)/' },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading-1' && a:heading_line =~ '^\s*"'
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum, 5)
  elseif a:which ==# 'heading'
    let heading.level = 4
    if heading.word =~ '^augroup '
      let heading.type = 'augroup'
      let heading.word = substitute(heading.word, '^augroup\s\+', '', '') . ' : augroup'
    else
      let heading.type = 'function'
      let heading.word = substitute(heading.word, '^\s*fu\%[nction]!\=', '', '')
      let heading.word = substitute(heading.word, '\S\zs(', ' (', '')
    endif
  endif

  if heading.level > 0
    let heading.word = substitute(heading.word, '"\=\s*{{{\d\=\s*$', '', '')
    return heading
  else
    return {}
  endif
endfunction
