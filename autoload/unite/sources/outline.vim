"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-21
" Version : 0.1.9
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"   
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"   
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    for funcall_fmt in tries
      let load_funcall = printf(funcall_fmt, a:filetype)
      try
        execute 'let outline_info = ' . load_funcall
      catch /^Vim\%((\a\+)\)\=:E117:/
        " E117: Unknown function:
        continue
      endtry
      " if the outline info has been updated since the last time it was
      " sourced, re-source and update it
      let oinfo_file = s:find_outline_info_file(a:filetype)
      if oinfo_file != ""
        let ftime = getftime(oinfo_file)
        if has_key(s:outline_info_ftime, a:filetype) && ftime > s:outline_info_ftime[a:filetype]
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
        \ 'autoload/unite/sources/outline/%s.vim',
        \ 'autoload/unite/sources/outline/defaults/%s.vim',
        \ ]
  for path_fmt in tries
    let path = printf(path_fmt, a:filetype)
    let oinfo_file = findfile(path, &runtimepath)
    if oinfo_file != ""
      return oinfo_file
    endif
  endfor
  return ""
endfunction

"---------------------------------------
" Utils

function! unite#sources#outline#indent(level)
  return unite#sources#outline#util#indent(a:level)
endfunction

function! unite#sources#outline#capitalize(str, ...)
  return unite#sources#outline#util#capitalize(a:str, (a:0 ? a:1 : ''))
endfunction

function! unite#sources#outline#join_to(lines, idx, pattern, ...)
  return unite#sources#outline#util#join_to(a:lines, a:idx, a:pattern, (a:0 ? a:1 : 3))
endfunction

function! unite#sources#outline#neighbor_match(lines, idx, pattern, ...)
  return unite#sources#outline#util#neighbor_match(a:lines, a:idx, a:pattern, (a:0 ? a:1 : 1))
endfunction

"-----------------------------------------------------------------------------
" Variables

if !exists('g:unite_source_outline_info')
  let g:unite_source_outline_info = {}
endif

if !exists('g:unite_source_outline_indent_width')
  let g:unite_source_outline_indent_width = 2
endif

if !exists('g:unite_source_outline_max_headings')
  let g:unite_source_outline_max_headings = 1000
endif

if !exists('g:unite_source_outline_cache_buffers')
  let g:unite_source_outline_cache_buffers = 20
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 100
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
      \ 'name'        : 'outline',
      \ 'description' : 'candidates from heading list',
      \ 'hooks'       : {},
      \ 'action_table': {},
      \ 'is_volatile' : 1,
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
        \ 'nr'        : bufnr('%'),
        \ 'path'      : expand('%:p'),
        \ 'filetype'  : filetype,
        \ 'shiftwidth': getbufvar('%', '&shiftwidth'),
        \ 'tabstop'   : getbufvar('%', '&tabstop'),
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

    let save_ignorecase = &ignorecase
    set noignorecase

    let lines = getbufline(s:buffer.nr, 1, '$')
    let idx = 0 | let n_lines = len(lines)

    " initialize the shared context dictionary
    let context = {
          \ 'heading_index': 0,
          \ 'matched_index': 0,
          \ 'lines'        : lines,
          \ 'buffer'       : s:buffer,
          \ 'heading_id'   : 0,
          \ 'outline_info' : outline_info
          \ }

    " initialize the outline info
    if has_key(outline_info, 'initialize')
      call outline_info.initialize(context)
    endif
    let context.heading_id += 1

    " initialize local variables
    let [   skip_header,
          \ skip_header_leading, header_leading_pattern,
          \ skip_header_block, header_beg_pattern, header_end_pattern,
          \ has_skip_header_func,
          \ skip_block,
          \ block_beg_pattern, block_end_pattern,
          \ has_heading_prev_pattern, heading_prev_pattern,
          \ has_heading_pattern, heading_pattern,
          \ has_heading_next_pattern, heading_next_pattern,
          \ has_create_heading_func
          \
          \ ] = s:init_local_vars(outline_info)

    "---------------------------------------
    " Skip the header

    if has_skip_header_func
      let idx = outline_info.skip_header(lines, { 'outline_info': outline_info })

    elseif skip_header
      while idx < n_lines
        let line = lines[idx]
        if skip_header_leading && line =~# header_leading_pattern
          let idx = s:skip_while(header_leading_pattern, lines, idx)
        elseif skip_header_block && line =~# header_beg_pattern
          let idx = s:skip_to(header_end_pattern, lines, idx)
        else
          break
        endif
      endwhile
    endif

    "---------------------------------------
    " Collect headings

    let headings = []
    while idx < n_lines
      let line = lines[idx]
      if skip_block && line =~# block_beg_pattern
        " skip a documentation block
        let idx = s:skip_to(block_end_pattern, lines, idx)

      elseif has_heading_prev_pattern && line =~# heading_prev_pattern && idx < n_lines - 3
        " matched: heading-1
        let next_line = lines[idx + 1]
        if next_line =~ '[[:punct:]]\@!\S'
          if has_create_heading_func
            let context.heading_index = idx + 1
            let context.matched_index = idx
            let heading = outline_info.create_heading('heading-1', next_line, line, context)
            if heading != ""
              call add(headings, [heading, next_line, idx + 1])
              let context.heading_id += 1
            endif
          else
            call add(headings, [next_line, next_line, idx + 1])
          endif
        elseif next_line =~ '\S' && idx < n_lines - 4
          " see one more next
          let next_line = lines[idx + 2]
          if next_line =~ '[[:punct:]]\@!\S'
            if has_create_heading_func
              let context.heading_index = idx + 2
              let context.matched_index = idx
              let heading = outline_info.create_heading('heading-1', next_line, line, context)
              if heading != ""
                call add(headings, [heading, next_line, idx + 2])
                let context.heading_id += 1
              endif
            else
              call add(headings, [next_line, next_line, idx + 2])
            endif
          endif
          let idx += 1
        endif
        let idx += 1

      elseif has_heading_pattern && line =~# heading_pattern
        " matched: heading
        if has_create_heading_func
          let context.heading_index = idx
          let context.matched_index = idx
          let heading = outline_info.create_heading('heading', line, line, context)
          if heading != ""
            call add(headings, [heading, line, idx])
            let context.heading_id += 1
          endif
        else
          call add(headings, [line, line, idx])
        endif

      elseif has_heading_next_pattern && line =~# heading_next_pattern && idx > 0
        " matched: heading+1
        let prev_line = lines[idx - 1]
        if prev_line =~ '[[:punct:]]\@!\S'
          if has_create_heading_func
            let context.heading_index = idx - 1
            let context.matched_index = idx
            let heading = outline_info.create_heading('heading+1', prev_line, line, context)
            if heading != ""
              call add(headings, [heading, prev_line, idx - 1])
              let context.heading_id += 1
            endif
          else
            call add(headings, [prev_line, prev_line, idx - 1])
          endif
        endif
      endif

      if context.heading_id >= g:unite_source_outline_max_headings
        call unite#print_error("unite-outline: too many headings, discarded the rest")
        break
      endif
      let idx += 1
    endwhile

    let cands = map(headings, '{
          \ "word"             : (has_create_heading_func ? v:val[0] : s:normalize_indent(v:val[0])),
          \ "source"           : "outline",
          \ "kind"             : "jump_list",
          \ "action__path"     : path,
          \ "action__pattern"  : "^" . s:escape_pattern(v:val[1]) . "$",
          \ "action__signature": self.calc_signature(v:val[2] + 1, lines),
          \ }')

    let is_volatile = has_key(outline_info, 'is_volatile') && outline_info.is_volatile
    if !is_volatile && (n_lines > g:unite_source_outline_cache_limit)
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
  finally
    let &ignorecase = save_ignorecase
  endtry
endfunction

function! s:init_local_vars(outline_info)
  let header_leading_pattern = ''
  let header_beg_pattern = '' | let header_end_pattern = ''

  " values used for skipping header
  let skip_header = has_key(a:outline_info, 'skip') && has_key(a:outline_info.skip, 'header')
  if skip_header
    let value_type = type(a:outline_info.skip.header)
    if value_type == type("")
      let skip_header_leading = 1 | let skip_header_block = 0
      let header_leading_pattern = a:outline_info.skip.header
    elseif value_type == type([])
      let skip_header_leading = 0 | let skip_header_block = 1
      let header_beg_pattern = a:outline_info.skip.header[0]
      let header_end_pattern = a:outline_info.skip.header[1]
    elseif value_type == type({})
      let skip_header_leading = has_key(a:outline_info.skip.header, 'leading')
      if skip_header_leading
        let header_leading_pattern = a:outline_info.skip.header.leading
      endif
      let skip_header_block = has_key(a:outline_info.skip.header, 'block')
      if skip_header_block
        let header_beg_pattern = a:outline_info.skip.header.block[0]
        let header_end_pattern = a:outline_info.skip.header.block[1]
      endif
    endif
  else
    let skip_header_leading = 0 | let skip_header_block = 0
  endif
  let has_skip_header_func = has_key(a:outline_info, 'skip_header')

  " values used for skipping blocks
  let skip_block = has_key(a:outline_info, 'skip') && has_key(a:outline_info.skip, 'block')
  let block_beg_pattern = (skip_block ? a:outline_info.skip.block[0] : '')
  let block_end_pattern = (skip_block ? a:outline_info.skip.block[1] : '')

  " values used for extracting headings
  let has_heading_prev_pattern = has_key(a:outline_info, 'heading-1')
  let heading_prev_pattern = (has_heading_prev_pattern ? a:outline_info['heading-1'] : '')
  let has_heading_pattern = has_key(a:outline_info, 'heading')
  let heading_pattern = (has_heading_pattern ? a:outline_info.heading : '')
  let has_heading_next_pattern = has_key(a:outline_info, 'heading+1')
  let heading_next_pattern = (has_heading_next_pattern ? a:outline_info['heading+1'] : '')
  let has_create_heading_func = has_key(a:outline_info, 'create_heading')

  return [skip_header,
        \ skip_header_leading, header_leading_pattern,
        \ skip_header_block, header_beg_pattern, header_end_pattern,
        \ has_skip_header_func,
        \ skip_block,
        \ block_beg_pattern, block_end_pattern,
        \ has_heading_prev_pattern, heading_prev_pattern,
        \ has_heading_pattern, heading_pattern,
        \ has_heading_next_pattern, heading_next_pattern,
        \ has_create_heading_func,
        \ ]
endfunction

function! s:skip_while(pattern, lines, idx)
  let idx = a:idx + 1 | let n_lines = len(a:lines)
  while idx < n_lines
    let line = a:lines[idx]
    if line !~# a:pattern
      break
    endif
    let idx += 1
  endwhile
  return idx
endfunction

function! s:skip_to(pattern, lines, idx)
  let idx = a:idx + 1 | let n_lines = len(a:lines)
  while idx < n_lines
    let line = a:lines[idx]
    if line =~# a:pattern
      break
    endif
    let idx += 1
  endwhile
  return idx + 1
endfunction

function! s:normalize_indent(str)
  let str = a:str
  let sw = s:buffer.shiftwidth
  let ts = s:buffer.tabstop
  " expand leading tabs
  let lead_tabs = matchstr(str, '^\t\+')
  let ntab = strlen(lead_tabs)
  if ntab > 0
    let str =  substitute(str, '^\t\+', repeat(' ', ntab * ts), '')
  endif
  " normalize indent
  let indent = matchstr(str, '^\s\+')
  let level = strlen(indent) / sw + 1
  if level > 0
    let str =  substitute(str, '^\s\+', unite#sources#outline#util#indent(level), '')
  endif
  return str
endfunction

function! s:escape_pattern(str)
  return escape(a:str, '^$[].*\~')
endfunction

function! s:source.calc_signature(lnum, ...)
  let range = 10 | let precision = 2
  if a:0
    let lines = a:1 | let idx = a:lnum - 1
    let from = max([0, idx - range])
    let to   = min([idx + range, len(lines) - 1])
    let backward = lines[from : idx]
    let forward  = lines[idx  : to]
  else
    let from = max([1, a:lnum - range])
    let to   = min([a:lnum + range, line('$')])
    let backward = getline(from, a:lnum)
    let forward  = getline(a:lnum, to)
  endif
  let backward = filter(backward, 'v:val =~ "\\S"')[-precision-1 : -2]
  let forward  = filter(forward,  'v:val =~ "\\S"')[1 : precision]
  return join(map(backward + forward, 'v:val[0:99]'))
endfunction

"---------------------------------------
" Actions

let s:action_table = {}

let s:action_table.preview = {
      \ 'description'  : 'preview this position',
      \ 'is_selectable': 0,
      \ 'is_quit'      : 0,
      \ }
function! s:action_table.preview.func(candidate)
  let cand = a:candidate

  " NOTE: Executing :pedit for a nofile buffer clears the buffer content at
  " all, so prohibit it.
  let bufnr = bufnr(unite#util#escape_file_searching(cand.action__path))
  if getbufvar(bufnr, '&buftype') =~# '\<nofile\>'
    call unite#print_error("unite-outline: can't preview nofile buffer")
    return
  endif

  " work around `cursor-goes-to-top' problem on :pedit %
  let save_cursors = s:save_window_cursors(bufnr)
  let n_wins = winnr('$')
  call unite#take_action('preview', cand)
  wincmd p
  let preview_winnr = winnr()
  call s:adjust_scroll(s:best_winline())
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
            \ 'cursor' : getpos('.'),
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

function! s:best_winline()
  return max([1, winheight(0) * g:unite_kind_jump_list_after_jump_scroll / 100])
endfunction

function! s:adjust_scroll(best_winline)
  normal! zt
  let save_cursor = getpos('.')
  let winl = 1
  " scroll the cursor line down
  while winl <= a:best_winline
    let prev_winl = winl
    execute "normal! \<C-y>"
    let winl = winline()
    if winl == prev_winl
      break
    end
    let prev_winl = winl
  endwhile
  if winl > a:best_winline
    execute "normal! \<C-e>"
  endif
  call setpos('.', save_cursor)
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
        \ 'touched'   : localtime(),
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
