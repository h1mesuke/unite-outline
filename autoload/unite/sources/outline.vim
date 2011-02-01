"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-02-01
" Version : 0.3.0
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
  let s:filetype_alias_table[a:alias] = a:src_filetype
endfunction

function! unite#sources#outline#clear_cache()
  let cache = unite#sources#outline#_cache#instance()
  call cache.clear()
endfunction

let s:outline_info_ftime = {}

function! unite#sources#outline#get_outline_info(filetype)
  let filetype = s:resolve_filetype_alias(a:filetype)
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

function! s:resolve_filetype_alias(filetype)
  if has_key(s:filetype_alias_table, a:filetype)
    let filetype = s:filetype_alias_table[a:filetype]
    return s:resolve_filetype_alias(filetype) | " 1 more hop
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

if !exists('g:unite_source_outline_ignore_heading_types')
  let g:unite_source_outline_ignore_heading_types = {}
endif

if !exists('g:unite_source_outline_max_headings')
  let g:unite_source_outline_max_headings = 1000
endif

if !exists('g:unite_source_outline_cache_dir')
  let here = expand('<sfile>:p:h')
  let g:unite_source_outline_cache_dir = here . '/outline/.cache'
endif

if !exists('g:unite_source_outline_cache_buffers')
  let g:unite_source_outline_cache_buffers = 50
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 100
endif

if !exists('g:unite_source_outline_cache_serialize_limit')
  let g:unite_source_outline_cache_serialize_limit = 1000
endif

"-----------------------------------------------------------------------------
" Aliases

let s:filetype_alias_table = {}

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
  " define it as an alias of the other filetype by default.
  if s:find_outline_info_file(alias) == ""
    call unite#sources#outline#alias(alias, src_filetype)
  endif
endfor
unlet alias | unlet src_filetype
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

function! s:source.gather_candidates(args, context)
  let save_ignorecase = &ignorecase
  set noignorecase

  try
    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
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

    if has_key(outline_info, 'initialize')
      call outline_info.initialize(s:context)
    endif

    let headings = s:extract_headings()

    if has_key(outline_info, 'finalize')
      call outline_info.finalize(s:context)
    endif

    call s:filter_headings(headings, s:get_ignore_heading_types(filetype))
    let levels = s:smooth_levels(headings)

    " headings -> candidates
    let cands = map(headings, '{
          \ "word"  : unite#sources#outline#util#indent(v:val["word"], levels[v:key]),
          \ "source": "outline",
          \ "kind"  : "jump_list",
          \ "action__path"     : path,
          \ "action__pattern"  : "^" . s:escape_regexp(v:val["line"]) . "$",
          \ "action__signature": self.calc_signature(v:val["line_idx"] + 1, s:buffer.lines),
          \ }')

    let is_volatile = has_key(outline_info, 'is_volatile') && outline_info.is_volatile
    if !is_volatile && (num_lines > g:unite_source_outline_cache_limit)
      let should_serialize = (num_lines > g:unite_source_outline_cache_serialize_limit)
      call cache.set_data(path, cands, should_serialize)
    elseif cache.has_data(path)
      call cache.remove_data(path)
    endif

    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
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
  let lines = s:buffer.lines | let num_lines = len(lines)

  if has_key(outline_info, 'skip_header')
    let s:line_idx = outline_info.skip_header(lines, s:context)

  elseif has_key(outline_info, 'skip') && has_key(outline_info.skip, 'header')
    " eval once
    let skip_header_leading = has_key(outline_info.skip.header, 'leading')
    let skip_header_block   = has_key(outline_info.skip.header, 'block')

    while s:line_idx < num_lines
      let line = lines[s:line_idx]
      if skip_header_leading && line =~# outline_info.skip.header.leading
        call s:skip_while(outline_info.skip.header.leading)
      elseif skip_header_block && line =~# outline_info.skip.header.block.begin
        call s:skip_to(outline_info.skip.header.block.end)
      else
        break
      endif
    endwhile
  endif

  return s:line_idx
endfunction

function! s:extract_headings()
  let s:line_idx = 0
  call s:skip_header()

  let outline_info = s:context.outline_info

  " eval once
  let skip_block = has_key(outline_info, 'skip') && has_key(outline_info.skip, 'block')
  let has_heading_pattern      = has_key(outline_info, 'heading')
  let has_heading_prev_pattern = has_key(outline_info, 'heading-1')
  let has_heading_next_pattern = has_key(outline_info, 'heading+1')
  let has_create_heading_func  = has_key(outline_info, 'create_heading')
  " NOTE: outline info is allowed to update heading patterns dynamically on
  " the runtime, so attribute values for them must not be assigned to local
  " variables.

  let headings = []
  let lines = s:buffer.lines | let num_lines = len(lines)

  while s:line_idx < num_lines
    let line = lines[s:line_idx]

    if skip_block && line =~# outline_info.skip.block.begin
      " skip a documentation block
      call s:skip_to(outline_info.skip.block.end)

    elseif has_heading_prev_pattern && line =~# outline_info['heading-1'] && s:line_idx < num_lines - 3
      " matched: heading-1
      let next_line = lines[s:line_idx + 1]
      if next_line =~ '[[:punct:]]\@!\S'
        if has_create_heading_func
          let s:context.heading_index = s:line_idx + 1
          let s:context.matched_index = s:line_idx
          let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
        else
          let heading = next_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading, next_line, s:line_idx + 1))
          let s:line_idx += 1
        endif
      elseif next_line =~ '\S' && s:line_idx < num_lines - 4
        " see one more next
        let next_line = lines[s:line_idx + 2]
        if next_line =~ '[[:punct:]]\@!\S'
          if has_create_heading_func
            let s:context.heading_index = s:line_idx + 2
            let s:context.matched_index = s:line_idx
            let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
          else
            let heading = next_line
          endif
          if !empty(heading)
            call add(headings, s:normalize_heading(heading, next_line, s:line_idx + 2))
            let s:line_idx += 2
          endif
        endif
      endif

    elseif has_heading_pattern && line =~# outline_info.heading
      " matched: heading
      if has_create_heading_func
        let s:context.heading_index = s:line_idx
        let s:context.matched_index = s:line_idx
        let heading = outline_info.create_heading('heading', line, line, s:context)
      else
        let heading = line
      endif
      if !empty(heading)
        call add(headings, s:normalize_heading(heading, line, s:line_idx))
      endif

    elseif has_heading_next_pattern && line =~# outline_info['heading+1'] && s:line_idx > 0
      " matched: heading+1
      let prev_line = lines[s:line_idx - 1]
      if prev_line =~ '[[:punct:]]\@!\S'
        if has_create_heading_func
          let s:context.heading_index = s:line_idx - 1
          let s:context.matched_index = s:line_idx
          let heading = outline_info.create_heading('heading+1', prev_line, line, s:context)
        else
          let heading = prev_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading, prev_line, s:line_idx - 1))
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
    let line = lines[s:line_idx]
    if line !~# a:pattern
      break
    endif
    let s:line_idx += 1
  endwhile
endfunction

function! s:skip_to(pattern)
  let lines = s:buffer.lines | let num_lines = len(lines)
  let s:line_idx += 1
  while s:line_idx < num_lines
    let line = lines[s:line_idx]
    if line =~# a:pattern
      break
    endif
    let s:line_idx += 1
  endwhile
endfunction

function! s:normalize_heading(heading, line, line_idx)
  if type(a:heading) == type("")
    " normalize to a Dictionary
    let heading = {
          \ 'word' : a:heading,
          \ 'level': unite#sources#outline#util#get_indent_level(a:heading, s:context),
          \ }
  else
    let heading = a:heading
  endif
  call extend(heading, {
        \ 'word' : a:line,
        \ 'level': 1,
        \ 'type' : 'generic' }, 'keep')
  let heading.word = s:normalize_heading_word(heading.word)
  let heading.line = a:line
  let heading.line_idx = a:line_idx
  return heading
endfunction

function! s:normalize_heading_word(str)
  let str = substitute(substitute(a:str, '^\s*', '', ''), '\s*$', '', '')
  let str = substitute(str, '\s\+', ' ', 'g')
  return str
endfunction

function! s:get_ignore_heading_types(filetype)
  if has_key(g:unite_source_outline_ignore_heading_types, a:filetype)
    return g:unite_source_outline_ignore_heading_types[a:filetype]
  else
    let resolved_filetype = s:resolve_filetype_alias(a:filetype)
    if has_key(g:unite_source_outline_ignore_heading_types, resolved_filetype)
      return g:unite_source_outline_ignore_heading_types[resolved_filetype]
    elseif has_key(g:unite_source_outline_ignore_heading_types, '*')
      return g:unite_source_outline_ignore_heading_types['*']
    else
      return []
    endif
  endif
endfunction

function! s:filter_headings(headings, ignore_types)
  if !empty(a:ignore_types)
    let ignore_types_pattern = '^\%(' . join(a:ignore_types, '\|') . '\)$'
    call filter(a:headings, 'v:val.type !~# ignore_types_pattern')
  endif
endfunction

function! s:smooth_levels(headings)
  let levels = map(copy(a:headings), 'v:val["level"]')
  return s:_smooth_levels(levels, 0)
endfunction
function! s:_smooth_levels(levels, base_level)
  let splitted = s:split_list(a:levels, a:base_level)
  for sub_levels in splitted
    let shift = min(sub_levels) - a:base_level - 1
    call map(sub_levels, 'v:val - shift')
  endfor
  call map(splitted, 'empty(v:val) ? v:val : s:_smooth_levels(v:val, a:base_level + 1)')
  return s:join_list(splitted, a:base_level)
endfunction

function! s:split_list(list, sep)
  let result = []
  let sub_list = []
  for value in a:list
    if value == a:sep
      call add(result, sub_list)
      let sub_list = []
    else
      call add(sub_list, value)
    endif
  endfor
  call add(result, sub_list)
  return result
endfunction

function! s:join_list(lists, sep)
  let result = []
  for sub_list in a:lists
    let result += sub_list
    let result += [a:sep]
  endfor
  call remove(result, -1)
  return result
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
    let bwd_lines = lines[from : idx]
    let fwd_lines = lines[idx  : to]
  else
    let from = max([1, a:lnum - range])
    let to   = min([a:lnum + range, line('$')])
    let bwd_lines = getline(from, a:lnum)
    let fwd_lines = getline(a:lnum, to)
  endif
  let bwd_lines = filter(bwd_lines, 'v:val =~ "\\S"')[-precision-1 : -2]
  let fwd_lines = filter(fwd_lines, 'v:val =~ "\\S"')[1 : precision]
  return join(map(bwd_lines + fwd_lines, 's:digest_line(v:val)'), '')
endfunction

" quick and dirty digest
function! s:digest_line(line)
  let line = substitute(a:line, '\s*', '', 'g')
  if s:strchars(line) <= 20
    let digest = line
  else
    let line = matchstr(line, '^\%(\%(.\{5}\)\{,20}\)')
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
