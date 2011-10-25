"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-10-26
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby
" Version: 0.1.2

function! unite#sources#outline#defaults#ruby#outline_info(...)
  if a:0
    " Redirect to DSL's outline info.
    let context = a:1
    let path = context.buffer.path
    if path =~ '_spec\.rb$'
      " RSpec
      let oinfo = unite#sources#outline#get_outline_info('ruby/rspec')
    else
      let oinfo = s:outline_info
    endif
  else
    let oinfo = s:outline_info
  endif
  return oinfo
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'name': 'Ruby',
      \ 'heading-1': s:Util.shared_pattern('sh', 'heading-1'),
      \ 'heading_keywords': [
      \   'module', 'class',
      \   'def', 'attr_\(accessor\|reader\|writer\)', 'alias',
      \   'BEGIN', 'END', '__END__',
      \   ],
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
      \     'pattern'  : '/:\@<! \zs\%(=>\)\@![_[:alnum:]=\[\]<>!?.]\+/' },
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

function! s:outline_info.initialize()
  let self.heading = '^\s*\(' . join(self.heading_keywords, '\|') . '\)\>'
endfunction

" NOTE: In Ruby, not a few developers indent non-public methods one more
" primarily for readability. Because this convention causes an incorrect
" structured tree, we can't use the level of indentation as the heading level
" of a method. To correct the level of non-public methods, I use a stack for
" keeping track of the current scope level.

function! s:outline_info.before(context)
  let s:scope_levels = map(range(20), 3)
  let s:slp = 0
endfunction

function! s:scope_level()
  return s:scope_levels[s:slp]
endfunction

function! s:scope_in(level)
  let s:slp += 1
  let s:scope_levels[s:slp] = a:level
endfunction

function! s:scope_out()
  let s:slp -= 1
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let word = a:heading_line
  let type = 'generic'
  let level = 0

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let m_lnum = a:context.matched_lnum
    let type = 'comment'
    let level = s:Util.get_comment_heading_level(a:context, m_lnum)

  elseif a:which == 'heading'
    let h_lnum = a:context.heading_lnum
    let level = s:Util.get_indent_level(a:context, h_lnum) + 3
    " NOTE: Level 1 to 3 are reserved for toplevel comment headings.

    while level <= s:scope_level()
      call s:scope_out()
    endwhile

    let matches = matchlist(a:heading_line, self.heading)
    let keyword = matches[1]
    let type = keyword

    if keyword == 'module' || keyword == 'class'
      if word =~ '\s\+<<\s\+'
        " Eigen-class
        let type = 'eigen_class'
      else
        " Module, Class
        let word = matchstr(word, '^\s*\%(module\|class\)\s\+\zs\h\w*') . ' : ' . keyword
      endif
      call s:scope_in(level)
    elseif keyword == 'def'
      if word =~ '#{'
        " Meta-method
        let type = 'meta_method'
      else
        " Method
        let type = 'method'
        let word = substitute(word, '\<def\s*', '', '')
      endif
      let word = substitute(word, '\S\zs(', ' (', '')
    elseif keyword =~ '^attr_'
      " Accessor
      let type = 'method'
      let access = matches[2]
      let word = substitute(word, '\<attr_\w\+\s*', '', '')
      let word = substitute(word, '\s*:', ' ', 'g') . ' : ' . access
    elseif keyword == 'alias'
      " Alias
      let type = 'method'
      let word = substitute(word, '\<alias\s*', '', '')
      let word = substitute(word, ':\=\(\S\+\)\s\+:\=\(\S\+\)', '\1 => \2', '')
    elseif keyword =~ '^\%(BEGIN\|END\)$'
      " BEGIN, END
      let word = substitute(word, '\s*{.*$', '', '')
    else
      " __END__
    endif
    let word = substitute(word, '\%(;\|#{\@!\).*$', '', '')

    if type == 'method'
      " Correct the method's level.
      let level = s:scope_level() + 1
    endif
  endif

  if level > 0
    let heading = {
          \ 'word' : word,
          \ 'level': level,
          \ 'type' : type,
          \ }
    return heading
  else
    return {}
  endif
endfunction

function! s:outline_info.need_blank_between(cand1, cand2, memo)
  if a:cand1.source__heading_group == 'method' && a:cand2.source__heading_group == 'method'
    " Don't insert a blank between two sibling methods.
    return 0
  else
    return (a:cand1.source__heading_group != a:cand2.source__heading_group ||
          \ a:cand1.source__has_marked_child || a:cand2.source__has_marked_child)
  endif
endfunction

" vim: filetype=vim
