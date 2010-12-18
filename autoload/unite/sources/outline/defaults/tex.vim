"=============================================================================
" File    : autoload/unite/sources/outline/defaults/tex.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-19
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for TeX
" Version: 0.0.6

function! unite#sources#outline#defaults#tex#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading': '^\\\(title\|part\|chapter\|\(sub\)\{,2}section\|begin{thebibliography}\){',
      \ }

let s:unit_order = [
      \ 'title',
      \ 'part',
      \ 'chapter',
      \ 'section',
      \ 'subsection',
      \ 'subsubsection',
      \ ]

let s:initial_unit_level = {}
let s:level = 1
for unit in s:unit_order
  let s:initial_unit_level[unit] = s:level
  let s:level += 1
endfor
unlet unit
unlet s:level

function! s:outline_info.initialize(context)
  let s:unit_count = {}
  for unit in s:unit_order
    let s:unit_count[unit] = 0
  endfor
  let s:unit_level = copy(s:initial_unit_level)
  let s:biggest_unit = 'subsubsection'
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let lines = a:context.lines | let h = a:context.heading_index
  if a:heading_line =~ '^\\begin{thebibliography}{'
    " Bibliography
    let level = 2
    let label = unite#sources#outline#util#neighbor_matchstr(
          \ lines, h, '\\renewcommand{\\bibname}{\zs.*\ze}\s*$', 3)
    let heading = (label == "" ? "Bibliography" : label)
  else
    " Parts, Chapters, Sections
    let unit = matchstr(a:heading_line, '^\\\zs\w\+\ze{')
    call s:add_unit(unit)
    if unit !=# 'title' && index(s:unit_order, unit) < index(s:unit_order, s:biggest_unit)
      call s:shift_unit_levels(unit)
      let s:biggest_unit = unit
    endif
    let level = s:unit_level[unit]
    let heading = unite#sources#outline#util#join_to(lines, h, '}\s*$')
    let heading = substitute(heading, '\\\\\n', '', 'g')
    let heading = matchstr(heading, '^\\\w\+{\zs.*\ze}\s*$')
    let heading = s:unit_seqnr_prefix(unit) . heading
  endif
  return unite#sources#outline#util#indent(level) . heading
endfunction

function! s:shift_unit_levels(unit)
  let level = 2
  for unit in s:unit_order[index(s:unit_order, a:unit) : ]
    let s:unit_level[unit] = level
    let level += 1
  endfor
endfunction

function! s:add_unit(unit)
  let s:unit_count[a:unit] += 1
  for unit in s:unit_order[index(s:unit_order, a:unit) + 1 : ]
    let s:unit_count[unit] = 0
  endfor
endfunction

function! s:unit_seqnr_prefix(unit)
  if a:unit ==# 'title'
    let seqnr = []
  elseif a:unit ==# 'part'
    let seqnr = [unite#sources#outline#util#nr2roman(s:unit_count.part)]
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
  if prefix != ""
    let prefix .= " "
  endif
  return prefix
endfunction

" vim: filetype=vim
