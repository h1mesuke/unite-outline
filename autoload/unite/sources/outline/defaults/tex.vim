"=============================================================================
" File    : autoload/unite/sources/outline/defaults/tex.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for TeX
" Version: 0.1.0

function! unite#sources#outline#defaults#tex#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^\s*\\\%(title\|part\|chapter\|\%(sub\)\{,2}section\|begin{thebibliography}\){',
      \}

let s:unit_level_map = {
      \ 'title'        : 1,
      \ 'part'         : 2,
      \ 'chapter'      : 3,
      \ 'section'      : 4,
      \ 'subsection'   : 5,
      \ 'subsubsection': 6,
      \ }

function! s:outline_info.before(context)
  let s:unit_count = map(copy(s:unit_level_map), '0')
  let s:bib_level = 6
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 0,
        \ 'type' : 'generic',
        \ }

  let h_lnum = a:context.heading_lnum
  if a:heading_line =~ '^\s*\\begin{thebibliography}{'
    " Bibliography
    let heading.level = s:bib_level
    let bib_label = s:Util.neighbor_matchstr(a:context, h_lnum,
          \ '\\renewcommand{\\bibname}{\zs.*\ze}\s*$', 3)
    let heading.word = (empty(bib_label) ? "Bibliography" : bib_label)
  else
    " Parts, Chapters, Sections, etc
    let unit = matchstr(a:heading_line, '^\s*\\\zs\w\+\ze{')
    let s:unit_count[unit] += 1
    let heading.level = s:unit_level_map[unit]
    if 1 < heading.level && heading.level < s:bib_level
      let s:bib_level = heading.level
    endif
    let heading.word = s:normalize_heading_word(
          \ s:Util.join_to(a:context, h_lnum, '}\s*$'), unit)
  endif

  if heading.level > 0
    return heading
  else
    return {}
  endif
endfunction

function! s:normalize_heading_word(word, unit)
  let word = substitute(a:word, '\\\\\n', '', 'g')
  let word = matchstr(word, '^\s*\\\w\+{\zs.*\ze}\s*$')
  let word = s:unit_seqnr_prefix(a:unit) . word
  return word
endfunction

function! s:unit_seqnr_prefix(unit)
  if a:unit ==# 'title'
    let seqnr = []
  elseif a:unit ==# 'part'
    let seqnr = [s:Util.String.nr2roman(s:unit_count.part)]
  elseif a:unit ==# 'chapter'
    let seqnr = [s:unit_count.chapter]
  elseif a:unit ==# 'section'
    if s:unit_count.chapter > 0
      let seqnr = [s:unit_count.chapter, s:unit_count.section]
    elseif a:unit ==# 'section'
      let seqnr = [s:unit_count.section]
    else
    endif
  elseif a:unit ==# 'subsection'
    if s:unit_count.chapter > 0
      let seqnr = [s:unit_count.chapter, s:unit_count.section, s:unit_count.subsection]
    else
      let seqnr = [s:unit_count.section, s:unit_count.subsection]
    endif
  elseif a:unit ==# 'subsubsection'
    if s:unit_count.chapter > 0
      let seqnr = [s:unit_count.section, s:unit_count.subsection, s:unit_count.subsubsection]
    else
      let seqnr = []
    endif
  endif
  let prefix = join(seqnr, '.')
  let prefix .= (!empty(prefix) ? " " : "")
  return prefix
endfunction
