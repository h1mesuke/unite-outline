"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke
" Updated : 2010-11-08
" Version : 0.0.1
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

let s:defalut_outline_patterns = {
      \ 'help': {
      \   'heading': '\*\S\+\*',
      \ },
      \ 'ruby': {
      \   'heading-1': '^#[-=#]\{10,}\s*$',
      \   'heading': '^\s*\(module\|class\|def\) ',
      \   'skip_header': '^#',
      \ },
      \ 'vim': {
      \   'heading-1': '^"[-=]\{10,}\s*$',
      \   'heading': '^\s*function!\= ',
      \   'skip_header': '^"',
      \ },
      \}

if !exists('g:unite_source_outline_patterns')
  let g:unite_source_outline_patterns = {}
endif
call extend(g:unite_source_outline_patterns, s:defalut_outline_patterns, 'keep')

function! unite#sources#outline#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'outline',
      \ }

function! s:source.gather_candidates(args, context)
  let filetype = getbufvar('#', '&filetype')
  if !has_key(g:unite_source_outline_patterns, filetype)
    return []
  endif

  let path = expand('#:p')
  let patterns = g:unite_source_outline_patterns[filetype]
  let lines = getbufline('#', 1, '$')

  if has_key(patterns, 'skip_header')
    let pat = patterns.skip_header
    let idx = 0
    for line in lines
      if line !~# pat
        break
      endif
      let idx += 1
    endfor
    let lines = lines[idx :]
  endif

  let has_pat_1 = has_key(patterns, 'heading-1')
  if has_pat_1
    let pat_1 = patterns['heading-1']
  endif
  let has_pat = has_key(patterns, 'heading')
  if has_pat
    let pat = patterns.heading
  endif
  " collect heading lines
  let headings = []
  let idx = 0 | let n_lines = len(lines)
  while idx < n_lines
    let line = lines[idx]
    if has_pat_1 && line =~# pat_1
      call add(headings, [idx + 2, lines[idx + 1]])
      let idx += 2
      continue
    endif
    if has_pat && line =~# pat
      call add(headings, [idx + 1, line])
    endif
    let idx += 1
  endwhile

  let format = '%' . strlen(len(lines)) . 'd: %s'
  return map(headings, '{
        \ "word": printf(format, v:val[0], v:val[1]),
        \ "source": "outline",
        \ "kind": "jump_list",
        \ "action__path": path,
        \ "action__line": v:val[0],
        \ }')
endfunction

" vim: filetype=vim
