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
    " eval once
    let val_type = type(outline_info.skip.header)
    if val_type == type("")
      let skip_header_lead = 1 | let skip_header_block = 0
      let header_lead  = outline_info.skip.header
    elseif val_type == type([])
      let skip_header_lead = 0 | let skip_header_block = 1
      let header_begin = outline_info.skip.header[0]
      let header_end   = outline_info.skip.header[1]
    elseif val_type == type({})
      let skip_header_lead = 1 | let skip_header_block = 1
      let header_lead  = outline_info.skip.header.leading
      let header_begin = outline_info.skip.header.block[0]
      let header_end   = outline_info.skip.header.block[1]
    endif

    let n_lines = len(lines)
    let line = lines[0]
    while ofs < n_lines
      let line = lines[ofs]
      if skip_header_lead && line =~# header_lead
        let ofs += 1
        while ofs < n_lines
          let line = lines[ofs]
          if line !~# header_lead
            break
          endif
          let ofs += 1
        endwhile
      elseif skip_header_block && line =~# header_begin
        let ofs += 1
        while ofs < n_lines
          let line = lines[ofs]
          if line =~# header_end
            break
          endif
          let ofs += 1
        endwhile
        let ofs += 1
      else
        break
      endif
    endwhile
    let lines = lines[ofs :]
  endif

  " eval once
  let skip_block = has_key(outline_info, 'skip') && has_key(outline_info.skip, 'block')
  if skip_block
    let skip_block_begin = outline_info.skip.block[0]
    let skip_block_end   = outline_info.skip.block[1]
  endif
  let match_head_prev = has_key(outline_info, 'heading-1')
  if match_head_prev
    let head_prev = outline_info['heading-1']
  endif
  let match_head_line = has_key(outline_info, 'heading')
  if match_head_line
    let head_line = outline_info.heading
  endif
  let match_head_next = has_key(outline_info, 'heading+1')
  if match_head_next
    let head_next = outline_info['heading+1']
  endif

  " collect heading lines
  let headings = []
  let idx = 0 | let n_lines = len(lines)
  while idx < n_lines
    let line = lines[idx]
    if skip_block && line =~# skip_block_begin
      " skip a documentation block
      let idx += 1
      while idx < n_lines
        let line = lines[idx]
        if line =~# skip_block_end
          break
        endif
        let idx += 1
      endwhile
    elseif match_head_prev && line =~# head_prev
      " matched: heading-1
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
        " see one more next
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
    elseif match_head_line && line =~# head_line
      " matched: heading
      if has_key(outline_info, 'create_heading')
        let heading = outline_info.create_heading('heading', line, line,
              \ { 'heading_index': idx, 'matched_index': idx, 'lines': lines })
        if heading != ""
          call add(headings, [ofs + idx + 1, heading])
        endif
      else
        call add(headings, [ofs + idx + 1, line])
      endif
    elseif match_head_next && line =~# head_next && idx > 0
      " matched: heading+1
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

function! s:get_outline_info(filetype)
  if has_key(g:unite_source_outline_info, a:filetype)
    return g:unite_source_outline_info[a:filetype]
  else
    let tries = [
          \ 'outline#',
          \ 'unite#sources#outline#',
          \ 'unite#sources#outline#defaults#',
          \ ]
    for path in tries
      let load_func = path . a:filetype . '#outline_info'
      try
        execute 'let outline_info = ' . load_func . '()'
        let g:unite_source_outline_info[a:filetype] = outline_info
        return outline_info
      catch /^Vim\%((\a\+)\)\=:E117:/
        " no file or undefined, go next
      catch
        " error on eval
        call unite#print_error(v:throwpoint)
        call unite#print_error(v:exception)
      endtry
    endfor
  endif
  return {}
endfunction

" vim: filetype=vim
