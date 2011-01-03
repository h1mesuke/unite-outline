"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-04
" Version : 0.2.0
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

function! unite#sources#outline#get_outline_info(filetype)
  let filetype = s:resolve_filetype(a:filetype)
  if has_key(g:unite_source_outline_info, filetype)
    return g:unite_source_outline_info[filetype]
  else
    let tries = [
          \ 'unite#sources#outline#%s#outline_info()',
          \ 'unite#sources#outline#defaults#%s#outline_info()',
          \ ]
    for funcall_fmt in tries
      let load_funcall = printf(funcall_fmt, filetype)
      try
        execute 'let outline_info = ' . load_funcall
      catch /^Vim\%((\a\+)\)\=:E117:/
        " E117: Unknown function:
        continue
      endtry
      " if the outline info has been updated since the last time it was
      " sourced, re-source and update it
      let oinfo_file = s:find_outline_info_file(filetype)
      if oinfo_file != ""
        let ftime = getftime(oinfo_file)
        if has_key(s:outline_info_ftime, filetype) && ftime > s:outline_info_ftime[filetype]
          source `=oinfo_file`
          execute 'let outline_info = ' . load_funcall
        endif
        let s:outline_info_ftime[filetype] = ftime
      endif
      return outline_info
    endfor
  endif
  return {}
endfunction

function! s:resolve_filetype(filetype, ...)
  if a:0
    let start_filetype = a:1
    if a:filetype == start_filetype
      throw "unite-outline: cyclic alias definitions for '" . start_filetype . "'"
    endif
  else
    let start_filetype = a:filetype
  endif
  if has_key(g:unite_source_outline_info, a:filetype) &&
        \ type(g:unite_source_outline_info[a:filetype]) == type("")
    " 1 more hop
    let filetype = g:unite_source_outline_info[a:filetype]
    return s:resolve_filetype(filetype, start_filetype)
  endif
  return a:filetype
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

function! unite#sources#outline#indent(...)
  return call('unite#sources#outline#util#indent', a:000)
endfunction

function! unite#sources#outline#capitalize(...)
  return call('unite#sources#outline#util#capitalize', a:000)
endfunction

function! unite#sources#outline#join_to(...)
  return call('unite#sources#outline#util#join_to', a:000)
endfunction

function! unite#sources#outline#neighbor_match(...)
  return call('unite#sources#outline#util#neighbor_match', a:000)
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

if !exists('g:unite_source_outline_cache_dir')
  let here = expand('<sfile>:p:h')
  let g:unite_source_outline_cache_dir = here . '/outline/.cache'
else
  let g:unite_source_outline_cache_dir = unite#util#substitute_path_separator(
        \ substitute(g:unite_source_outline_cache_dir, '/$', '', ''))
endif
if !exists('*mkdir')
  let g:unite_source_outline_cache_dir = ''
endif
if g:unite_source_outline_cache_dir != '' && !isdirectory(g:unite_source_outline_cache_dir)
  try
    call mkdir(g:unite_source_outline_cache_dir, 'p')
  catch
    call unite#util#print_error("unite-outline: could not create the cache directory")
    let g:unite_source_outline_cache_dir = ''
  endtry
endif
lockvar g:unite_source_outline_cache_dir

if !exists('g:unite_source_outline_cache_buffers')
  let g:unite_source_outline_cache_buffers = 20
  let s:cache_serialize_buffers = g:unite_source_outline_cache_buffers
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 100
endif

if !exists('g:unite_source_outline_cache_serialize_limit')
  let g:unite_source_outline_cache_serialize_limit = 1000
endif

if !exists('g:unite_source_outline_profile')
  let g:unite_source_outline_profile = 0
endif

"-----------------------------------------------------------------------------
" Aliases

let s:default_alias_map = [
      \ ['cfg',      'dosini'  ],
      \ ['mkd',      'markdown'],
      \ ['plaintex', 'tex'     ],
      \ ['snippet',  'conf'    ],
      \ ['xhtml',    'html'    ],
      \ ['zsh',      'sh'      ],
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
  let s:context = {}
endfunction

function! s:source.hooks.on_close(args, context)
  let s:buffer  = {}
  let s:context = {}
endfunction

function! s:source.gather_candidates(args, context)
  let save_ignorecase = &ignorecase
  set noignorecase

  try
    if g:unite_source_outline_profile && has("reltime")
      let start_time = s:get_time()
    endif

    let is_force = ((len(a:args) > 0 && a:args[0] == '!') || a:context.is_redraw)
    let cache = unite#sources#outline#_cache#instance()
    let path = s:buffer.path
    if cache.has_data(path) && !is_force
      return cache.get_data(path)
    endif

    let filetype = s:buffer.filetype
    let outline_info = unite#sources#outline#get_outline_info(filetype)
    if empty(outline_info)
      call unite#util#print_error("unite-outline: not supported filetype: " . filetype)
      return []
    endif
    call s:normalize_outline_info(outline_info)

    let s:buffer.lines = getbufline(s:buffer.nr, 1, '$')
    let num_lines = len(s:buffer.lines)

    " initialize the shared context dictionary
    let s:context = {
          \ 'heading_index': 0,
          \ 'matched_index': 0,
          \ 'lines'        : s:buffer.lines,
          \ 'buffer'       : s:buffer,
          \ 'outline_info' : outline_info
          \ }

    " initialize the outline info
    if has_key(outline_info, 'initialize')
      call outline_info.initialize(s:context)
    endif

    " extract headings
    let s:line_idx = 0
    call s:skip_header()
    let headings = s:extract_headings()

    " finalize the outline info
    if has_key(outline_info, 'finalize')
      call outline_info.finalize(s:context)
    endif

    let cands = map(headings, '{
          \ "word"  : s:normalize_heading(v:val[0]),
          \ "source": "outline",
          \ "kind"  : "jump_list",
          \ "action__path"     : path,
          \ "action__pattern"  : "^" . s:escape_regexp(v:val[1]) . "$",
          \ "action__signature": self.calc_signature(v:val[2] + 1, s:buffer.lines),
          \ }')

    let is_volatile = has_key(outline_info, 'is_volatile') && outline_info.is_volatile
    if !is_volatile && (num_lines > g:unite_source_outline_cache_limit)
      call cache.set_data(path, cands)
    endif

    if g:unite_source_outline_profile && has("reltime")
      let used_time = s:get_time() - start_time
      let used_time_100l = used_time * (str2float("100") / num_lines)
      echomsg "unite-outline: used=" . string(used_time) . "s, 100l=". string(used_time_100l) . "s"
    endif

    return cands
  catch
    call unite#util#print_error(v:throwpoint)
    call unite#util#print_error(v:exception)
    return []
  finally
    let &ignorecase = save_ignorecase
  endtry
endfunction

function! s:get_time()
  return str2float(reltimestr(reltime()))
endfunction

function! s:normalize_outline_info(outline_info)
  if has_key(a:outline_info, 'skip') && has_key(a:outline_info.skip, 'header')
    let value_type = type(a:outline_info.skip.header)
    if value_type == type("")
      let a:outline_info.skip.header = { 'leading': a:outline_info.skip.header }
    elseif value_type == type([])
      let a:outline_info.skip.header =
            \ { 'block': s:normalize_block_patterns(a:outline_info.skip.header) }
    elseif value_type == type({})
      if has_key(a:outline_info.skip.header, 'block') &&
            \ type(a:outline_info.skip.header.block) == type([])
        let a:outline_info.skip.header.block =
              \ s:normalize_block_patterns(a:outline_info.skip.header.block)
      endif
    endif
  endif
  if has_key(a:outline_info, 'skip') && has_key(a:outline_info.skip, 'block')
    let value_type = type(a:outline_info.skip.block)
    if value_type == type([])
      let a:outline_info.skip.block = s:normalize_block_patterns(a:outline_info.skip.block)
    endif
  endif
endfunction

function! s:normalize_block_patterns(patterns)
  return { 'begin': a:patterns[0], 'end': a:patterns[1] }
endfunction

function! s:skip_header()
  let outline_info = s:context.outline_info

  if has_key(outline_info, 'skip_header')
    let s:line_idx = outline_info.skip_header(lines, s:context)

  elseif has_key(outline_info, 'skip') && has_key(outline_info.skip, 'header')
    let skip_header_leading = has_key(outline_info.skip.header, 'leading')
    if skip_header_leading
      let header_leading_pattern = outline_info.skip.header.leading
    endif
    let skip_header_block = has_key(outline_info.skip.header, 'block')
    if skip_header_block
      let header_beg_pattern = outline_info.skip.header.block.begin
      let header_end_pattern = outline_info.skip.header.block.end
    endif

    let lines = s:buffer.lines | let num_lines = len(lines)

    while s:line_idx < num_lines
      let line = lines[s:line_idx]
      if skip_header_leading && line =~# header_leading_pattern
        call s:skip_while(header_leading_pattern)
      elseif skip_header_block && line =~# header_beg_pattern
        call s:skip_to(header_end_pattern)
      else
        break
      endif
    endwhile
  endif

  return s:line_idx
endfunction

function! s:extract_headings()
  let outline_info = s:context.outline_info

  let skip_block = has_key(outline_info, 'skip') && has_key(outline_info.skip, 'block')
  if skip_block
    let block_beg_pattern = outline_info.skip.block.begin
    let block_end_pattern = outline_info.skip.block.end
  endif

  let has_heading_prev_pattern = has_key(outline_info, 'heading-1')
  if has_heading_prev_pattern
    let heading_prev_pattern = outline_info['heading-1']
  endif
  let has_heading_pattern = has_key(outline_info, 'heading')
  if has_heading_pattern
    let heading_pattern = outline_info.heading
  endif
  let has_heading_next_pattern = has_key(outline_info, 'heading+1')
  if has_heading_next_pattern
    let heading_next_pattern = outline_info['heading+1']
  endif
  let has_create_heading_func = has_key(outline_info, 'create_heading')

  let headings = []
  let lines = s:buffer.lines | let num_lines = len(lines)

  while s:line_idx < num_lines
    let line = lines[s:line_idx]
    if skip_block && line =~# block_beg_pattern
      " skip a documentation block
      call s:skip_to(block_end_pattern)

    elseif has_heading_prev_pattern && line =~# heading_prev_pattern && s:line_idx < num_lines - 3
      " matched: heading-1
      let next_line = lines[s:line_idx + 1]
      if next_line =~ '[[:punct:]]\@!\S'
        if has_create_heading_func
          let s:context.heading_index = s:line_idx + 1
          let s:context.matched_index = s:line_idx
          let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
          if heading != ""
            call add(headings, [heading, next_line, s:line_idx + 1])
          endif
        else
          call add(headings, [next_line, next_line, s:line_idx + 1])
        endif
      elseif next_line =~ '\S' && s:line_idx < num_lines - 4
        " see one more next
        let next_line = lines[s:line_idx + 2]
        if next_line =~ '[[:punct:]]\@!\S'
          if has_create_heading_func
            let s:context.heading_index = s:line_idx + 2
            let s:context.matched_index = s:line_idx
            let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
            if heading != ""
              call add(headings, [heading, next_line, s:line_idx + 2])
            endif
          else
            call add(headings, [next_line, next_line, s:line_idx + 2])
          endif
        endif
        let s:line_idx += 1
      endif
      let s:line_idx += 1

    elseif has_heading_pattern && line =~# heading_pattern
      " matched: heading
      if has_create_heading_func
        let s:context.heading_index = s:line_idx
        let s:context.matched_index = s:line_idx
        let heading = outline_info.create_heading('heading', line, line, s:context)
        if heading != ""
          call add(headings, [heading, line, s:line_idx])
        endif
      else
        call add(headings, [line, line, s:line_idx])
      endif

    elseif has_heading_next_pattern && line =~# heading_next_pattern && s:line_idx > 0
      " matched: heading+1
      let prev_line = lines[s:line_idx - 1]
      if prev_line =~ '[[:punct:]]\@!\S'
        if has_create_heading_func
          let s:context.heading_index = s:line_idx - 1
          let s:context.matched_index = s:line_idx
          let heading = outline_info.create_heading('heading+1', prev_line, line, s:context)
          if heading != ""
            call add(headings, [heading, prev_line, s:line_idx - 1])
          endif
        else
          call add(headings, [prev_line, prev_line, s:line_idx - 1])
        endif
      endif
    endif

    if len(headings) > g:unite_source_outline_max_headings
      call unite#util#print_error("unite-outline: too many headings, discarded the rest")
      break
    endif
    let s:line_idx += 1
  endwhile

  return headings
endfunction

function! s:skip_while(pattern)
  let lines = s:buffer.lines | let num_lines = len(lines)
  let s:line_idx += 1
  while s:line_idx < num_lines
    let s:line_idx += 1
    let line = lines[s:line_idx]
    if line !~# a:pattern
      break
    endif
  endwhile
endfunction

function! s:skip_to(pattern)
  let lines = s:buffer.lines | let num_lines = len(lines)
  let s:line_idx += 1
  while s:line_idx < num_lines
    let s:line_idx += 1
    let line = lines[s:line_idx]
    if line =~# a:pattern
      break
    endif
  endwhile
endfunction

function! s:normalize_heading(heading)
  let outline_info = s:context.outline_info
  let heading = a:heading
  if has_key(outline_info, 'create_heading')
    let heading = s:normalize_indent(heading)
  endif
  return heading
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

function! s:escape_regexp(str)
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
  return join(map(backward + forward, 's:digest_line(v:val)'), '')
endfunction

" quick and dirty digest
function! s:digest_line(line)
  let line = substitute(a:line, '\s*', '', 'g')
  if s:strchars(line) <= 20
    let digest = line
  else
    let line = matchstr(line, '^\(\%(.\{5}\)\{,20}\)')
    let digest = substitute(line, '\(.\).\{4}', '\1', 'g')
  endif
  return digest
endfunction

if v:version >= 703
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(a:str, '.', 'c', 'g'))
  endfunction
endif

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
    call unite#util#print_error("unite-outline: can't preview nofile buffer")
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

" vim: filetype=vim
