"=============================================================================
" File    : autoload/unite/sources/outline/defaults/tex.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-13
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for TeX
" Version: 0.0.3

function! unite#sources#outline#defaults#tex#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading': '^\\\(title\|part\|chapter\|\(sub\)\{,2}section\){',
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
  let unit = matchstr(a:heading_line, '^\\\zs\w\+\ze{')
  call s:add_unit(unit)
  if unit !=# 'title' && index(s:unit_order, unit) < index(s:unit_order, s:biggest_unit)
    call s:shift_unit_levels(unit)
    let s:biggest_unit = unit
  endif
  let level = s:unit_level[unit]
  let lines = a:context.lines | let h = a:context.heading_index
  let heading = unite#sources#outline#join_to(lines, h, '}\s*$')
  let heading = substitute(heading, '\\\\\n', '', 'g')
  let heading = matchstr(heading, '^\\\w\+{\zs.*\ze}\s*$')
  let heading = unite#sources#outline#indent(level) . s:unit_seqnr_prefix(unit) . heading
  return heading
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
    let prefix = ""
  elseif a:unit ==# 'part'
    let prefix = s:nr2roman(s:unit_count.part)
  elseif a:unit ==# 'chapter'
    let prefix = s:unit_count.chapter
  elseif a:unit ==# 'section'
    if s:unit_count.chapter > 0
      let prefix = s:unit_count.chapter . "." . s:unit_count.section
    elseif a:unit ==# 'section'
      let prefix = s:unit_count.section
    else
    endif
  elseif a:unit ==# 'subsection'
    if s:unit_count.chapter > 0
      let prefix = s:unit_count.chapter . "." . s:unit_count.section . "." . s:unit_count.subsection
    else
      let prefix = s:unit_count.section . "." . s:unit_count.subsection
    endif
  elseif a:unit ==# 'subsubsection'
    if s:unit_count.chapter > 0
      let prefix = s:unit_count.section . "." . s:unit_count.subsection . "." . s:unit_count.subsubsection
    else
      let prefix = ""
    endif
  endif
  if prefix != ""
    let prefix .= " "
  endif
  return prefix
endfunction

" ported from:
" Sample code from Programing Ruby, page 145
"
function! s:nr2roman(nr)
  if a:nr <= 0 || 4999 < a:nr
    return string(a:nr)
  endif
  let factors = [
        \ ["M", 1000], ["CM", 900], ["D",  500], ["CD", 400],
        \ ["C",  100], ["XC",  90], ["L",   50], ["XL",  40],
        \ ["X",   10], ["IX",   9], ["V",    5], ["IV",   4],
        \ ["I",    1],
        \]
  let nr = a:nr
  let roman = ""
  for [code, factor] in factors
    let cnt = nr / factor
    let nr  = nr % factor
    if cnt > 0
      let roman .= repeat(code, cnt)
    endif
  endfor
  return roman
endfunction

" vim: filetype=vim
