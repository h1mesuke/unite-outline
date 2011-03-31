"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-04-01
" Version : 0.3.3
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

let s:OUTLINE_INFO_PATH = [
      \ 'autoload/outline/',
      \ 'autoload/unite/sources/outline/',
      \ 'autoload/unite/sources/outline/defaults/',
      \ ]

function! unite#sources#outline#get_outline_info(filetype, ...)
  let is_default = (a:0 ? a:1 : 0)

  " NOTE: The filetype of the buffer may be a "compound filetype", a set of
  " filetypes separated by periods.
  let try_filetypes = [a:filetype]
  if a:filetype =~ '\.'
    " If the filetype is a compound one and has no outline info, fallback to
    " its major filetype which is the left most.
    call add(try_filetypes, split(a:filetype, '\.')[0])
  endif

  for filetype in try_filetypes
    let outline_info = s:get_outline_info(filetype, is_default)
    if !empty(outline_info) | return outline_info | endif
  endfor
  return {}
endfunction

function! unite#sources#outline#get_default_outline_info(filetype)
  return unite#sources#outline#get_outline_info(a:filetype, 1)
endfunction

function! s:get_outline_info(filetype, is_default)
  let filetype = s:resolve_filetype_alias(a:filetype)

  if has_key(g:unite_source_outline_info, filetype)
    return g:unite_source_outline_info[filetype]
  endif

  for path in (a:is_default ? s:OUTLINE_INFO_PATH[-1:] : s:OUTLINE_INFO_PATH)
    let load_func  = substitute(substitute(path, '^autoload/', '', ''), '/', '#', 'g')
    let load_func .= substitute(filetype, '\.', '_', 'g') . '#outline_info'
    try
      call {load_func}()
    catch /^Vim\%((\a\+)\)\=:E117:/
      " E117: Unknown function:
      continue
    endtry
    call s:check_update(s:find_autoload_script(load_func))
    return s:init_outline_info({load_func}())
  endfor
  return {}
endfunction

function! s:resolve_filetype_alias(filetype)
  if has_key(s:filetype_alias_table, a:filetype)
    let filetype = s:filetype_alias_table[a:filetype]
    return s:resolve_filetype_alias(filetype) | " 1 more hop
  endif
  return a:filetype
endfunction

let s:ftime_table = {}

function! s:check_update(path)
  let path = fnamemodify(a:path, ':p')
  let old_ftime = get(s:ftime_table, path, 0)
  let new_ftime = getftime(path)
  if new_ftime > old_ftime
    source `=path`
  endif
  let s:ftime_table[path] = new_ftime
  return (new_ftime > old_ftime)
endfunction

function! s:init_outline_info(outline_info)
  if has_key(a:outline_info, 'skip')
    call s:normalize_skip_info(a:outline_info)
  endif
  if has_key(a:outline_info, 'heading_groups')
    call s:init_heading_group_map(a:outline_info)
  endif
  return a:outline_info
endfunction

function! s:normalize_skip_info(outline_info)
  if has_key(a:outline_info.skip, 'header')
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
  if has_key(a:outline_info.skip, 'block')
    let value_type = type(a:outline_info.skip.block)
    if value_type == type([])
      let a:outline_info.skip.block = s:normalize_block_patterns(a:outline_info.skip.block)
    endif
  endif
endfunction

function! s:normalize_block_patterns(patterns)
  return { 'begin': a:patterns[0], 'end': a:patterns[1] }
endfunction

function! s:init_heading_group_map(outline_info)
  let groups = a:outline_info.heading_groups
  let group_map = {} | let group_id = 1
  for group_types in groups
    for heading_type in group_types
      let group_map[heading_type] = group_id
    endfor
    let group_id += 1
  endfor
  let a:outline_info.heading_group_map = group_map
endfunction

function! s:find_outline_info(filetype, ...)
  let filetype = substitute(a:filetype, '\.', '_', 'g')
  let is_default = (a:0 ? a:1 : 0)
  for path in (is_default ? s:OUTLINE_INFO_PATH[-1:] : s:OUTLINE_INFO_PATH)
    let oinfo_path = get(split(globpath(&runtimepath, path . filetype . '.vim'), "\<NL>"), 0, '')
    if !empty(oinfo_path) | return oinfo_path | endif
  endfor
  return ""
endfunction

function! unite#sources#outline#make_module(sid, prefix)

  " Original source from vital.vim
  " https://github.com/ujihisa/vital.vim
  "
  let prefix = '<SNR>' . a:sid . '_' . a:prefix . '_'
  redir => funcs
    silent! function
  redir END
  let is_module_func = 'v:val =~# "^function " . prefix'
  let remove_prefix = 'matchstr(v:val, prefix . "\\zs\\w\\+")'
  let module_funcs = map(filter(split(funcs, "\<NL>"), is_module_func), remove_prefix)

  let module = {}
  for func in module_funcs
    let module[func] = function(prefix . func)
  endfor

  return module
endfunction

function! unite#sources#outline#import(name)
  let name = tolower(substitute(a:name, '\(\l\)\(\u\)', '\1_\2', 'g'))
  let load_func = 'unite#sources#outline#modules#' . name . '#module'
  call s:check_update(s:find_autoload_script(load_func))
  return {load_func}()
endfunction

function! s:find_autoload_script(funcname)
  let path = 'autoload/' . join(split(a:funcname, '#')[:-2], '/') . '.vim'
  return get(split(globpath(&runtimepath, path), "\<NL>"), 0, '')
endfunction

function! unite#sources#outline#clear_cache()
  let s:cache = unite#sources#outline#import('cache')
  call s:cache.clear()
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

if !exists('g:unite_source_outline_cache_buffers')
  let g:unite_source_outline_cache_buffers = 100
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 1000
endif

"-----------------------------------------------------------------------------
" Aliases

let s:filetype_alias_table = {}

let s:default_alias_map = [
      \ ['c',        'cpp'     ],
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
  if empty(s:find_outline_info(alias))
    call unite#sources#outline#alias(alias, src_filetype)
  endif
endfor
unlet alias | unlet src_filetype
unlet s:default_alias_map

"-----------------------------------------------------------------------------
" Source

let s:source = {
      \ 'name'       : 'outline',
      \ 'description': 'candidates from heading list',
      \
      \ 'hooks': {}, 'action_table'  : {}, 'alias_table': {}, 'default_action': {},
      \ }

function! s:source.hooks.on_init(args, context)
  let s:cache = unite#sources#outline#import('cache')
  let s:tree  = unite#sources#outline#import('tree')
  let s:util  = unite#sources#outline#import('util')

  let s:heading_id = 1

  let buffer = {
        \ 'nr'        : bufnr('%'),
        \ 'path'      : expand('%:p'),
        \ 'filetype'  : getbufvar('%', '&filetype'),
        \ 'shiftwidth': getbufvar('%', '&shiftwidth'),
        \ 'tabstop'   : getbufvar('%', '&tabstop'),
        \ }
  let compound_filetypes = split(buffer.filetype, '\.')
  call extend(buffer, {
        \ 'major_filetype': get(compound_filetypes, 0, ''),
        \ 'minor_filetype': get(compound_filetypes, 1, ''),
        \ 'compound_filetypes': compound_filetypes,
        \ })
  let outline_info = unite#sources#outline#get_outline_info(buffer.filetype)
  let s:context = {
        \ 'buffer': buffer,
        \ 'outline_info': outline_info,
        \ }
  let a:context.source__outline_context = s:context
endfunction

function! s:source.hooks.on_close(args, context)
  unlet! s:context
endfunction

function! s:source.gather_candidates(args, context)
  let save_cpoptions  = &cpoptions
  let save_ignorecase = &ignorecase
  set cpoptions&vim
  set noignorecase

  try
    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
      let start_time = s:get_reltime()
    endif

    let is_force = ((len(a:args) > 0 && a:args[0] == '!') || a:context.is_redraw)

    let path = s:context.buffer.path
    if s:cache.has(path) && !is_force
      try
        return s:cache.get(path)
      catch /^CacheCompatibilityError/
      catch /^unite-outline:/
        call unite#util#print_error(v:exception)
      endtry
    endif

    let filetype = s:context.buffer.filetype
    let outline_info = s:context.outline_info

    if empty(outline_info)
      if empty(filetype)
        call unite#util#print_error("unite-outline: Please set the filetype.")
      else
        call unite#util#print_error(
              \ "unite-outline: Sorry, " . toupper(filetype) . " is not supported.")
      endif
      return []
    endif

    let lines = [""] + getbufline(s:context.buffer.nr, 1, '$')
    let num_lines = len(lines) - 1

    let s:context.outline_info = outline_info
    let s:context.lines = lines
    let s:context.heading_lnum = 0
    let s:context.matched_lnum = 0

    if has_key(outline_info, 'initialize')
      call outline_info.initialize(s:context)
    endif

    if has_key(outline_info, 'extract_headings')
      let headings = outline_info.extract_headings(s:context)
      let normalized = 0
    else
      let headings = s:extract_headings()
      let normalized = 1
    endif

    if has_key(outline_info, 'finalize')
      call outline_info.finalize(s:context)
    endif

    let ignore_types = unite#sources#outline#get_ignore_heading_types(filetype)

    " normalize and filter
    if type(headings) == type({})
      let tree_root = headings | unlet headings
      let headings  = s:tree.flatten(s:tree.normalize(tree_root))
      call s:filter_headings(headings, ignore_types, 1)
      call map(headings, 's:normalize_heading(v:val)')
    else
      call s:filter_headings(headings, ignore_types, 1)
      if !normalized
        call map(headings, 's:normalize_heading(v:val)')
      endif
      let tree_root = s:tree.build(headings)
    endif
    let headings = s:filter_headings(headings, ignore_types)

    unlet s:context.heading_lnum
    unlet s:context.matched_lnum

    " headings -> candidates
    let candidates = s:convert_headings_to_candidates(headings)

    let is_volatile = has_key(outline_info, 'is_volatile') && outline_info.is_volatile
    if !is_volatile && (num_lines > 100)
      let do_serialize = (num_lines > g:unite_source_outline_cache_limit)
      call s:cache.set(path, candidates, do_serialize)
    elseif s:cache.has(path)
      call s:cache.remove(path)
    endif

    if exists('g:unite_source_outline_profile') && g:unite_source_outline_profile && has("reltime")
      let used_time = s:get_reltime() - start_time
      let used_time_100l = used_time * (str2float("100") / num_lines)
      call s:util.print_progress("unite-outline: used=" . string(used_time) . "s, "
            \ . "100l=". string(used_time_100l) . "s")
    endif

    return candidates
  catch
    call unite#util#print_error(v:throwpoint)
    call unite#util#print_error(v:exception)
    return []
  finally
    let &cpoptions  = save_cpoptions
    let &ignorecase = save_ignorecase
  endtry
endfunction

function! s:get_reltime()
  return str2float(reltimestr(reltime()))
endfunction

function! s:skip_header()
  let outline_info = s:context.outline_info
  let lines = s:context.lines | let num_lines = len(lines)

  if has_key(outline_info, 'skip') && has_key(outline_info.skip, 'header')
    " eval once
    let skip_header_leading = has_key(outline_info.skip.header, 'leading')
    let skip_header_block   = has_key(outline_info.skip.header, 'block')

    while s:lnum < num_lines
      let line = lines[s:lnum]
      if skip_header_leading && line =~# outline_info.skip.header.leading
        call s:skip_while(outline_info.skip.header.leading)
      elseif skip_header_block && line =~# outline_info.skip.header.block.begin
        call s:skip_to(outline_info.skip.header.block.end)
      else
        break
      endif
    endwhile
  endif
endfunction

function! s:extract_headings()
  let s:lnum = 1

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
  let lines = s:context.lines | let num_lines = len(lines)

  while s:lnum < num_lines
    let line = lines[s:lnum]

    if skip_block && line =~# outline_info.skip.block.begin
      " skip a documentation block
      call s:skip_to(outline_info.skip.block.end)

    elseif has_heading_prev_pattern && line =~# outline_info['heading-1'] && s:lnum < num_lines - 3
      " matched: heading-1
      let next_line = lines[s:lnum + 1]
      if next_line =~ '[[:punct:]]\@!\S'
        let s:context.heading_lnum = s:lnum + 1
        let s:context.matched_lnum = s:lnum
        if has_create_heading_func
          let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
        else
          let heading = next_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading))
          let s:lnum += 1
        endif
      elseif next_line =~ '\S' && s:lnum < num_lines - 4
        " see one more next
        let next_line = lines[s:lnum + 2]
        if next_line =~ '[[:punct:]]\@!\S'
          let s:context.heading_lnum = s:lnum + 2
          let s:context.matched_lnum = s:lnum
          if has_create_heading_func
            let heading = outline_info.create_heading('heading-1', next_line, line, s:context)
          else
            let heading = next_line
          endif
          if !empty(heading)
            call add(headings, s:normalize_heading(heading))
            let s:lnum += 2
          endif
        endif
      endif

    elseif has_heading_pattern && line =~# outline_info.heading
      " matched: heading
      let s:context.heading_lnum = s:lnum
      let s:context.matched_lnum = s:lnum
      if has_create_heading_func
        let heading = outline_info.create_heading('heading', line, line, s:context)
      else
        let heading = line
      endif
      if !empty(heading)
        call add(headings, s:normalize_heading(heading))
      endif

    elseif has_heading_next_pattern && line =~# outline_info['heading+1'] && s:lnum > 0
      " matched: heading+1
      let prev_line = lines[s:lnum - 1]
      if prev_line =~ '[[:punct:]]\@!\S'
        let s:context.heading_lnum = s:lnum - 1
        let s:context.matched_lnum = s:lnum
        if has_create_heading_func
          let heading = outline_info.create_heading('heading+1', prev_line, line, s:context)
        else
          let heading = prev_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading))
        endif
      endif
    endif

    if s:lnum % 500 == 0
      if len(headings) > g:unite_source_outline_max_headings
        call unite#util#print_error(
              \ "unite-outline: Too many headings, the extraction was interrupted.")
        break
      else
        call s:util.print_progress("Extracting headings..." . s:lnum * 100 / num_lines . "%")
      endif
    endif

    let s:lnum += 1
  endwhile
  call s:util.print_progress("Extracting headings...done.")

  return headings
endfunction

function! s:skip_while(pattern)
  let lines = s:context.lines | let num_lines = len(lines)
  let s:lnum += 1
  while s:lnum < num_lines
    let line = lines[s:lnum]
    if line !~# a:pattern
      break
    endif
    let s:lnum += 1
  endwhile
endfunction

function! s:skip_to(pattern)
  let lines = s:context.lines | let num_lines = len(lines)
  let s:lnum += 1
  while s:lnum < num_lines
    let line = lines[s:lnum]
    if line =~# a:pattern
      break
    endif
    let s:lnum += 1
  endwhile
endfunction

function! s:normalize_heading(heading)
  if type(a:heading) == type("")
    " normalize to a Dictionary
    let level = unite#sources#outline#
          \util#get_indent_level(s:context, s:context.heading_lnum)
    let heading = {
          \ 'word' : a:heading,
          \ 'level': level,
          \ }
  else
    let heading = a:heading
  endif

  let heading.source__id = s:heading_id
  let heading.word = s:normalize_heading_word(heading.word)
  call extend(heading, {
        \ 'level': 1,
        \ 'type' : 'generic',
        \ 'lnum' : s:context.heading_lnum,
        \ }, 'keep')
  let s:heading_id += 1

  return heading
endfunction

function! s:normalize_heading_word(heading_word)
  let heading_word = substitute(substitute(a:heading_word, '^\s*', '', ''), '\s*$', '', '')
  let heading_word = substitute(heading_word, '\s\+', ' ', 'g')
  return heading_word
endfunction

" Heading Type Filter
function! s:filter_headings(headings, ignore_types, ...)
  let headings = a:headings
  let remove_comments = (a:0 ? a:1 : 0)

  if !empty(a:ignore_types)
    if remove_comments
      if index(a:ignore_types, 'comment') >= 0
        call filter(headings, 'v:val.type !=# "comment"')
      endif
    else
      let ignore_types = map(copy(a:ignore_types), 'unite#util#escape_pattern(v:val)')
      let ignore_types_pattern = '^\%(' . join(ignore_types, '\|') . '\)$'

      " something like closure
      let pred = {}
      let pred.ignore_types_pattern = ignore_types_pattern
      function pred.call(heading)
        return (a:heading.type !~# self.ignore_types_pattern)
      endfunction

      let headings = s:tree.filter(headings, pred, 1)
    endif
  endif

  return headings
endfunction

function! unite#sources#outline#get_ignore_heading_types(filetype)
  for filetype in [a:filetype, s:resolve_filetype_alias(a:filetype), '*']
    if has_key(g:unite_source_outline_ignore_heading_types, filetype)
      return g:unite_source_outline_ignore_heading_types[filetype]
    endif
  endfor
  return []
endfunction

function! s:convert_headings_to_candidates(headings)
  if empty(a:headings) | return a:headings | endif

  let physical_levels = s:smooth_levels(a:headings)
  let candidates = map(s:util.list.zip(a:headings, physical_levels),
        \ 's:create_candidate(v:val[0], v:val[1])')
  return candidates
endfunction

function! s:create_candidate(heading, physical_level)
  let heading = {
        \ 'word' : a:heading.word,
        \ 'level': a:heading.level,
        \ 'type' : a:heading.type,
        \ 'lnum' : a:heading.lnum,
        \
        \ 'physical_level' : a:physical_level,
        \ }

  " NOTE: To keep the tree structure of the headings, convert a heading
  " Dictionary to a candidate Dictionary in-place.
  "
  let cand = a:heading
  let heading.candidate = cand
  call extend(cand, {
        \ 'word': s:make_indent(a:physical_level) . a:heading.word,
        \ 'source': 'outline',
        \ 'kind'  : 'jump_list',
        \ 'action__path': s:context.buffer.path,
        \ 'action__pattern'  : s:make_search_pattern(s:context.lines[a:heading.lnum]),
        \ 'action__signature': s:source.calc_signature(a:heading.lnum, s:context.lines),
        \
        \ 'source__heading': heading,
        \ })
  unlet cand.level
  unlet cand.type
  unlet cand.lnum

  return cand
endfunction

function! s:make_indent(level)
  return repeat(' ', (a:level - 1) * g:unite_source_outline_indent_width)
endfunction

function! s:make_search_pattern(line)
  return '^' . unite#util#escape_pattern(a:line) . '$'
endfunction

function! s:smooth_levels(headings)
  let levels = map(copy(a:headings), 'v:val.level')
  return s:_smooth_levels(levels, 0)
endfunction
function! s:_smooth_levels(levels, base_level)
  let splitted = s:util.list.split(a:levels, a:base_level)
  for sub_levels in splitted
    let shift = min(sub_levels) - a:base_level - 1
    call map(sub_levels, 'v:val - shift')
  endfor
  call map(splitted, 'empty(v:val) ? v:val : s:_smooth_levels(v:val, a:base_level + 1)')
  return s:util.list.join(splitted, a:base_level)
endfunction

function! s:source.calc_signature(lnum, ...)
  let range = 10 | let precision = 2
  if a:0
    let lines = a:1
    let from = max([1, a:lnum - range])
    let to   = min([a:lnum + range, len(lines) - 1])
    let bwd_lines = lines[from : a:lnum]
    let fwd_lines = lines[a:lnum  : to]
  else
    let from = max([1, a:lnum - range])
    let to   = min([a:lnum + range, line('$')])
    let bwd_lines = getline(from, a:lnum)
    let fwd_lines = getline(a:lnum, to)
  endif
  let is_not_blank = 'v:val =~ "\\S"'
  let bwd_lines = filter(bwd_lines, is_not_blank)[-precision-1 : -2]
  let fwd_lines = filter(fwd_lines, is_not_blank)[1 : precision]
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
    call unite#util#print_error("unite-outline: Can't preview the nofile buffer.")
    return
  endif

  " workaround for `cursor-goes-to-top' problem on :pedit %
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

let s:action_table = {}
let s:action_table.nop_ = {
      \ 'description'  : 'do nothing',
      \ 'is_selectable': 0,
      \ }
function! s:action_table.nop_.func(candidate)
endfunction

let s:source.action_table.common = s:action_table
let s:source.default_action.common = 'nop_'
unlet s:action_table

let s:source.alias_table.common = {}
for action in ['yank', 'yank_escape', 'ex', 'insert']
  let s:source.alias_table.common[action] = 'nop'
endfor

"---------------------------------------
" Filters

call unite#custom_filters('outline', ['outline_matcher_glob_tree', 'outline_formatter'])

" vim: filetype=vim
