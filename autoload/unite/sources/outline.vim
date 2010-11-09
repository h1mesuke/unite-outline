"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke
" Updated : 2010-11-09
" Version : 0.0.3
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

function! unite#sources#outline#define()
  return s:source
endfunction

scriptencoding utf-8

let s:shared_pattern = {
      \ 'c_header'     : ['^/\*', '\*/\s*$'],
      \ 'c_heading-1'  : '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \ 'cpp_header': {
      \   'leading'    : '^//',
      \   'block'      : ['^/\*', '\*/\s*$'],
      \ },
      \ 'cpp_heading-1': '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
      \ 'sh_header'    : '^#',
      \ 'sh_heading-1' : '^\s*#\s*[-=#]\{10,}\s*$',
      \ }

let s:defalut_outline_patterns = {
      \ 'css': {
      \   'heading-1'  : s:shared_pattern['c_heading-1'],
      \   'skip_header': {
      \     'leading'  : '^@charset',
      \     'block'    : s:shared_pattern.c_header,
      \   },
      \ },
      \ 'help': {
      \   'heading-1'  : '^[-=]\{10,}\s*$',
      \ },
      \ 'html': {
      \   'heading'    : '<[hH][1-6][^>]*>',
      \ },
      \ 'dosini': {
      \   'heading'    : '^\s*\[[^\]]\+\]',
      \ },
      \ 'javascript': {
      \   'heading-1'  : s:shared_pattern['cpp_heading-1'],
      \   'heading'    : '^\s*\(var\s\+\u\w*\s\+=\s\+{\|function\>\)',
      \   'skip_header': s:shared_pattern.cpp_header,
      \ },
      \ 'mkd': {
      \   'heading'    : '^#\+',
      \   'heading+1'  : '^[-=]\+$',
      \ },
      \ 'perl': {
      \   'heading-1'  : s:shared_pattern['sh_heading-1'],
      \   'heading'    : '^\s*sub\>',
      \   'skip_header': s:shared_pattern.sh_header,
      \   'skip_begin' : '^=\(cut\)\@!\w\+',
      \   'skip_end'   : '^=cut',
      \ },
      \ 'php': {
      \   'heading-1'  : s:shared_pattern['cpp_heading-1'],
      \   'heading'    : '^\s*\(class\|function\)\>',
      \   'skip_header': {
      \     'leading'  : '^\(<?php\|//\)',
      \     'block'    : s:shared_pattern.c_header,
      \   },
      \ },
      \ 'python': {
      \   'heading-1'  : s:shared_pattern['sh_heading-1'],
      \   'heading'    : '^\s*\(class\|def\)\>',
      \   'skip_header': s:shared_pattern.sh_header,
      \ },
      \ 'ruby': {
      \   'heading-1'  : s:shared_pattern['sh_heading-1'],
      \   'heading'    : '^\s*\(module\|class\|def\)\>',
      \   'skip_header': s:shared_pattern.sh_header,
      \   'skip_begin' : '^=begin',
      \   'skip_end'   : '^=end',
      \ },
      \ 'sh': {
      \   'heading-1'  : s:shared_pattern['sh_heading-1'],
      \   'heading'    : '^\s*\(\w\+()\|function\>\)',
      \   'skip_header': s:shared_pattern.sh_header,
      \ },
      \ 'text': {
      \   'heading'    : '^\s*\([■□●○◎▲△▼▽★☆]\|[１２３４５６７８９０]\+、\|\d\+\. \|\a\. \)',
      \ },
      \ 'vim': {
      \   'heading-1'  : '^\s*"\s*[-=]\{10,}\s*$',
      \   'heading'    : '^\s*fu\%[nction]!\= ',
      \   'skip_header': '^"',
      \ },
      \}

scriptencoding

" aliases
let s:defalut_outline_patterns.cfg   = s:defalut_outline_patterns.dosini
let s:defalut_outline_patterns.xhtml = s:defalut_outline_patterns.html
let s:defalut_outline_patterns.zsh   = s:defalut_outline_patterns.sh

if !exists('g:unite_source_outline_patterns')
  let g:unite_source_outline_patterns = {}
endif
call extend(g:unite_source_outline_patterns, s:defalut_outline_patterns, 'keep')

let s:source = {
      \ 'name': 'outline',
      \ }

function! s:source.gather_candidates(args, context)
  let filetype = getbufvar('#', '&filetype')
  if !has_key(g:unite_source_outline_patterns, filetype)
    return []
  endif

  if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
    let start_time = reltime()
  endif

  let path = expand('#:p')
  let pattern = g:unite_source_outline_patterns[filetype]
  let lines = getbufline('#', 1, '$')
  let lnum_width = strlen(len(lines))

  " skip the header of the file
  let ofs = 0
  if has_key(pattern, 'skip_header')
    let val_type = type(pattern.skip_header)
    if val_type == type("")
      let head_lead_pat = pattern.skip_header
    elseif val_type == type([])
      let head_beg_pat = pattern.skip_header[0]
      let head_end_pat = pattern.skip_header[1]
    elseif val_type == type({})
      let head_lead_pat = pattern.skip_header.leading
      let head_beg_pat = pattern.skip_header.block[0]
      let head_end_pat = pattern.skip_header.block[1]
    endif
    let n_lines = len(lines)
    let line = lines[0]
    while ofs < n_lines
      let line = lines[ofs]
      if exists('head_beg_pat') && line =~# head_beg_pat
        let ofs += 1
        while ofs < n_lines
          let line = lines[ofs]
          if line =~# head_end_pat
            break
          endif
          let ofs += 1
        endwhile
        let ofs += 1
      elseif exists('head_lead_pat') && line =~# head_lead_pat
        let ofs += 1
        while ofs < n_lines
          let line = lines[ofs]
          if line !~# head_lead_pat
            break
          endif
          let ofs += 1
        endwhile
      else
        break
      endif
    endwhile
    let lines = lines[ofs :]
  endif

  " eval once
  let has_skip_beg_pat = has_key(pattern, 'skip_begin')
  if has_skip_beg_pat
    let skip_beg_pat = pattern.skip_begin
    let skip_end_pat = pattern.skip_end
  endif
  let has_head_p1_pat = has_key(pattern, 'heading-1')
  if has_head_p1_pat
    let head_p1_pat = pattern['heading-1']
  endif
  let has_head_pat = has_key(pattern, 'heading')
  if has_head_pat
    let head_pat = pattern.heading
  endif
  let has_head_n1_pat = has_key(pattern, 'heading+1')
  if has_head_n1_pat
    let head_n1_pat = pattern['heading+1']
  endif
  " collect heading lines
  let headings = []
  let idx = 0 | let n_lines = len(lines)
  while idx < n_lines
    let line = lines[idx]
    if has_skip_beg_pat && line =~# skip_beg_pat
      " skip a documentation block
      let idx += 1
      while idx < n_lines
        let line = lines[idx]
        if line =~# skip_end_pat
          break
        endif
        let idx += 1
      endwhile
    elseif has_head_p1_pat && line =~# head_p1_pat
      let next_line = lines[idx + 1]
      if next_line =~ '[[:punct:]]\@!\S'
        call add(headings, [ofs + idx + 2, next_line])
      else
        let next_line = lines[idx + 2]
        if next_line =~ '[[:punct:]]\@!\S'
          call add(headings, [ofs + idx + 3, next_line])
        endif
      endif
      let idx += 1
    elseif has_head_pat && line =~# head_pat
      call add(headings, [ofs + idx + 1, line])
    elseif has_head_n1_pat && line =~# head_n1_pat && idx > 0
      let prev_line = lines[idx - 1]
      if prev_line =~ '[[:punct:]]\@!\S'
        call add(headings, [ofs + idx, prev_line])
      endif
    endif
    let idx += 1
  endwhile

  let format = '%' . lnum_width . 'd: %s'
  let cands = map(headings, '{
        \ "word": printf(format, v:val[0], v:val[1]),
        \ "source": "outline",
        \ "kind": "jump_list",
        \ "action__path": path,
        \ "action__line": v:val[0],
        \ }')

  if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
    let used_time = split(reltimestr(reltime(start_time)))[0]
    echomsg "unite-outline: gather_candidates: Finished in " . used_time . " seconds."
  endif

  return cands
endfunction

" vim: filetype=vim
