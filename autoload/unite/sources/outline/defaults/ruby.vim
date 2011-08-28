"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-29
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby
" Version: 0.1.0

function! unite#sources#outline#defaults#ruby#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\%(\s*\%(module\|class\|def\|BEGIN\|END\)\>\|__END__$\)',
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \
      \ 'heading_groups': {
      \   'type'  : ['module', 'class'],
      \   'method': ['method'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'     : 'comment',
      \     'pattern'  : '/#.*/' },
      \   { 'name'     : 'method',
      \     'pattern'  : '/:\@<! \zs[_[:alnum:]=\[\]<>!?.]\+/' },
      \   { 'name'     : 'type',
      \     'pattern'  : '/\S\+\ze : \%(module\|class\)/' },
      \   { 'name'     : 'eigen_class',
      \     'pattern'  : '/\<class\s\+<<\s\+.*/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'meta_method',
      \     'pattern'  : '/\<def\s\+[^(]*/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'parameter_list',
      \     'pattern'  : '/(.*)/' },
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

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)
  elseif a:which == 'heading'
    if a:heading_line =~ '^\s*\%(BEGIN\|END\)\>'
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
    endif
    if heading.word =~ '^\s*module\>'
      " module
      let heading.type = 'module'
      let heading.word = matchstr(heading.word, '^\s*module\s\+\zs\h\w*') . ' : module'
    elseif heading.word =~ '^\s*class\>'
      if heading.word =~ '\s\+<<\s\+'
        " eigen class
        let heading.type = 'eigen_class'
      else
        " class
        let heading.type = 'class'
        let heading.word = matchstr(heading.word, '^\s*class\s\+\zs\h\w*') . ' : class'
      endif
    elseif heading.word =~ '^\s*def\>'
      if heading.word =~ '#{'
        " meta method
        let heading.type = 'meta_method'
      else
        " method
        let heading.type = 'method'
        let heading.word = substitute(heading.word, '\<def\s*', '', '')
      endif
      let heading.word = substitute(heading.word, '\S\zs(', ' (', '')
    endif
    let heading.word = substitute(heading.word, '\%(;\|#{\@!\).*$', '', '')
  endif
  return heading
endfunction

function! s:outline_info.need_blank_between(head1, head2, memo)
  if a:head1.group == 'method' && a:head2.group == 'method'
    " Don't insert a blank between two sibling methods.
    return 0
  else
    return (a:head1.group != a:head2.group ||
          \ s:Util.has_marked_child(a:head1, a:memo) ||
          \ s:Util.has_marked_child(a:head2, a:memo))
  endif
endfunction

" vim: filetype=vim
