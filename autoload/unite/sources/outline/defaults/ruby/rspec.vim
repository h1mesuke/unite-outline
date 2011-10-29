"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby/rspec.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-10-29
"
" Contributed by kenchan
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby/RSpec
" Version: 0.1.1

function! unite#sources#outline#defaults#ruby#rspec#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

" Inherit Ruby's outline info.
let s:super = unite#sources#outline#get_outline_info('ruby', 1, 1)

let s:outline_info = deepcopy(s:super)
call extend(s:outline_info, {
      \ 'super': s:super,
      \
      \ 'rspec_heading_keywords': [
      \   'before', 'describe', 'its\=', 'after',
      \   'context', 'let!\=', 'specify', 'subject',
      \ ],
      \})

function! s:outline_info.initialize()
  let self.rspec_heading = '^\s*\(' . join(self.rspec_heading_keywords, '\|') . '\)\>'
  let self.heading_keywords += self.rspec_heading_keywords
  call call(self.super.initialize, [], self)
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let word = a:heading_line
  let type = 'generic'
  let level = 0

  if a:which == 'heading' && a:heading_line =~ self.rspec_heading
    let h_lnum = a:context.heading_lnum
    let level = s:Util.get_indent_level(a:context, h_lnum) + 3
    " NOTE: Level 1 to 3 are reserved for toplevel comment headings.

    let type = 'rspec'
    let word = substitute(word, '\s*\%(do\|{\)\%(\s*|[^|]*|\)\=\s*$', '', '')
    let word = substitute(word, '\%(;\|#{\@!\).*$', '', '')
  endif

  if level > 0
    let heading = {
          \ 'word' : word,
          \ 'level': level,
          \ 'type' : type,
          \ }
  else
    let heading = call(self.super.create_heading,
          \ [a:which, a:heading_line, a:matched_line, a:context], self.super)
  endif
  return heading
endfunction

" vim: filetype=vim
