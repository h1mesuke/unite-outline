"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke
" Updated : 2010-11-10
" Version : 0.0.5
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

function! unite#sources#outline#define()
  return s:source
endfunction

function! unite#sources#outline#indent(level)
  return printf('%*s', (a:level - 1) * g:unite_source_outline_indent_width, '')
endfunction

if !exists('g:unite_source_outline_info')
  let g:unite_source_outline_info = {}
endif
if !exists('g:unite_source_outline_indent_width')
  let g:unite_source_outline_indent_width = 2
endif

function! s:get_outline_info(filetype)
  if has_key(g:unite_source_outline_info, a:filetype)
    return g:unite_source_outline_info[a:filetype]
  else
    try
      execute 'let outline_info = unite#sources#outline#defaults#' . a:filetype . '#outline_info()'
      return outline_info
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      return {}
    endtry
  endif
endfunction

let s:source = {
      \ 'name': 'outline',
      \ }

function! s:source.gather_candidates(args, context)
  if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
    let start_time = reltime()
  endif

  let path = expand('#:p')
  let filetype = getbufvar('#', '&filetype')
  let outline_info = s:get_outline_info(filetype)
  if len(outline_info) == 0
    call unite#print_error("unite-outline: not supported filetype: " . filetype)
    return []
  endif

  let lines = getbufline('#', 1, '$')
  let lnum_width = strlen(len(lines))

  " skip the header of the file
  let ofs = 0
  if has_key(outline_info, 'skip') && has_key(outline_info.skip, 'header')
    let val_type = type(outline_info.skip.header)
    if val_type == type("")
      let head_lead_pat = outline_info.skip.header
    elseif val_type == type([])
      let head_beg_pat = outline_info.skip.header[0]
      let head_end_pat = outline_info.skip.header[1]
    elseif val_type == type({})
      let head_lead_pat = outline_info.skip.header.leading
      let head_beg_pat = outline_info.skip.header.block[0]
      let head_end_pat = outline_info.skip.header.block[1]
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
  let has_skip_beg_pat = has_key(outline_info, 'skip') && has_key(outline_info.skip, 'begin')
  if has_skip_beg_pat
    let skip_beg_pat = outline_info.skip.begin
    let skip_end_pat = outline_info.skip.end
  endif
  let has_head_p1_pat = has_key(outline_info, 'heading-1')
  if has_head_p1_pat
    let head_p1_pat = outline_info['heading-1']
  endif
  let has_head_pat = has_key(outline_info, 'heading')
  if has_head_pat
    let head_pat = outline_info.heading
  endif
  let has_head_n1_pat = has_key(outline_info, 'heading+1')
  if has_head_n1_pat
    let head_n1_pat = outline_info['heading+1']
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
        if has_key(outline_info, 'create_heading')
          let heading = outline_info.create_heading('heading-1', next_line, line,
                \ { 'heading_index': idx + 1, 'matched_index': idx, 'lines': lines })
          if heading != ""
            call add(headings, [ofs + idx + 2, heading])
          endif
        else
          call add(headings, [ofs + idx + 2, next_line])
        endif
      else
        let next_line = lines[idx + 2]
        if next_line =~ '[[:punct:]]\@!\S'
          if has_key(outline_info, 'create_heading')
            let heading = outline_info.create_heading('heading-1', next_line, line,
                  \ { 'heading_index': idx + 2, 'matched_index': idx, 'lines': lines })
            if heading != ""
              call add(headings, [ofs + idx + 3, heading])
            endif
          else
            call add(headings, [ofs + idx + 3, next_line])
          endif
        endif
      endif
      let idx += 1
    elseif has_head_pat && line =~# head_pat
      if has_key(outline_info, 'create_heading')
        let heading = outline_info.create_heading('heading', line, line,
              \ { 'heading_index': idx, 'matched_index': idx, 'lines': lines })
        if heading != ""
          call add(headings, [ofs + idx + 1, heading])
        endif
      else
        call add(headings, [ofs + idx + 1, line])
      endif
    elseif has_head_n1_pat && line =~# head_n1_pat && idx > 0
      let prev_line = lines[idx - 1]
      if prev_line =~ '[[:punct:]]\@!\S'
        if has_key(outline_info, 'create_heading')
          let heading = outline_info.create_heading('heading+1', prev_line, line,
                \ { 'heading_index': idx - 1, 'matched_index': idx, 'lines': lines })
          if heading != ""
            call add(headings, [ofs + idx, heading])
          endif
        else
          call add(headings, [ofs + idx, prev_line])
        endif
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
