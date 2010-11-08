"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke
" Updated : 2010-11-08
" Version : 0.0.2
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

function! unite#sources#outline#define()
  return s:source
endfunction

let s:shared_pattern = {
      \ 'skip_header_c'  : '^\(/\*\|\s*\*\)',
      \ 'skip_header_cpp': '^\(//\|/\*\|\s*\*\)',
      \ 'skip_header_sh' : '^#',
      \ 'heading-1_c'    : '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \ 'heading-1_cpp'  : '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
      \ 'heading-1_sh'   : '^\s*#\s*[-=#]\{10,}\s*$',
      \ }

let s:defalut_outline_patterns = {
      \ 'css': {
      \   'heading-1'  : s:shared_pattern['heading-1_c'],
      \   'skip_header': s:shared_pattern.skip_header_c,
      \ },
      \ 'help': {
      \   'heading': '\*\S\+\*',
      \ },
      \ 'html': {
      \   'heading'    : '<[hH][1-6][^>]*>',
      \ },
      \ 'dosini': {
      \   'heading'    : '^\s*\[[^\]]\+\]',
      \ },
      \ 'javascript': {
      \   'heading-1'  : s:shared_pattern['heading-1_cpp'],
      \   'heading'    : '^\s*\(var\s\+\u\w*\s\+=\s\+{\|function\>\)',
      \   'skip_header': s:shared_pattern.skip_header_cpp,
      \ },
      \ 'perl': {
      \   'heading-1'  : s:shared_pattern['heading-1_sh'],
      \   'heading'    : '^\s*sub\>',
      \   'skip_header': s:shared_pattern.skip_header_sh,
      \ },
      \ 'php': {
      \   'heading-1'  : s:shared_pattern['heading-1_cpp'],
      \   'heading'    : '^\s*\(class\|function\)\>',
      \   'skip_header': '^\(<?php\|\(//\|/\*\|\s\*\)\)',
      \ },
      \ 'python': {
      \   'heading-1'  : s:shared_pattern['heading-1_sh'],
      \   'heading'    : '^\s*\(class\|def\)\>',
      \   'skip_header': s:shared_pattern.skip_header_sh,
      \ },
      \ 'ruby': {
      \   'heading-1'  : s:shared_pattern['heading-1_sh'],
      \   'heading'    : '^\s*\(module\|class\|def\)\>',
      \   'skip_header': s:shared_pattern.skip_header_sh,
      \ },
      \ 'sh': {
      \   'heading-1'  : s:shared_pattern['heading-1_sh'],
      \   'heading'    : '^\s*\(\w\+()\|function\>\)',
      \   'skip_header': s:shared_pattern.skip_header_sh,
      \ },
      \ 'vim': {
      \   'heading-1'  : '^\s*"\s*[-=]\{10,}\s*$',
      \   'heading'    : '^\s*fu\%[nction]!\= ',
      \   'skip_header': '^"',
      \ },
      \}

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

  if exists('g:unite_source_outline_debug') && g:unite_source_outline_debug && has("reltime")
    let start_time = reltime()
  endif

  let path = expand('#:p')
  let patterns = g:unite_source_outline_patterns[filetype]
  let lines = getbufline('#', 1, '$')

  let ofs = 0
  if has_key(patterns, 'skip_header')
    let pat = patterns.skip_header
    for line in lines
      if line !~# pat
        break
      endif
      let ofs += 1
    endfor
    let lines = lines[ofs :]
  endif

  " eval once
  let has_pat_p1 = has_key(patterns, 'heading-1')
  if has_pat_p1
    let pat_p1 = patterns['heading-1']
  endif
  let has_pat = has_key(patterns, 'heading')
  if has_pat
    let pat = patterns.heading
  endif
  let has_pat_n1 = has_key(patterns, 'heading+1')
  if has_pat_n1
    let pat_n1 = patterns['heading+1']
  endif
  " collect heading lines
  let headings = []
  let idx = 0 | let n_lines = len(lines)
  while idx < n_lines
    let line = lines[idx]
    if has_pat_p1 && line =~# pat_p1
      call add(headings, [ofs + idx + 2, lines[idx + 1]])
      let idx += 2
      continue
    endif
    if has_pat && line =~# pat
      call add(headings, [ofs + idx + 1, line])
    elseif has_pat_n1 && line =~# pat_n1 && idx > 0
      call add(headings, [ofs + idx - 1, line])
    endif
    let idx += 1
  endwhile

  let format = '%' . strlen(len(lines)) . 'd: %s'
  let cands = map(headings, '{
        \ "word": printf(format, v:val[0], v:val[1]),
        \ "source": "outline",
        \ "kind": "jump_list",
        \ "action__path": path,
        \ "action__line": v:val[0],
        \ }')

  if exists('g:unite_source_outline_debug') && g:unite_source_outline_debug && has("reltime")
    let used_time = split(reltimestr(reltime(start_time)))[0]
    echomsg "unite-outline: gather_candidates: Finished in " . used_time . " seconds."
  endif

  return cands
endfunction

" vim: filetype=vim
