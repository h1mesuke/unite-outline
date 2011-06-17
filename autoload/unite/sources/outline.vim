"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-16
" Version : 0.3.5
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

"-----------------------------------------------------------------------------
" Constants

let s:OUTLINE_INFO_PATH = [
      \ 'autoload/outline/',
      \ 'autoload/unite/sources/outline/',
      \ 'autoload/unite/sources/outline/defaults/',
      \ ]

let s:OUTLINE_ALIASES = [
      \ ['c',        'cpp'     ],
      \ ['cfg',      'dosini'  ],
      \ ['mkd',      'markdown'],
      \ ['plaintex', 'tex'     ],
      \ ['snippet',  'conf'    ],
      \ ['xhtml',    'html'    ],
      \ ['zsh',      'sh'      ],
      \]

let s:OUTLINE_CACHE_VAR = 'unite_source_outline_cache'

"-----------------------------------------------------------------------------
" Functions

function! unite#sources#outline#define()
  return s:source
endfunction

function! unite#sources#outline#alias(alias, src_filetype)
  if !exists('s:filetype_alias_table')
    let s:filetype_alias_table = {}
  endif
  let s:filetype_alias_table[a:alias] = a:src_filetype
endfunction

function! unite#sources#outline#get_outline_info(filetype, ...)
  let is_default = (a:0 ? a:1 : 0)

  " NOTE: The filetype of the buffer may be a "compound filetype", a set of
  " filetypes separated by periods. If the filetype is a compound one and has
  " no outline info, fallback to its major filetype which is the left most.
  "
  let try_filetypes = [a:filetype]
  if a:filetype =~ '\.'
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
    try
      let scr_path = s:find_autoload_script(load_func)
    catch /^ScriptNotFoundError:/
      " the user moved his/her outline info somewhere!
      continue
    endtry
    call s:check_update(scr_path)
    let outline_info = {load_func}()
    let outline_info = s:normalize_outline_info(outline_info)
    return outline_info
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

function! s:check_update(path)
  if !exists('s:ftime_table')
    let s:ftime_table = {}
  endif
  let path = fnamemodify(a:path, ':p')
  let new_ftime = getftime(path)
  let old_ftime = get(s:ftime_table, path, new_ftime)
  if new_ftime > old_ftime
    source `=path`
  endif
  let s:ftime_table[path] = new_ftime
  return (new_ftime > old_ftime)
endfunction

function! s:normalize_outline_info(outline_info)
  if !has_key(a:outline_info, '__normalized__')
    call extend(a:outline_info, { 'is_volatile': 0 }, 'keep' )
    if has_key(a:outline_info, 'skip')
      call s:normalize_skip_info(a:outline_info)
    endif
    call s:normalize_heading_groups(a:outline_info)
    if has_key(a:outline_info, 'not_match_patterns')
      let a:outline_info.__not_match_pattern__ =
            \ '\%(' . join(a:outline_info.not_match_patterns, '\|') . '\)'
    else
      let a:outline_info.__not_match_pattern__ = ''
    endif
    let a:outline_info.__normalized__ = 1
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

function! s:normalize_heading_groups(outline_info)
  if !has_key(a:outline_info, 'heading_groups')
    let a:outline_info.heading_groups = {}
    let group_map = {}
  else
    let groups = keys(a:outline_info.heading_groups)
    let group_map = {}
    for group in groups
      let group_types = a:outline_info.heading_groups[group]
      for heading_type in group_types
        let group_map[heading_type] = group
      endfor
    endfor
  endif
  let group_map.generic = 'generic'
  let a:outline_info.heading_group_map = group_map
endfunction

function! unite#sources#outline#import(name, ...)
  let name = tolower(substitute(a:name, '\(\l\)\(\u\)', '\1_\2', 'g'))
  return call('unite#sources#outline#modules#' . name . '#import', a:000)
endfunction

function! s:find_autoload_script(funcname)
  if !exists('s:autoload_scripts')
    let s:autoload_scripts = {}
  endif
  if has_key(s:autoload_scripts, a:funcname)
    let path =  s:autoload_scripts[a:funcname]
    if filereadable(path)
      return s:autoload_scripts[a:funcname]
    else
      " the script was moved somewhere for some reason...
      unlet s:autoload_scripts[a:funcname]
    endif
  endif
  let path_list = split(a:funcname, '#')
  let rel_path = 'autoload/' . join(path_list[:-2], '/') . '.vim'
  let path = get(split(globpath(&runtimepath, rel_path), "\<NL>"), 0, '')
  if empty(path)
    throw "ScriptNotFoundError: Script file not found for " . a:funcname
  else
    let s:autoload_scripts[a:funcname] = path
  endif
  return path
endfunction

function! unite#sources#outline#clear_cache()
  call s:Cache.clear()
endfunction

"-----------------------------------------------------------------------------
" Key-mappings

let g:unite_source_outline_input = ''

function! s:jump_to_match(...)
  if unite#get_context().buffer_name !=# 'outline'
    call unite#print_error("unite-outline: Invalid buffer name.")
    return
  endif
  let flags = (a:0 ? a:1 : '')
  let forward = (flags !~# 'b')
  if empty(g:unite_source_outline_input)
    execute 'normal' "\<Plug>(unite_loop_cursor_" . (forward ? 'down' : 'up') . ')'
  else
    for i in range(3)
      execute 'normal!' (forward ? '$' : '0')
      call search('\c' . g:unite_source_outline_input, 'w' . flags)
      if winline() > 2 | break | endif
    endfor
  endif
endfunction

nnoremap <silent> <Plug>(unite_source_outline_loop_cursor_down)
      \ :<C-u>call <SID>jump_to_match()<CR>

nnoremap <silent> <Plug>(unite_source_outline_loop_cursor_up)
      \ :<C-u>call <SID>jump_to_match('b')<CR>

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

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 1000
endif

"---------------------------------------
" Aliases

function! s:define_filetype_aliases()

  " NOTE: If the user has his/her own outline info for a filetype, not define
  " it as an alias of the other filetype by default.
  "
  let oinfos = {}
  for path in s:OUTLINE_INFO_PATH[:-2]
    let oinfo_paths = split(globpath(&rtp, path . '*.vim'), "\<NL>")
    for filetype in map(oinfo_paths, 'matchstr(v:val, "\\w\\+\\ze\\.vim$")')
      let filetype = substitute(filetype, '_', '.', 'g')
      let oinfos[filetype] = 1
    endfor
  endfor

  for [alias, src_filetype] in s:OUTLINE_ALIASES
    if !has_key(oinfos, alias)
      call unite#sources#outline#alias(alias, src_filetype)
    endif
  endfor
endfunction

call s:define_filetype_aliases()

"-----------------------------------------------------------------------------
" Source

let s:Cache = unite#sources#outline#import('Cache', g:unite_data_directory . '/.outline')
let s:Tree  = unite#sources#outline#import('Tree')
let s:Util  = unite#sources#outline#import('Util')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:source = {
      \ 'name'       : 'outline',
      \ 'description': 'candidates from heading list',
      \
      \ 'hooks': {}, 'action_table': {}, 'alias_table': {}, 'default_action': {},
      \ }

function! s:Source_Hooks_on_init(args, context)
  let s:heading_id = 1
  let buffer = {
        \ 'nr'  : bufnr('%'),
        \ 'path': expand('%:p'),
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
let s:source.hooks.on_init = function(s:SID . 'Source_Hooks_on_init')

function! s:Source_Hooks_on_close(args, context)
  unlet! s:context
endfunction
let s:source.hooks.on_close = function(s:SID . 'Source_Hooks_on_close')

function! s:Source_gather_candidates(args, context)
  let save_cpoptions  = &cpoptions
  let save_ignorecase = &ignorecase
  set cpoptions&vim
  set noignorecase
  try
    let is_force = ((len(a:args) > 0 && a:args[0] == '!') || a:context.is_redraw)
    let buffer = s:context.buffer

    let bufvars = getbufvar(buffer.nr, '')
    if has_key(bufvars, s:OUTLINE_CACHE_VAR) && !is_force
      " Path A: Get candidates from the buffer local cache and return them.
      let candidates = getbufvar(buffer.nr, s:OUTLINE_CACHE_VAR)
      return candidates
    endif

    let cache_loaded = 0
    if s:Cache.has(buffer) && !is_force
      " Path B1: Get headings from the serialized cache.
      try
        let headings = s:Cache.get(buffer)
        let cache_loaded = 1
      catch /^CacheCompatibilityError:/
      catch /^unite-outline:/
        call unite#util#print_error(v:exception)
      endtry
    endif
    if !cache_loaded
      " Path B2: Get headings by parsing the buffer.
      let start_time = s:benchmark_start()

      if is_force
        " re-source the outline info if updated
        let s:context.outline_info =
              \ unite#sources#outline#get_outline_info(buffer.filetype)
      endif

      let outline_info = s:context.outline_info
      if empty(outline_info)
        if empty(buffer.filetype)
          call unite#print_message("unite-outline: Please set the filetype.")
        else
          call unite#print_message("unite-outline: Sorry, " .
                \ toupper(buffer.filetype) . " is not supported.")
        endif
        return []
      endif

      let lines = [""] + getbufline(s:context.buffer.nr, 1, '$')
      let num_lines = len(lines) - 1
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

      let ignore_types = unite#sources#
            \outline#get_ignore_heading_types(buffer.filetype)

      " normalize and filter headings
      if type(headings) == type({})
        let tree = headings | unlet headings
        let tree = s:Tree.normalize(tree)
        let headings  = s:Tree.flatten(tree)
        call s:filter_headings(headings, ignore_types, 1)
        call map(headings, 's:normalize_heading(v:val)')
      else
        call s:filter_headings(headings, ignore_types, 1)
        if !normalized
          call map(headings, 's:normalize_heading(v:val)')
        endif
        let tree = s:Tree.build(headings)
      endif
      let headings = s:filter_headings(headings, ignore_types)

      unlet s:context.heading_lnum
      unlet s:context.matched_lnum

      if !outline_info.is_volatile && num_lines > 100 && !empty(headings)
        let is_persistant = (num_lines > g:unite_source_outline_cache_limit)
        call s:Cache.set(buffer, headings, is_persistant)
      elseif s:Cache.has(buffer)
        call s:Cache.remove(buffer)
      endif

      call s:benchmark_stop(start_time)
    endif

    " headings -> candidates
    let candidates = s:convert_headings_to_candidates(headings)
    call setbufvar(buffer.nr, s:OUTLINE_CACHE_VAR, candidates)

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
let s:source.gather_candidates = function(s:SID . 'Source_gather_candidates')

function! s:benchmark_start()
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    return s:get_reltime()
  else
    return 0
  endif
endfunction

function! s:benchmark_stop(start_time)
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    let num_lines = len(s:context.lines)
    let used_time = s:get_reltime() - a:start_time
    let used_time_100l = used_time * (str2float("100") / num_lines)
    call s:Util.print_progress("unite-outline: used=" . string(used_time) .
          \ "s, 100l=". string(used_time_100l) . "s")
  endif
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
  " variables here.

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
        call unite#print_message(
              \ "unite-outline: Too many headings, the extraction was interrupted.")
        break
      else
        call s:Util.print_progress("Extracting headings..." . s:lnum * 100 / num_lines . "%")
      endif
    endif
    let s:lnum += 1
  endwhile
  call s:Util.print_progress("Extracting headings...done.")

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
    let level = s:Util.get_indent_level(s:context, s:context.heading_lnum)
    let heading = {
          \ 'word' : a:heading,
          \ 'level': level,
          \ }
  else
    let heading = a:heading
  endif
  let heading.id = s:heading_id
  let heading.word = s:normalize_heading_word(heading.word)
  call extend(heading, {
        \ 'level': 1,
        \ 'type' : 'generic',
        \ 'lnum' : s:context.heading_lnum,
        \ 'keyword': heading.word,
        \ 'is_marked' : 1,
        \ 'is_matched': 0,
        \ }, 'keep')
  let heading.line = s:context.lines[heading.lnum]
  let heading.pattern = s:make_search_pattern(heading.line)
  let heading.signature = s:calc_signature(heading.lnum, s:context.lines)
  let outline_info = s:context.outline_info
  if !has_key(heading, 'group')
    let group_map = outline_info.heading_group_map
    let heading.group = get(group_map, heading.type, 'generic')
  endif
  if !has_key(heading, 'keyword') && !empty(outline_info.__not_match_pattern__)
    let heading.keyword =
          \ substitute(heading.word, outline_info.__not_match_pattern__, '', 'g')
  endif
  let s:heading_id += 1
  return heading
endfunction

function! s:normalize_heading_word(heading_word)
  let heading_word = substitute(substitute(a:heading_word, '^\s*', '', ''), '\s*$', '', '')
  let heading_word = substitute(heading_word, '\s\+', ' ', 'g')
  return heading_word
endfunction

function! s:make_search_pattern(line)
  return '^' . unite#util#escape_pattern(a:line) . '$'
endfunction

let s:SIGNATURE_RANGE = 10
let s:SIGNATURE_PRECISION = 2

function! s:calc_signature(lnum, lines)
  let range = s:SIGNATURE_RANGE
  let from = max([1, a:lnum - range])
  let to   = min([a:lnum + range, len(a:lines) - 1])
  let bwd_lines = a:lines[from : a:lnum]
  let fwd_lines = a:lines[a:lnum  : to]
  return s:_calc_signature(bwd_lines, fwd_lines)
endfunction
function! s:_calc_signature(bwd_lines, fwd_lines)
  let precision = s:SIGNATURE_PRECISION
  let is_not_blank = 'v:val =~ "\\S"'
  let bwd_lines = filter(a:bwd_lines, is_not_blank)[-precision-1 : -2]
  let fwd_lines = filter(a:fwd_lines, is_not_blank)[1 : precision]
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

" Heading Type Filter
function! s:filter_headings(headings, ignore_types, ...)
  let headings = a:headings
  if !empty(a:ignore_types)
    let remove_comments = (a:0 ? a:1 : 0)
    if remove_comments
      if index(a:ignore_types, 'comment') >= 0
        call filter(headings, 'v:val.type !=# "comment"')
      endif
    else
      let ignore_types = map(copy(a:ignore_types), 'unite#util#escape_pattern(v:val)')
      let ignore_types_pattern = '^\%(' . join(ignore_types, '\|') . '\)$'

      " something like closure
      let predicate = {}
      let predicate.ignore_types_pattern = ignore_types_pattern
      function predicate.call(heading)
        return (a:heading.type !~# self.ignore_types_pattern)
      endfunction

      let headings = s:Tree.filter(a:headings, predicate, 1)
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
  if empty(a:headings) | return [] | endif

  let outline_info = s:context.outline_info
  let physical_levels = s:smooth_levels(a:headings)
  let candidates = []
  for [heading, physical_level] in s:Util.List.zip(a:headings, physical_levels)
    let heading.physical_level = physical_level
    let cand = s:create_candidate(heading, physical_level)
    call add(candidates, cand)
  endfor
  return candidates
endfunction

function! s:create_candidate(heading, physical_level)
  " NOTE:
  "   abbr - String for displaying
  "   word - String for narrowing
  let cand = {
        \ 'abbr': s:make_indent(a:physical_level) . a:heading.word,
        \ 'word': a:heading.keyword,
        \ 'source': 'outline',
        \ 'kind'  : 'jump_list',
        \ 'action__path': s:context.buffer.path,
        \ 'action__pattern'  : a:heading.pattern,
        \ 'action__signature': a:heading.signature,
        \
        \ 'source__heading'   : a:heading,
        \ }
  let a:heading.__unite_candidate__ = cand
  return cand
endfunction

function! s:make_indent(level)
  return repeat(' ', (a:level - 1) * g:unite_source_outline_indent_width)
endfunction

function! s:smooth_levels(headings)
  let levels = map(copy(a:headings), 'v:val.level')
  return s:_smooth_levels(levels, 0)
endfunction
function! s:_smooth_levels(levels, base_level)
  let splitted = s:Util.List.split(a:levels, a:base_level)
  for sub_levels in splitted
    let shift = min(sub_levels) - a:base_level - 1
    call map(sub_levels, 'v:val - shift')
  endfor
  call map(splitted, 'empty(v:val) ? v:val : s:_smooth_levels(v:val, a:base_level + 1)')
  return s:Util.List.join(splitted, a:base_level)
endfunction

function! s:Source_calc_signature(lnum)
  let range = s:SIGNATURE_RANGE
  let from = max([1, a:lnum - range])
  let to   = min([a:lnum + range, line('$')])
  let bwd_lines = getline(from, a:lnum)
  let fwd_lines = getline(a:lnum, to)
  return s:_calc_signature(bwd_lines, fwd_lines)
endfunction
let s:source.calc_signature = function(s:SID . 'Source_calc_signature')

"---------------------------------------
" Actions

let s:action_table = {}
let s:action_table.preview = {
      \ 'description'  : 'preview this position',
      \ 'is_selectable': 0,
      \ 'is_quit'      : 0,
      \ }
function! s:Action_preview(candidate)
  let cand = a:candidate

  " NOTE: Executing :pedit for a nofile buffer clears the buffer content at
  " all, so prohibit it.
  let bufnr = bufnr(unite#util#escape_file_searching(cand.action__path))
  if getbufvar(bufnr, '&buftype') =~# '\<nofile\>'
    call unite#print_error("unite-outline: Can't preview the nofile buffer.")
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
let s:action_table.preview.func = function(s:SID . 'Action_preview')

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

"---------------------------------------
" Filters

call unite#custom_filters('outline', ['outline_matcher_glob', 'outline_formatter'])

" vim: filetype=vim
