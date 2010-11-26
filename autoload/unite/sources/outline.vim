"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-11-26
" Version : 0.1.4
" License : MIT license {{{
"
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

function! unite#sources#outline#define()
  return s:source
endfunction

function! unite#sources#outline#alias(alias, src_filetype)
  let g:unite_source_outline_info[a:alias] = a:src_filetype
endfunction

let s:outline_info_ftime = {}

function! unite#sources#outline#get_outline_info(filetype, ...)
  if a:0 && a:filetype == a:1
    throw "unite-outline: get_outline_info: cyclic alias definitions for '" . a:1 . "'"
  endif
  if has_key(g:unite_source_outline_info, a:filetype)
    if type(g:unite_source_outline_info[a:filetype]) == type("")
      " resolve the alias
      let src_filetype = g:unite_source_outline_info[a:filetype]
      return unite#sources#outline#get_outline_info(src_filetype, (a:0 ? a:1 : a:filetype))
    else
      return g:unite_source_outline_info[a:filetype]
    endif
  else
    let tries = [
          \ 'unite#sources#outline#%s#outline_info()',
          \ 'unite#sources#outline#defaults#%s#outline_info()',
          \ ]
    for fmt in tries
      let load_funcall = printf(fmt, a:filetype)
      try
        execute 'let outline_info = ' . load_funcall
      catch /^Vim\%((\a\+)\)\=:E117:/
        " E117: Unknown function:
        continue
      endtry
      let oinfo_file = s:find_outline_info_file(a:filetype)
      if oinfo_file != ""
        let ftime = getftime(oinfo_file)
        if has_key(s:outline_info_ftime, a:filetype) && ftime > s:outline_info_ftime[a:filetype]
          " reload the outline info because it was updated
          source `=oinfo_file`
          execute 'let outline_info = ' . load_funcall
        endif
        let s:outline_info_ftime[a:filetype] = ftime
      endif
      return outline_info
    endfor
  endif
  return {}
endfunction

function! s:find_outline_info_file(filetype)
  let tries = [
        \ 'unite/sources/outline/%s.vim',
        \ 'unite/sources/outline/defaults/%s.vim',
        \ ]
  for fmt in tries
    let oinfo_file = printf(fmt, a:filetype)
    if findfile(oinfo_file, &runtimepath) != ""
      return oinfo_file
    endif
  endfor
  return ""
endfunction

"---------------------------------------
" Utils

function! unite#sources#outline#indent(level)
  return printf('%*s', (a:level - 1) * g:unite_source_outline_indent_width, '')
endfunction

function! unite#sources#outline#capitalize(str, ...)
  let flag = (a:0 ? a:1 : '')
  return substitute(a:str, '\<\(\u\)\(\u\+\)\>', '\u\1\L\2', flag)
endfunction

function! unite#sources#outline#join_to(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  if limit < 0
    return s:join_to_backward(a:lines, a:idx, a:pattern, limit * -1)
  endif
  let idx = a:idx
  let lim_idx = min([a:idx + limit, len(a:lines) - 1])
  while idx <= lim_idx
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx += 1
  endwhile
  return join(a:lines[a:idx : idx], "\n")
endfunction

function! s:join_to_backward(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  let idx = a:idx
  let lim_idx = max(0, a:idx - limit])
  while idx > 0
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx -= 1
  endwhile
  return join(a:lines[idx : a:idx], "\n")
endfunction

function! unite#sources#outline#neighbor_match(lines, idx, pattern, ...)
  let nb = (a:0 ? a:1 : 1)
  if type(nb) == type([])
    let prev = nb[0]
    let next = nb[1]
  else
    let prev = nb
    let next = nb
  endif
  let nb_range = range(max([0, a:idx - prev]), min([a:idx + next, len(a:lines) - 1]))
  for idx in nb_range
    if a:lines[idx] =~ a:pattern
      return 1
    endif
  endfor
  return 0
endfunction

"-----------------------------------------------------------------------------
" Variables

if !exists('g:unite_source_outline_info')
  let g:unite_source_outline_info = {}
endif

if !exists('g:unite_source_outline_indent_width')
  let g:unite_source_outline_indent_width = 2
endif

if !exists('g:unite_source_outline_cache_buffers')
  let g:unite_source_outline_cache_buffers = 10
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 100
endif

if !exists('g:unite_source_outline_after_jump_scroll')
  let g:unite_source_outline_after_jump_scroll = 25
else
  let g:unite_source_outline_after_jump_scroll =
        \ min([max([0, g:unite_source_outline_after_jump_scroll]), 100])
endif

"-----------------------------------------------------------------------------
" Aliases

let s:default_alias_map = [
      \ ['cfg',      'dosini'],
      \ ['plaintex', 'tex'   ],
      \ ['xhtml',    'html'  ],
      \ ['zsh',      'sh'    ],
      \]
for [alias, src_filetype] in s:default_alias_map
  " NOTE: If the user has his/her own outline info for {alias} filetype, not
  " define any aliases for the filetype by default.
  if s:find_outline_info_file(alias) == ""
    call unite#sources#outline#alias(alias, src_filetype)
  endif
endfor
unlet s:default_alias_map

"-----------------------------------------------------------------------------
" Source

let s:source = {
      \ 'name': 'outline',
      \ 'description': 'candidates from heading list',
      \ 'action_table': {}, 'hooks': {},
      \ 'is_volatile': 1,
      \ }

function! s:source.hooks.on_init(args, context)
  " NOTE: The filetype of the buffer may be a "compound filetype", a set of
  " filetypes separated by periods.
  let filetype = getbufvar('%', '&filetype')
  if filetype != ""
    " if the filetype is a compound one, use the left most
    let filetype = split(filetype, '\.')[0]
  endif
  let s:buffer = {
        \ 'path'      : expand('%:p'),
        \ 'filetype'  : filetype,
        \ 'shiftwidth': getbufvar('%', '&shiftwidth'),
        \ 'tabstop'   : getbufvar('%', '&tabstop'),
        \ 'lines'     : getbufline('%', 1, '$'),
        \ }
endfunction

function! s:source.gather_candidates(args, context)
  try
    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
      let start_time = reltime()
    endif

    let is_force = ((len(a:args) > 0 && a:args[0] == '!') || a:context.is_redraw)
    let path = s:buffer.path
    if s:cache.has(path) && !is_force
      return s:cache.read(path)
    endif

    let filetype = s:buffer.filetype
    let outline_info = unite#sources#outline#get_outline_info(filetype)
    if empty(outline_info)
      call unite#print_error("unite-outline: not supported filetype: " . filetype)
      return []
    endif

    let lines = s:buffer.lines
    let idx = 0 | let n_lines = len(lines)

    "---------------------------------------
    " Skip the header

    if has_key(outline_info, 'skip_header')
      let idx = outline_info.skip_header(lines, { 'outline_info': outline_info })

    elseif has_key(outline_info, 'skip') && has_key(outline_info.skip, 'header')
      " eval once
      let val_type = type(outline_info.skip.header)
      if val_type == type("")
        let skip_header_lead = 1 | let skip_header_block = 0
        let header_lead = outline_info.skip.header
      elseif val_type == type([])
        let skip_header_lead = 0 | let skip_header_block = 1
        let header_begin = outline_info.skip.header[0]
        let header_end   = outline_info.skip.header[1]
      elseif val_type == type({})
        let skip_header_lead = has_key(outline_info.skip.header, 'leading')
        if skip_header_lead
          let header_lead = outline_info.skip.header.leading
        endif
        let skip_header_block = has_key(outline_info.skip.header, 'block')
        if skip_header_block
          let header_begin = outline_info.skip.header.block[0]
          let header_end   = outline_info.skip.header.block[1]
        endif
      endif

      while idx < n_lines
        let line = lines[idx]
        if skip_header_lead && line =~# header_lead
          let idx += 1
          while idx < n_lines
            let line = lines[idx]
            if line !~# header_lead
              break
            endif
            let idx += 1
          endwhile
        elseif skip_header_block && line =~# header_begin
          let idx += 1
          while idx < n_lines
            let line = lines[idx]
            if line =~# header_end
              break
            endif
            let idx += 1
          endwhile
          let idx += 1
        else
          break
        endif
      endwhile
    endif

    "---------------------------------------
    " Collect headings

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
    let has_create_heading = has_key(outline_info, 'create_heading')

    " collect headings
    let headings = []
    let heading_id = 1
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

      elseif match_head_prev && line =~# head_prev && idx < n_lines - 3
        " matched: heading-1
        let next_line = lines[idx + 1]
        if next_line =~ '[[:punct:]]\@!\S'
          if has_create_heading
            let heading = outline_info.create_heading('heading-1', next_line, line, {
                  \ 'heading_index': idx + 1, 'matched_index': idx, 'lines': lines,
                  \ 'heading_id': heading_id, 'outline_info': outline_info })
            if heading != ""
              call add(headings, [heading, next_line, idx + 1])
              let heading_id += 1
            endif
          else
            call add(headings, [next_line, next_line, idx + 1])
          endif
        elseif next_line =~ '\S' && idx < n_lines - 4
          " see one more next
          let next_line = lines[idx + 2]
          if next_line =~ '[[:punct:]]\@!\S'
            if has_create_heading
              let heading = outline_info.create_heading('heading-1', next_line, line, {
                    \ 'heading_index': idx + 2, 'matched_index': idx, 'lines': lines,
                    \ 'heading_id': heading_id, 'outline_info': outline_info })
              if heading != ""
                call add(headings, [heading, next_line, idx + 2])
                let heading_id += 1
              endif
            else
              call add(headings, [next_line, next_line, idx + 2])
            endif
          endif
          let idx += 1
        endif
        let idx += 2

      elseif match_head_line && line =~# head_line
        " matched: heading
        if has_create_heading
          let heading = outline_info.create_heading('heading', line, line, {
                \ 'heading_index': idx, 'matched_index': idx, 'lines': lines,
                \ 'heading_id': heading_id, 'outline_info': outline_info })
          if heading != ""
            call add(headings, [heading, line, idx])
            let heading_id += 1
          endif
        else
          call add(headings, [line, line, idx])
        endif

      elseif match_head_next && line =~# head_next && idx > 0
        " matched: heading+1
        let prev_line = lines[idx - 1]
        if prev_line =~ '[[:punct:]]\@!\S'
          if has_create_heading
            let heading = outline_info.create_heading('heading+1', prev_line, line, {
                  \ 'heading_index': idx - 1, 'matched_index': idx, 'lines': lines,
                  \ 'heading_id': heading_id, 'outline_info': outline_info })
            if heading != ""
              call add(headings, [heading, prev_line, idx - 1])
              let heading_id += 1
            endif
          else
            call add(headings, [prev_line, prev_line, idx - 1])
          endif
        endif
      endif
      let idx += 1
    endwhile

    let cands = map(headings, '{
          \ "word": (has_create_heading ? v:val[0] : s:normalize_indent(v:val[0])),
          \ "source": "outline",
          \ "kind": "jump_list",
          \ "action__path": path,
          \ "action__pattern": "^" . s:escape_regex(v:val[1]) . "$",
          \ "action__signature": s:calc_signature2(lines, v:val[2]),
          \ }')

    if n_lines > g:unite_source_outline_cache_limit
      call s:cache.write(path, cands)
    endif

    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
      let used_time = split(reltimestr(reltime(start_time)))[0]
      let phl = str2float(used_time) * (100.0 / n_lines)
      echomsg "unite-outline: used=" . used_time . "s, 100l=". string(phl) . "s"
    endif

    return cands
  catch
    call unite#print_error(v:throwpoint)
    call unite#print_error(v:exception)
    return []
  endtry
endfunction

function! s:normalize_indent(str)
  let str = a:str
  let sw = s:buffer.shiftwidth
  let ts = s:buffer.tabstop
  " expand leading tabs
  let lead_tabs = matchstr(str, '^\t\+')
  let ntab = strlen(lead_tabs)
  if ntab > 0
    let str =  substitute(str, '^\t\+', printf('%*s', ntab * ts, ""), '')
  endif
  " normalize indent
  let indent = matchstr(str, '^\s\+')
  let level = strlen(indent) / sw + 1
  if level > 0
    let str =  substitute(str, '^\s\+', unite#sources#outline#indent(level), '')
  endif
  return str
endfunction

function! s:escape_regex(str)
  return escape(a:str, '^$[].*\~')
endfunction

function! s:source.calc_signature(lnum)
  let range = 2
  let from = max([1, a:lnum - range])
  let to   = min([a:lnum + range, line('$')])
  return join(getline(from, to))
endfunction

function! s:calc_signature2(lines, idx)
  let range = 2
  let from = max([0, a:idx - range])
  let to   = min([a:idx + range, len(a:lines) - 1])
  return join(a:lines[from : to])
endfunction

"---------------------------------------
" Actions

let s:action_table = {}

let s:action_table.open = {
      \ 'description': 'jump to this position',
      \ 'is_selectable': 1,
      \ }
function! s:action_table.open.func(candidates)
  for cand in a:candidates
    call unite#take_action('open', cand)
    call s:adjust_scroll(s:best_scroll())
  endfor
endfunction

let s:action_table.preview = {
      \ 'description': 'preview this position',
      \ 'is_selectable': 0,
      \ 'is_quit' : 0,
      \ }
function! s:action_table.preview.func(candidate)
  let cand = a:candidate
  let bufnr = bufnr(unite#util#escape_file_searching(cand.action__path))
  if getbufvar(bufnr, '&buftype') =~# '\<nofile\>'
    " NOTE: Executing :pedit for a nofile buffer clears the buffer content at all.
    call unite#print_error("unite-outline: can't preview nofile buffer")
    return
  endif

  " work around `scroll-to-top' problem on :pedit %
  let save_cursors = s:save_window_cursors(bufnr)
  let n_wins = winnr('$')
  call unite#take_action('preview', cand)
  wincmd p
  let preview_winnr = winnr()
  call s:adjust_scroll(s:best_scroll())
  wincmd p
  call s:restore_window_cursors(save_cursors, preview_winnr, (winnr('$') > n_wins))
endfunction

function! s:save_window_cursors(bufnr)
  let save_cursors = {}
  let save_winnr = winnr()
  let winnr = 1
  while winnr <= winnr('$')
    if winbufnr(winnr) == a:bufnr
      execute winnr . 'wincmd w'
      let save_cursors[winnr] = {
            \ 'cursor': getpos('.'),
            \ 'winline': winline(),
            \ }
    endif
    let winnr += 1
  endwhile
  execute save_winnr . 'wincmd w'
  return save_cursors
endfunction

function! s:restore_window_cursors(save_cursors, preview_winnr, is_new)
  let save_winnr = winnr()
  for [winnr, saved] in items(a:save_cursors)
    if winnr == a:preview_winnr
      continue
    elseif a:is_new && winnr >= a:preview_winnr
      let winnr += 1
    endif
    execute winnr . 'wincmd w'
    if getpos('.') != saved.cursor
      call setpos('.', saved.cursor)
      call s:adjust_scroll(saved.winline)
    endif
  endfor
  execute save_winnr . 'wincmd w'
endfunction

function! s:best_scroll()
  return max([1, winheight(0) * g:unite_source_outline_after_jump_scroll / 100])
endfunction

function! s:adjust_scroll(best)
  normal! zt
  let save_pos = getpos('.')
  let winl = winline()
  let delta = winl - a:best
  let prev_winl = winl
  if delta > 0
    " scroll up
    while 1
      execute "normal! \<C-e>"
      let winl = winline()
      if winl < a:best || winl == prev_winl
        break
      end
      let prev_winl = winl
    endwhile
    execute "normal! \<C-y>"
  elseif delta < 0
    " scroll down
    while 1
      execute "normal! \<C-y>"
      let winl = winline()
      if winl > a:best || winl == prev_winl
        break
      end
      let prev_winl = winl
    endwhile
    execute "normal! \<C-e>"
  endif
  call setpos('.', save_pos)
endfunction

let s:source.action_table.jump_list = s:action_table
unlet s:action_table

"-----------------------------------------------------------------------------
" Cache

let s:cache = { 'data': {} }

function! s:cache.has(path)
  return has_key(self.data, a:path)
endfunction

function! s:cache.read(path)
  let item = self.data[a:path]
  let item.touched = localtime()
  return item.candidates
endfunction

function! s:cache.write(path, cands)
  let self.data[a:path] = {
        \ 'candidates': a:cands,
        \ 'touched': localtime(), 
        \ }
  if len(self.data) > g:unite_source_outline_cache_buffers
    let oldest = sort(items(self.data), 's:compare_timestamp')[0]
    unlet self.data[oldest[0]]
  endif
endfunction

function! s:compare_timestamp(item1, item2)
  let t1 = a:item1[1].touched
  let t2 = a:item2[1].touched
  return t1 == t2 ? 0 : t1 > t2 ? 1 : -1
endfunction

" vim: filetype=vim
