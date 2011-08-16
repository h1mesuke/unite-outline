"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-08-16
" Version : 0.3.7
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
      " The user moved his/her outline info somewhere!
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
      " The script was moved somewhere for some reason...
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

" For backward compatibility.
nmap <Plug>(unite_source_outline_loop_cursor_down) <Plug>(unite_skip_cursor_down)
nmap <Plug>(unite_source_outline_loop_cursor_up) <Plug>(unite_skip_cursor_up)

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

if !exists('g:unite_source_outline_highlight')
  let g:unite_source_outline_highlight = {}
endif
call extend(g:unite_source_outline_highlight, {
      \ 'comment' : 'Comment',
      \ 'function': 'Function',
      \ 'macro'   : 'Macro',
      \ 'method'  : 'Function',
      \ 'normal'  : g:unite_abbr_highlight,
      \ 'package' : g:unite_abbr_highlight,
      \ 'special' : 'Macro',
      \ 'type'    : 'Type',
      \ 'level_1' : 'Type',
      \ 'level_2' : 'PreProc',
      \ 'level_3' : 'Identifier',
      \ 'level_4' : 'Constant',
      \ 'level_5' : 'Special',
      \ 'level_6' : g:unite_abbr_highlight,
      \ 'parameter_list': g:unite_abbr_highlight,
      \ }, 'keep')

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
      \ 'syntax'     : 'uniteSource__Outline',
      \
      \ 'hooks': {}, 'action_table': {}, 'alias_table': {}, 'default_action': {},
      \ }

function! s:Source_Hooks_on_init(args, context)
  let s:heading_id = 1
  " Collect the current buffer's information.
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

function! s:Source_Hooks_on_syntax(args, context)
  let outline_context = a:context.source__outline_context
  let outline_info = outline_context.outline_info

  if outline_context.method ==# 'filetype'
    " Filetype
    if has_key(outline_info, 'highlight_rules')
      for hl_rule in outline_info.highlight_rules
        if !has_key(hl_rule, 'highlight')
          let hl_rule.highlight = g:unite_source_outline_highlight[hl_rule.name]
        endif
        execute 'syntax match uniteSource__Outline_' . hl_rule.name hl_rule.pattern
              \ 'contained containedin=uniteSource__Outline'
        execute 'highlight default link uniteSource__Outline_' . hl_rule.name hl_rule.highlight
      endfor
    endif
  endif
endfunction
let s:source.hooks.on_syntax = function(s:SID . 'Source_Hooks_on_syntax')

function! s:Source_gather_candidates(args, context)
  " Save and set Vim options.
  let save_cpoptions  = &cpoptions
  let save_ignorecase = &ignorecase
  let save_magic = &magic
  set cpoptions&vim
  set noignorecase
  set magic
  try
    let opts = s:parse_options(a:args, a:context)
    call extend(s:context, opts)

    let buffer = s:context.buffer
    let bufvars = getbufvar(buffer.nr, '')
    if has_key(bufvars, s:OUTLINE_CACHE_VAR)
      " Path A: Get candidates from the buffer local cache and return them.
      let candidates = getbufvar(buffer.nr, s:OUTLINE_CACHE_VAR)
      let method = (!empty(candidates) &&
            \ candidates[0].source__heading.type ==# 'folding' ? 'folding' : 'filetype')
      if s:context.method ==# 'last'
        let s:context.method = method
      endif
      if !s:context.is_force && s:context.method ==# method
        " The cached candidates are reusable because they were extracted by
        " the same method as s:context.method.
        return candidates
      endif
    endif

    " Path B: Candidates haven't been cached, so try to get headings.
    let headings = s:gather_headings()
    " Convert headings into candidates and cache them.
    let candidates = s:convert_headings_to_candidates(headings)
    call setbufvar(buffer.nr, s:OUTLINE_CACHE_VAR, candidates)

    return candidates
  catch /^NoWindowError:/
    call unite#print_message("[unite-outline] The context buffer has no window.")
    return []
  catch
    call unite#util#print_error(v:throwpoint)
    call unite#util#print_error(v:exception)
    return []
  finally
    " Restore Vim options.
    let &cpoptions  = save_cpoptions
    let &ignorecase = save_ignorecase
    let &magic = save_magic
  endtry
endfunction
let s:source.gather_candidates = function(s:SID . 'Source_gather_candidates')

function! s:parse_options(args, context)
  let opts = {
        \ 'method'  : 'last',
        \ 'is_force': 0,
        \ }
  for value in a:args
    if value =~# '^\%(ft\|fi\%[letype]\)$'
      let opts.method = 'filetype'
    elseif value =~# '^fo\%[lding]$'
      let opts.method = 'folding'
    elseif value =~# '^\%(update\|!\)$'
      let opts.is_force = 1
    endif
  endfor
  if a:context.is_redraw
    let opts.is_force = 1
  endif
  return opts
endfunction

function! s:gather_headings()
  let buffer = s:context.buffer
  let cache_reusable = 0
  if s:Cache.has(buffer)
    " Path B_1: Get headings from the persistent cache.
    try
      let headings = s:Cache.get(buffer)
      let method = (!empty(headings) &&
            \ headings[0].type ==# 'folding' ? 'folding' : 'filetype')
      if s:context.method ==# 'last'
        let s:context.method = method
      endif
      if !s:context.is_force && s:context.method ==# method
        " The cached headings are reusable because they were extracted by the
        " same method as s:context.method.
        let cache_reusable = 1
        call s:ids_to_refs(headings)
      endif
    catch /^CacheCompatibilityError:/
      " Fallback siliently.
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif
  if !cache_reusable
    " Path B_2: Get headings by parsing the buffer.
    let winnr = bufwinnr(s:context.buffer.nr)
    if winnr == -1
      throw "NoWindowError:"
    endif

    call s:Util.print_progress("Extracting headings...")

    " Save and set Vim options.
    let save_eventignore = &eventignore
    let save_winheight   = &winheight
    let save_winwidth    = &winwidth
    let save_lazyredraw  = &lazyredraw
    set eventignore=all
    set winheight=1
    set winwidth=1
    " NOTE: To keep the window size on :wincmd, set 'winheight' and 'winwidth'
    " to a small value.
    set lazyredraw

    " Switch: current window -> context window
    execute winnr . 'wincmd w'

    " Save the cursor and scroll.
    let save_cursor  = getpos('.')
    let save_topline = line('w0')

    let lines = [""] + getbufline(s:context.buffer.nr, 1, '$')
    let s:context.lines = lines | " available while the extraction
    let s:context.heading_lnum = 0
    let s:context.matched_lnum = 0

    let success = 0
    let start_time = s:benchmark_start()
    try
      if s:context.method !=# 'folding'
        " Path B_2_a: Extract headings in filetype-specific way using the
        " filetype's outline info.
        let s:context.method = 'filetype'
        let headings = s:extract_filetype_headings()
      else
        " Path B_2_b: Extract headings using folds' information.
        let s:context.method = 'folding'
        let headings = s:extract_folding_headings()
      endif

      " Cache the headings.
      let num_lines = len(s:context.lines) - 1 | " -1 for a dummy
      let is_volatile = get(s:context.outline_info, 'is_volatile', 0)
      if !is_volatile && num_lines > 100 && !empty(headings)
        let is_persistant = (num_lines > g:unite_source_outline_cache_limit)
        call s:Cache.set(buffer, s:refs_to_ids(headings), is_persistant)
      elseif s:Cache.has(buffer)
        call s:Cache.remove(buffer)
      endif
      let success = 1
    finally
      " Restore the cursor and scroll.
      let save_scrolloff = &scrolloff
      set scrolloff=0
      call cursor(save_topline, 1)
      normal! zt
      call setpos('.', save_cursor)
      let &scrolloff = save_scrolloff

      " Siwtch: current window <- context window
      wincmd p

      " Restore Vim options.
      let &lazyredraw = save_lazyredraw
      if success
        call s:Util.print_progress("Extracting headings...done.")
        call s:benchmark_stop(start_time) | " use s:context.lines
      endif
      let &winheight   = save_winheight
      let &winwidth    = save_winwidth
      let &eventignore = save_eventignore

      unlet s:context.lines
      unlet s:context.heading_lnum
      unlet s:context.matched_lnum
    endtry
  endif
  return headings
endfunction

function! s:benchmark_start()
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    return s:get_reltime()
  else
    return 0
  endif
endfunction

function! s:benchmark_stop(start_time)
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    let num_lines = len(s:context.lines) - 1 | " -1 for a dummy
    let used_time = s:get_reltime() - a:start_time
    let used_time_100l = used_time * (str2float("100") / num_lines)
    call s:Util.print_progress("unite-outline: used=" . string(used_time) .
          \ "s, 100l=". string(used_time_100l) . "s")
  endif
endfunction

function! s:get_reltime()
  return str2float(reltimestr(reltime()))
endfunction

" NOTE: Built-in string() function can't dump an object that has any cyclic
" references because of E724, nested too deep error; therefore, we need to
" substitute references to each heading's parent and children with their id
" numbers before their serialization.
"
function! s:refs_to_ids(headings)
  let headings = copy(a:headings)
  let headings = map(headings, 'copy(v:val)')
  for heading in headings
    let heading.parent = heading.parent.id
    let heading.children = map(copy(heading.children), 'v:val.id')
  endfor
  return headings
endfunction

function! s:ids_to_refs(headings)
  try
    let root = s:Tree.new()
    let heading_table = {}
    for heading in a:headings
      let heading_table[heading.id] = heading
    endfor
    for heading in a:headings
      if heading.parent == 0
        call s:Tree.append_child(root, heading)
      else
        let heading.parent = heading_table[heading.parent]
      endif
      call map(heading.children, 'heading_table[v:val]')
    endfor
  catch
    call s:Util.print_debug(v:throwpoint)
    call s:Util.print_debug(v:exception)
    throw "CacheCompatibilityError:"
  endtry
  return a:headings
endfunction

function! s:extract_filetype_headings()
  let buffer = s:context.buffer
  if s:context.is_force
    " Re-source the outline info if updated.
    let s:context.outline_info =
          \ unite#sources#outline#get_outline_info(buffer.filetype)
  endif
  let outline_info = s:context.outline_info
  if empty(outline_info)
    if empty(buffer.filetype)
      call unite#print_message("[unite-outline] Please set the filetype.")
    else
      call unite#print_message("[unite-outline] Sorry, " .
            \ toupper(buffer.filetype) . " is not supported.")
    endif
    return []
  endif

  " Extract headings.
  if has_key(outline_info, 'initialize')
    call outline_info.initialize(s:context)
  endif
  if has_key(outline_info, 'extract_headings')
    let headings = outline_info.extract_headings(s:context)
    let is_normalized = 0
  else
    let headings = s:builtin_extract_headings()
    let is_normalized = 1
  endif
  if has_key(outline_info, 'finalize')
    call outline_info.finalize(s:context)
  endif

  " Normalize.
  if type(headings) == type({})
    let tree = headings | unlet headings
    let headings = s:Tree.flatten(tree)
  else
    let tree = s:Tree.build(headings)
    let headings = s:Tree.flatten(tree) | " smooth levels
  endif
  if !is_normalized
    call map(headings, 's:normalize_heading(v:val)')
  endif

  " Filter headings.
  let ignore_types = unite#sources#
        \outline#get_ignore_heading_types(buffer.filetype)
  let headings = s:filter_headings(headings, ignore_types)

  return headings
endfunction

function! s:builtin_extract_headings()
  let outline_info = s:context.outline_info
  let [which, pattern] = s:build_heading_pattern()

  let has_create_heading = has_key(outline_info, 'create_heading')
  let num_lines = line('$')

  let skip_ranges = s:get_skip_ranges()
  call add(skip_ranges, [num_lines + 1, num_lines + 2]) | " sentinel
  let srp = 0 | " skip range pointer

  let headings = []
  call cursor(1, 1)
  while 1
    let found = 0
    let [lnum, col, submatch] = searchpos(pattern, 'cpW')
    if lnum == 0
      break
    endif
    while lnum > skip_ranges[srp][1]
      let srp += 1
    endwhile
    if lnum < skip_ranges[srp][0]
      if which[submatch] ==# 'heading-1' && lnum < num_lines - 3
        " Matched: heading-1
        let next_line = getline(lnum + 1)
        if next_line =~ '[[:punct:]]\@!\S'
          let s:context.heading_lnum = lnum + 1
          let s:context.matched_lnum = lnum
          let found = 1
        elseif next_line =~ '\S' && lnum < num_lines - 4
          " See one more next.
          let next_line = getline(lnum + 2)
          if next_line =~ '[[:punct:]]\@!\S'
            let s:context.heading_lnum = lnum + 2
            let s:context.matched_lnum = lnum
            let found = 1
          endif
        endif
      elseif which[submatch] ==# 'heading'
        " Matched: heading
        let s:context.heading_lnum = lnum
        let s:context.matched_lnum = lnum
        let found = 1
      elseif which[submatch] ==# 'heading+1' && lnum > 0
        " Matched: heading+1
        let s:context.heading_lnum = lnum - 1
        let s:context.matched_lnum = lnum
        let prev_line = getline(lnum - 1)
        let found = (prev_line =~ '[[:punct:]]\@!\S')
      endif
      if found
        let heading_line = getline(s:context.heading_lnum)
        let matched_line = getline(s:context.matched_lnum)
        if has_create_heading
          let heading = outline_info.create_heading(
                \ which[submatch], heading_line, matched_line, s:context)
        else
          let heading = heading_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading))
        endif
        if len(headings) >= g:unite_source_outline_max_headings
          call unite#print_message(
                \ "[unite-outline] Too many headings, the extraction was interrupted.")
          break
        endif
      endif
    endif
    if lnum == num_lines
      break
    endif
    call cursor(lnum + 1, 1)
  endwhile
  return headings
endfunction

function! s:build_heading_pattern()
  let outline_info = s:context.outline_info
  let which = ['dummy', 'dummy']
  " NOTE: searchpos() returns submatch counted from 2.
  let sub_patterns = []
  if has_key(outline_info, 'heading-1')
    call add(which, 'heading-1')
    call add(sub_patterns, outline_info['heading-1'])
  endif
  if has_key(outline_info, 'heading')
    call add(which, 'heading')
    call add(sub_patterns, outline_info.heading)
  endif
  if has_key(outline_info, 'heading+1')
    call add(which, 'heading+1')
    call add(sub_patterns, outline_info['heading+1'])
  endif
  call map(sub_patterns, 's:_substitue_sub_pattern(v:val)')
  let pattern = '\%(' . join(sub_patterns, '\|') . '\)'
  return [which, pattern]
endfunction
function! s:_substitue_sub_pattern(pattern)
  " Substitute all '\(' with '\%('
  return '\(' . substitute(a:pattern, '\(\(^\|[^\\]\)\(\\\{2}\)*\)\@<=\\(', '\\%(', 'g') . '\)'
endfunction

function! s:get_skip_ranges()
  let outline_info = s:context.outline_info
  if !has_key(outline_info, 'skip') | return [] | endif
  let ranges = []
  if has_key(outline_info.skip, 'header')
    let header_range = s:get_header_range()
    if !empty(header_range)
      call add(ranges, header_range)
    endif
  endif
  if has_key(outline_info.skip, 'block')
    let block = outline_info.skip.block
    let num_lines = line('$')
    call cursor(1, 1)
    while 1
      let beg_lnum= search(block.begin, 'cW')
      if beg_lnum == 0 || beg_lnum == num_lines
        break
      else
        call cursor(beg_lnum + 1, 1)
      endif
      let end_lnum= search(block.end, 'cW')
      if end_lnum == 0
        break
      endif
      call add(ranges, [beg_lnum, end_lnum])
      if end_lnum == num_lines
        break
      else
        call cursor(end_lnum + 1, 1)
      endif
    endwhile
  endif
  return ranges
endfunction

function! s:get_header_range()
  let outline_info = s:context.outline_info
  let header = outline_info.skip.header
  let has_leading = has_key(header, 'leading')
  let has_block   = has_key(header, 'block')

  let lnum = 1 | let num_lines = line('$')
  while lnum < num_lines
    let line = getline(lnum)
    if has_leading && line =~# header.leading
      let lnum = s:skip_while(header.leading, lnum)
    elseif has_block && line =~# header.block.begin
      let lnum = s:skip_until(header.block.end, lnum)
    else
      break
    endif
  endwhile
  let lnum -= 1
  if lnum > 1
    return [1, lnum]
  else
    return []
  endif
endfunction

function! s:skip_while(pattern, from)
  let lnum = a:from + 1 | let num_lines = line('$')
  while lnum <= num_lines
    let line = getline(lnum)
    if line !~# a:pattern
      break
    endif
    let lnum += 1
  endwhile
  return lnum
endfunction

function! s:skip_until(pattern, from)
  let lnum = a:from + 1 | let num_lines = line('$')
  while lnum <= num_lines
    let line = getline(lnum)
    let lnum += 1
    if line =~# a:pattern
      break
    endif
  endwhile
  return lnum
endfunction

function! s:extract_folding_headings()
  let headings = []
  let curr_level = 0
  let lnum = 1 | let num_lines = line('$')
  while lnum < num_lines
    let foldlevel = foldlevel(lnum)
    if foldlevel > curr_level
      let heading_lnum = lnum
      if &l:foldmethod ==# 'indent'
        let heading_lnum -=1
      endif
      let heading = {
            \ 'word' : getline(heading_lnum),
            \ 'level': foldlevel,
            \ 'type' : 'folding',
            \ 'lnum' : heading_lnum,
            \ }
      call add(headings, heading)
      if len(headings) >= g:unite_source_outline_max_headings
        call unite#print_message(
              \ "[unite-outline] Too many headings, the extraction was interrupted.")
        break
      endif
    endif
    let curr_level = foldlevel
    let lnum += 1
  endwhile
  call map(headings, 's:normalize_heading(v:val)')
  call s:Tree.build(headings)
  return headings
endfunction

function! s:normalize_heading(heading)
  if type(a:heading) == type("")
    " Normalize to a Dictionary.
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
  let heading.pattern = '^' . unite#util#escape_pattern(heading.line) . '$'
  let heading.signature = s:calc_signature(heading.lnum, s:context.lines)
  let outline_info = s:context.outline_info
  if s:context.method !=# 'folding' && !has_key(heading, 'group')
    let group_map = outline_info.heading_group_map
    let heading.group = get(group_map, heading.type, 'generic')
  endif
  if has_key(outline_info, '__not_match_pattern__')
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

" Quick and Dirty Digest
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
function! s:filter_headings(headings, ignore_types)
  if empty(a:ignore_types) | return a:headings | endif
  let headings = a:headings

  " Remove comment headings.
  if index(a:ignore_types, 'comment') >= 0
    call filter(headings, 'v:val.type !=# "comment"')
    let headings = s:Tree.flatten(s:Tree.build(headings))
  endif

  let ignore_types = map(copy(a:ignore_types), 'unite#util#escape_pattern(v:val)')
  let ignore_types_pattern = '^\%(' . join(ignore_types, '\|') . '\)$'
  " Use something like closure.
  let predicate = {}
  let predicate.ignore_types_pattern = ignore_types_pattern
  function predicate.call(heading)
    return (a:heading.type =~# self.ignore_types_pattern)
  endfunction
  " Remove headings to be ignored.
  let tree = s:Tree.get_root(headings[0])
  call s:Tree.remove(tree, predicate)
  let headings = s:Tree.flatten(tree)
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
  let candidates = map(copy(a:headings), 's:create_candidate(v:val)')
  return candidates
endfunction

function! s:create_candidate(heading)
  " NOTE:
  "   abbr - String for displaying
  "   word - String for narrowing
  let indent = repeat(' ', (a:heading.level - 1) * g:unite_source_outline_indent_width)
  let cand = {
        \ 'abbr': indent . a:heading.word,
        \ 'word': a:heading.keyword,
        \ 'source': 'outline',
        \ 'kind'  : 'jump_list',
        \ 'action__path': s:context.buffer.path,
        \ 'action__pattern'  : a:heading.pattern,
        \ 'action__signature': a:heading.signature,
        \
        \ 'source__heading'  : a:heading,
        \ }
  let a:heading.__unite_candidate__ = cand
  return cand
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
  " Scroll the cursor line down.
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
