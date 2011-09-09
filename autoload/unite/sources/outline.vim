"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-09-10
" Version : 0.5.0
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

let s:OUTLINE_ALIASES = {
      \ 'c'       : 'cpp',
      \ 'cfg'     : 'dosini',
      \ 'mkd'     : 'markdown',
      \ 'plaintex': 'tex',
      \ 'snippet' : 'conf',
      \ 'xhtml'   : 'html',
      \ 'zsh'     : 'sh',
      \ }

let s:OUTLINE_CACHE_DIR = g:unite_data_directory . '/outline'

" Rename the cache directory if its name is still old, dotted style name.
" See http://d.hatena.ne.jp/tyru/20110824/unite_file_mru
let old_cache_dir = g:unite_data_directory . '/.outline'
if isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir) 
    call unite#print_message("[unite-outline] " .
          \ "Warning: Please remove the old cache directory: ")
    call unite#print_message("[unite-outline] " . old_cache_dir)
  endif
else " if !isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir)
    if rename(old_cache_dir, s:OUTLINE_CACHE_DIR) != 0
      let s:OUTLINE_CACHE_DIR = old_cache_dir
      call unite#util#print_error(
            \ "unite-outline: Couldn't rename the cache directory.")
    endif
  endif
endif
unlet old_cache_dir

let s:OUTLINE_FILECACHE_FORMAT_VERSION = 1

let s:BUFVAR_OUTLINE_DATA = 'unite_source_outline_data'
let s:WINVAR_OUTLINE_BUFFER_IDS = 'unite_source_outline_buffer_ids'

"-----------------------------------------------------------------------------
" Functions

function! unite#sources#outline#define()
  return s:source
endfunction

" Defines an alias of {filetype}.
"
function! unite#sources#outline#alias(alias, filetype)
  if !exists('s:filetype_alias_table')
    let s:filetype_alias_table = {}
  endif
  let s:filetype_alias_table[a:alias] = a:filetype
endfunction

" Accessor functions for the outline data, that is a Dictionary assigned to
" the script local variable.
"
function! unite#sources#outline#has_outline_data(...)
  return call('s:has_outline_data', a:000)
endfunction
function! s:has_outline_data(bufnr, ...)
  if a:0
    let key = a:1
    let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
    return has_key(data, key)
  else
    let bufvars = getbufvar(a:bufnr, '')
    return has_key(bufvars, s:BUFVAR_OUTLINE_DATA)
  endif
endfunction

" Returns the value of outline data {key} for buffer {bufnr}.
" If the value isn't available, returns {default}.
"
function! unite#sources#outline#get_outline_data(...)
  return call('s:get_outline_data', a:000)
endfunction
function! s:get_outline_data(bufnr, key, ...)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  return (a:0 ? get(data, a:key, a:1) : data[a:key])
endfunction

" Sets the value of outline data {key} for buffer {bufnr} to {value}.
"
function! unite#sources#outline#set_outline_data(...)
  call call('s:set_outline_data', a:000)
endfunction
function! s:set_outline_data(bufnr, key, value)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  let data[a:key] = a:value
endfunction

" Removes the value of outline data {key} for buffer {bufnr}.
"
function! unite#sources#outline#remove_outline_data(...)
  call call('s:remove_outline_data', a:000)
endfunction
function! s:remove_outline_data(bufnr, key)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  unlet data[a:key]
endfunction

function! s:has_outline_buffer_ids(winnr)
  let winvars  = getwinvar(a:winnr, '')
  return has_key(winvars, s:WINVAR_OUTLINE_BUFFER_IDS)
endfunction

function! s:get_outline_buffer_ids(winnr)
  let winvars  = getwinvar(a:winnr, '')
  return winvars[s:WINVAR_OUTLINE_BUFFER_IDS]
endfunction

" Returns the outline info for {filetype}. If not found, returns an empty
" Dictionary.
"
function! unite#sources#outline#get_outline_info(filetype)
  return s:get_outline_info(a:filetype, 0)
endfunction

" Returns the default outline info for {filetype}. If not found, returns an
" empty Dictionary.
"
function! unite#sources#outline#get_default_outline_info(filetype)
  return s:get_outline_info(a:filetype, 1)
endfunction

function! s:get_outline_info(filetype, ...)
  let is_default = (a:0 ? a:1 : 0)
  for filetype in s:resolve_filetype(a:filetype)
    let outline_info = s:load_outline_info(filetype, is_default)
    if !empty(outline_info) | return outline_info | endif
  endfor
  return {}
endfunction

" Try to load the outline info for {filetype}. If couldn't load, returns an
" empty Directory.
"
function! s:load_outline_info(filetype, is_default)
  if has_key(g:unite_source_outline_info, a:filetype)
    return g:unite_source_outline_info[a:filetype]
  endif
  let oinfo_dirs = (a:is_default ? s:OUTLINE_INFO_PATH[-1:] : s:OUTLINE_INFO_PATH)
  for dir in oinfo_dirs
    let load_func  = substitute(substitute(dir, '^autoload/', '', ''), '/', '#', 'g')
    let load_func .= substitute(a:filetype, '\.', '_', 'g') . '#outline_info'
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
    call s:update_script(scr_path)
    " Load the outline info.
    let outline_info = {load_func}()
    let outline_info = s:initialize_outline_info(outline_info)
    return outline_info
  endfor
  return {}
endfunction

" Returns a full pathname of the script file where function {funcname} is
" defined.
"
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

" Re-sources script file {path} if the script has been modified since the last
" sourcing.
"
function! s:update_script(path)
  if !exists('s:file_mtime_table')
    let s:file_mtime_table = {}
  endif
  let path = fnamemodify(a:path, ':p')
  let new_ftime = getftime(path)
  let old_ftime = get(s:file_mtime_table, path, new_ftime)
  if new_ftime > old_ftime
    source `=path`
  endif
  let s:file_mtime_table[path] = new_ftime
  return (new_ftime > old_ftime)
endfunction

function! s:initialize_outline_info(outline_info)
  if has_key(a:outline_info, '__initialized__')
    return a:outline_info
  endif
  call extend(a:outline_info, { 'is_volatile': 0 }, 'keep' )
  if has_key(a:outline_info, 'skip')
    call s:normalize_skip_info(a:outline_info)
  endif
  call s:normalize_heading_groups(a:outline_info)
  if has_key(a:outline_info, 'not_match_patterns')
    let a:outline_info.__not_match_pattern__ =
          \ '\%(' . join(a:outline_info.not_match_patterns, '\|') . '\)'
  endif
  let a:outline_info.__initialized__ = 1
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

" Returns the value of filetype option {key} for {filetype}.
" If the value isn't available, returns {default}.
"
function! unite#sources#outline#get_filetype_option(...)
  return call('s:get_filetype_option', a:000)
endfunction
function! s:get_filetype_option(filetype, key, ...)
  for filetype in s:resolve_filetype(a:filetype)
    if has_key(g:unite_source_outline_filetype_options, filetype)
      let options = g:unite_source_outline_filetype_options[filetype]
      if has_key(options, a:key)
        return options[a:key]
      endif
    endif
  endfor
  let default = (a:0 ? a:1 : 0)
  return get(s:default_filetype_options, a:key, default)
endfunction

" Returns a List of filetypes that are {filetype} itself and its fallback
" filetypes.
"
"  {filetype}
"    |/
"   aaa.bbb.ccc -(alias)-> ddd -(alias)-> eee
"    |/
"   aaa.bbb     -(alias)-> fff -(alias)-> ggg
"    |/
"   aaa
"
"   => [aaa.bbb.ccc, ddd, eee, aaa.bbb, fff, ggg, aaa]
"
function! s:resolve_filetype(filetype)
  let candidates = []
  let filetype = a:filetype
  while 1
    call add(candidates, filetype)
    let candidates += s:resolve_filetype_alias(filetype)
    if filetype =~ '\.\w\+$'
      let filetype = substitute(filetype, '\.\w\+$', '', '')
    else
      break
    endif
  endwhile
  call add(candidates, '*')
  return candidates
endfunction

function! s:resolve_filetype_alias(filetype)
  let seen = {}
  let candidates = []
  let filetype = a:filetype
  while 1
    if has_key(s:filetype_alias_table, filetype)
      if has_key(seen, filetype)
        throw "unite-outline: Cyclic alias definition detected."
      endif
      let filetype = s:filetype_alias_table[filetype]
      call add(candidates, filetype)
      let seen[filetype] = 1
    else
      break
    endif
  endwhile
  return candidates
endfunction

function! unite#sources#outline#get_highlight(...)
  return call('s:get_highlight', a:000)
endfunction
function! s:get_highlight(name)
  return (has_key(g:unite_source_outline_highlight, a:name)
        \ ? g:unite_source_outline_highlight[a:name]
        \ : s:default_highlight[a:name])
endfunction

function! unite#sources#outline#import(name, ...)
  let name = tolower(substitute(a:name, '\(\l\)\(\u\)', '\1_\2', 'g'))
  return call('unite#sources#outline#modules#' . name . '#import', a:000)
endfunction

function! unite#sources#outline#remove_cache_files()
  call s:FileCache.clear()
endfunction

"-----------------------------------------------------------------------------
" Key-mappings

" DEPRECATED:
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

if !exists('g:unite_source_outline_max_headings')
  let g:unite_source_outline_max_headings = 1000
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 1000
endif

let s:default_filetype_options = {
      \ 'auto_update'      : 1,
      \ 'auto_update_event': 'write',
      \ 'ignore_types'     : [],
      \ }
if !exists('g:unite_source_outline_filetype_options')
  let g:unite_source_outline_filetype_options = {}
endif

let s:default_highlight = {
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
      \ }
if !exists('g:unite_source_outline_highlight')
  let g:unite_source_outline_highlight = {}
endif

if !exists('g:unite_source_outline_verbose')
  let g:unite_source_outline_verbose = 0
endif

"---------------------------------------
" Aliases

function! s:define_filetype_aliases()
  " NOTE: If the user has his/her own outline info for a filetype, not define
  " it as an alias of the other filetype by default.
  let user_oinfos = {}
  for path in s:OUTLINE_INFO_PATH[:-2]
    let oinfo_paths = split(globpath(&rtp, path . '*.vim'), "\<NL>")
    for filetype in map(oinfo_paths, 'matchstr(v:val, "\\w\\+\\ze\\.vim$")')
      let filetype = substitute(filetype, '_', '.', 'g')
      let user_oinfos[filetype] = 1
    endfor
  endfor
  for [alias, filetype] in items(s:OUTLINE_ALIASES)
    if !has_key(user_oinfos, alias)
      call unite#sources#outline#alias(alias, filetype)
    endif
  endfor
endfunction
" Define the default filetype aliases.
call s:define_filetype_aliases()

"-----------------------------------------------------------------------------
" Source

let s:FileCache = unite#sources#outline#import('FileCache', s:OUTLINE_CACHE_DIR)
let s:Tree = unite#sources#outline#import('Tree')
let s:Util = unite#sources#outline#import('Util')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:outline_buffer_id = 1
let s:source = {
      \ 'name'       : 'outline',
      \ 'description': 'candidates from heading list',
      \ 'filters'    : ['outline_matcher_glob', 'outline_formatter'],
      \ 'syntax'     : 'uniteSource__Outline',
      \
      \ 'hooks': {}, 'action_table': {}, 'alias_table': {}, 'default_action': {},
      \ }

function! s:Source_Hooks_on_init(source_args, unite_context)
  let a:unite_context.source__outline_buffer_id = s:outline_buffer_id
  let a:unite_context.source__outline_source_bufnr = bufnr('%')
  call s:unite_outline_initialize()
  call s:unite_outline_attach(s:outline_buffer_id)
  let s:outline_buffer_id += 1
endfunction
let s:source.hooks.on_init = function(s:SID . 'Source_Hooks_on_init')

" Initialize the outline data and register autocmds if the current buffer
" hasn't initialized yet.
"
function! s:unite_outline_initialize()
  let bufnr = bufnr('%')
  let bufvars  = getbufvar(bufnr, '')
  if !exists('s:outline_data')
    let s:outline_data = {}
  endif
  if !has_key(bufvars, s:BUFVAR_OUTLINE_DATA)
    let bufvars[s:BUFVAR_OUTLINE_DATA] = {}
    call s:register_autocmds()
  endif
  call s:update_buffer_changenr()
endfunction

" Associate the current buffer's window with the outline buffer {buffer_id}
" where the headings from the buffer will be displayed.
"
function! s:unite_outline_attach(buffer_id)
  let winnr = winnr()
  let winvars  = getwinvar(winnr, '')
  if !has_key(winvars, s:WINVAR_OUTLINE_BUFFER_IDS)
    let winvars[s:WINVAR_OUTLINE_BUFFER_IDS] = []
  endif
  call add(winvars[s:WINVAR_OUTLINE_BUFFER_IDS], a:buffer_id)
endfunction

function! s:Source_Hooks_on_syntax(source_args, unite_context)
  let bufnr = a:unite_context.source__outline_source_bufnr
  let context = s:get_outline_data(bufnr, 'context')
  let outline_info = context.outline_info
  if context.extract_method ==# 'filetype'
    " Method: Filetype
    if has_key(outline_info, 'highlight_rules')
      for hl_rule in outline_info.highlight_rules
        if !has_key(hl_rule, 'highlight')
          let hl_rule.highlight = s:get_highlight(hl_rule.name)
        endif
        execute 'syntax match uniteSource__Outline_' . hl_rule.name hl_rule.pattern
              \ 'contained containedin=uniteSource__Outline'
        execute 'highlight default link uniteSource__Outline_' . hl_rule.name hl_rule.highlight
      endfor
    endif
  else
    " Method: Folding
    " Now folding headings are not highlighted at all.
  endif
endfunction
let s:source.hooks.on_syntax = function(s:SID . 'Source_Hooks_on_syntax')

function! s:Source_gather_candidates(source_args, unite_context)
  " Save the Vim options.
  let save_cpoptions  = &cpoptions
  let save_ignorecase = &ignorecase
  let save_magic = &magic
  try
    set cpoptions&vim
    set noignorecase
    set magic

    let options = s:parse_source_arguments(a:source_args, a:unite_context)
    let bufnr = a:unite_context.source__outline_source_bufnr

    let auto_update = s:get_filetype_option(getbufvar(bufnr, '&filetype'), 'auto_update', 0)
    if auto_update
      let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
      let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
      if model_changenr != buffer_changenr
        " The source buffer has been changed since the last extraction.
        " Need to update all.
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr . ', unite = ? ')
        let options.is_force = 1
        let options.is_sync  = 0
      else
        let  unite_changenr = s:get_outline_data(bufnr, '__unite_changenr__', 0)
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr . ', unite = ' . unite_changenr . ' ')
        if model_changenr != unite_changenr
          " Model data (headings) has been updated since the last gathering of
          " candidates.
          " Need to synchronize candidates to the headings.
          let options.is_sync = 1
        endif
      endif
    endif

    if s:has_outline_data(bufnr, '__unite_candidates__')
      " Path A: Get candidates from the buffer local cache and return them.
      let candidates = s:get_outline_data(bufnr, '__unite_candidates__')
      if s:is_valid_candidates(candidates, options)
        return candidates
      endif
    endif

    " Path B: Candidates are invalid or haven't been cached, so try to get
    " headings.
    let headings = s:get_Headings(bufnr, options)

    " Convert the headings into candidates.
    let candidates = s:convert_headings_to_candidates(headings, a:unite_context)
    " Save the candidates to the on-memory cache.
    call s:set_outline_data(bufnr, '__unite_candidates__', candidates)

    if auto_update
      " Synchronize the change counts.
      if options.is_sync
        call s:set_outline_data(bufnr, '__unite_changenr__',  model_changenr)
      else
        call s:set_outline_data(bufnr, '__unite_changenr__', buffer_changenr)
      endif
      if get(g:, 'unite_source_outline_event_debug', 0)
        let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
        let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
        let  unite_changenr = s:get_outline_data(bufnr, '__unite_changenr__', 0)
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr . ', unite = ' . unite_changenr . ' [SYNC]')
      endif
    endif

    return candidates

  catch /^NoWindowError:/
    call unite#print_message("[unite-outline] The source buffer has no window.")
    return []

  catch
    call unite#util#print_error(v:throwpoint)
    call unite#util#print_error(v:exception)
    return []

  finally
    " Restore the Vim options.
    let &cpoptions  = save_cpoptions
    let &ignorecase = save_ignorecase
    let &magic = save_magic
  endtry
endfunction
let s:source.gather_candidates = function(s:SID . 'Source_gather_candidates')

function! s:parse_source_arguments(source_args, unite_context)
  let options = {
        \ 'is_force': 0,
        \ 'is_sync' : 0,
        \ 'extract_method': 'last',
        \ }
  for value in a:source_args
    if value =~# '^\%(ft\|fi\%[letype]\)$'
      let options.extract_method = 'filetype'
    elseif value =~# '^fo\%[lding]$'
      let options.extract_method = 'folding'
    elseif value =~# '^\%(update\|!\)$'
      let options.is_force = 1
    endif
  endfor
  if a:unite_context.is_redraw
    let options.is_force = 1
  endif
  if has_key(a:unite_context, 'source__outline_is_swap')
    unlet a:unite_context.source__outline_is_swap
    let options.is_force = 0
  endif
  return options
endfunction

" Creates a context Dictionary.
"
function! s:create_context(bufnr, ...)
  let buffer = {
        \ 'nr'  : a:bufnr,
        \ 'path': fnamemodify(bufname(a:bufnr), ':p'),
        \ 'filetype'  : getbufvar(a:bufnr, '&filetype'),
        \ 'shiftwidth': getbufvar(a:bufnr, '&shiftwidth'),
        \ 'tabstop'   : getbufvar(a:bufnr, '&tabstop'),
        \ }
  let compound_filetypes = split(buffer.filetype, '\.')
  call extend(buffer, {
        \ 'major_filetype': get(compound_filetypes, 0, ''),
        \ 'minor_filetype': get(compound_filetypes, 1, ''),
        \ 'compound_filetypes': compound_filetypes,
        \ })
  let outline_info = s:get_outline_info(buffer.filetype)
  let context = {
        \ 'buffer': buffer,
        \ 'event' : 'user',
        \ 'is_force': 0,
        \ 'is_sync' : 0,
        \ 'extract_method': 'last',
        \ 'outline_info': outline_info,
        \ }
  call extend(context, (a:0 ? a:1 : {}))
  return context
endfunction

function! s:is_valid_candidates(candidates, options)
  let last_method = (!empty(a:candidates) &&
        \ a:candidates[0].source__heading.type ==# 'folding' ? 'folding' : 'filetype')
  if a:options.extract_method ==# 'last'
    let a:options.extract_method = last_method
  endif
  if a:options.is_sync
    return 0
  else
    return (!a:options.is_force && a:options.extract_method ==# last_method)
  endif
endfunction

function! s:is_valid_Headings(headings, context)
  let l_headings = a:headings.as_list
  let is_folding = (!empty(l_headings) && l_headings[0].type ==# 'folding')
  let last_method = (is_folding ? 'folding' : 'filetype')
  if a:context.extract_method ==# 'last'
    let a:context.extract_method = last_method
  endif
  if a:context.is_sync
    return 1
  else
    return (!a:context.is_force && a:context.extract_method ==# last_method)
  endif
endfunction

function! s:is_valid_filecache(data)
  let format_version = '__unite_outline_filecache_format_version__'
  return (type(a:data) == type({})
        \ && has_key(a:data, format_version)
        \ && a:data[format_version] == s:OUTLINE_FILECACHE_FORMAT_VERSION)
endfunction

function! s:get_Headings(bufnr, options)
  let context = s:create_context(a:bufnr, a:options)
  call s:set_outline_data(a:bufnr, 'context', context)

  if s:has_outline_data(a:bufnr, 'headings')
    " Path B_1: Get headings from the on-memory cache.
    let headings = s:get_outline_data(a:bufnr, 'headings')
    if s:is_valid_Headings(headings, context)
      return headings
    endif
  endif

  if !context.is_force && s:FileCache.has(a:bufnr)
    " Path B_2: Get headings from the persistent cache.
    try
      let t_headings = s:FileCache.get(a:bufnr)
      if s:is_valid_filecache(t_headings)
        let headings = s:Headings_new(t_headings)
        if s:is_valid_Headings(headings, context)
          " Save the headings to the on-memory cache.
          call s:set_outline_data(a:bufnr, 'headings', headings)
          return headings
        endif
      endif
    catch /^unite-outline:/
      " Fallback to Path_B_3.
      call unite#util#print_error(v:exception)
    endtry
  endif

  " Path B_3: Get headings by parsing the buffer.
  let headings = s:extract_Headings(context)

  let is_volatile = get(context.outline_info, 'is_volatile', 0)
  if !is_volatile
    " Save the headings to the cache.
    call s:set_outline_data(a:bufnr, 'headings', headings)
    let is_persistant = (context.__num_lines__ > g:unite_source_outline_cache_limit)
    if is_persistant
      let format_version = '__unite_outline_filecache_format_version__'
      let headings.as_tree[format_version] = s:OUTLINE_FILECACHE_FORMAT_VERSION
      call s:FileCache.set(a:bufnr, headings.as_tree)
    elseif s:FileCache.has(a:bufnr)
      " Remove the invalid file cache.
      call s:FileCache.remove(a:bufnr)
    endif
  endif
  return headings
endfunction

function! s:extract_Headings(context)
  let winnr = bufwinnr(a:context.buffer.nr)
  if winnr == -1
    throw "NoWindowError:"
  endif

  " Print a progress message.
  if a:context.event ==# 'auto_update'
    if g:unite_source_outline_verbose
      call s:Util.print_progress("Update headings...")
    endif
  else
    call s:Util.print_progress("Extract headings...")
  endif

  " Save the Vim options.
  let save_eventignore = &eventignore
  let save_winheight   = &winheight
  let save_winwidth    = &winwidth
  let save_lazyredraw  = &lazyredraw
  try
    set eventignore=all
    set winheight=1
    set winwidth=1
    " NOTE: To keep the window size on :wincmd, set 'winheight' and 'winwidth'
    " to a small value.
    set lazyredraw

    " Switch: current window -> source buffer's window
    execute winnr . 'wincmd w'
    " Save the cursor and scroll.
    let save_cursor  = getpos('.')
    let save_topline = line('w0')

    let lines = [""] + getbufline('%', 1, '$')
    let a:context.__num_lines__ = len(lines)
    " Merge the temporary context data to the context.
    let a:context.lines = lines
    let a:context.heading_lnum = 0
    let a:context.matched_lnum = 0

    let success = 0
    let start_time = s:benchmark_start()

    " Extract headings.
    let s:heading_id = 1
    if a:context.extract_method !=# 'folding'
      " Path B_3_a: Extract headings in filetype-specific way using the
      " filetype's outline info.
      let a:context.extract_method = 'filetype'
      let headings = s:extract_filetype_Headings(a:context)
    else
      " Path B_3_b: Extract headings using folds' information.
      let a:context.extract_method = 'folding'
      let headings = s:extract_folding_Headings(a:context)
    endif

    " Update the change count of the headings.
    call s:set_outline_data(a:context.buffer.nr, 'model_changenr', changenr())

    let success = 1
    return headings

    " Don't catch anything.

  finally
    " Remove the temporary context data.
    unlet a:context.lines
    unlet a:context.heading_lnum
    unlet a:context.matched_lnum

    " Restore the cursor and scroll.
    let save_scrolloff = &scrolloff
    set scrolloff=0
    call cursor(save_topline, 1)
    normal! zt
    call setpos('.', save_cursor)
    let &scrolloff = save_scrolloff
    " Switch: current window <- source buffer's window
    wincmd p

    " Restore the Vim options.
    let &lazyredraw  = save_lazyredraw
    let &winheight   = save_winheight
    let &winwidth    = save_winwidth
    let &eventignore = save_eventignore

    if success
      " Print a progress message.
      if a:context.event ==# 'auto_update'
        if g:unite_source_outline_verbose
          call s:Util.print_progress("Update headings...done.")
        endif
      else
        call s:Util.print_progress("Extract headings...done.")
      endif
      call s:benchmark_stop(start_time)
    endif
  endtry
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
    let num_lines = line('$')
    let used_time = s:get_reltime() - a:start_time
    let used_time_100l = used_time * (str2float("100") / num_lines)
    call s:Util.print_progress("unite-outline: used=" . string(used_time) .
          \ "s, 100l=". string(used_time_100l) . "s")
  endif
endfunction

function! s:get_reltime()
  return str2float(reltimestr(reltime()))
endfunction

" Extract headings from the source buffer in its filetype specific way using
" the filetype's outline info.
"
function! s:extract_filetype_Headings(context)
  let buffer  = a:context.buffer
  if a:context.is_force
    " Re-source the outline info if updated.
    let a:context.outline_info = s:get_outline_info(buffer.filetype)
  endif
  let outline_info = a:context.outline_info
  if empty(outline_info)
    if empty(buffer.filetype)
      call unite#print_message("[unite-outline] Please set the filetype.")
    else
      call unite#print_message("[unite-outline] " .
            \ "Sorry, " . toupper(buffer.filetype) . " is not supported.")
    endif
    return s:Headings_new([])
  endif

  " Extract headings.
  if has_key(outline_info, 'initialize')
    call outline_info.initialize(a:context)
  endif
  if has_key(outline_info, 'extract_headings')
    let lt_headings = outline_info.extract_headings(a:context)
    " NOTE: lt_ prefix means `List or Tree'.
    let is_normalized = 0
  else
    let lt_headings = s:builtin_extract_headings(a:context)
    let is_normalized = 1
  endif
  if has_key(outline_info, 'finalize')
    call outline_info.finalize(a:context)
  endif

  " Normalize headings.
  let headings = s:Headings_new(lt_headings)
  if !is_normalized
    call map(headings.as_list, 's:normalize_heading(v:val, a:context)')
  endif

  " Filter headings.
  let ignore_types =
        \ unite#sources#outline#get_filetype_option(buffer.filetype, 'ignore_types')
  let headings = s:filter_Headings(headings, ignore_types)

  return headings
endfunction

function! s:Headings_new(lt_headings)
  let headings = {}
  if type(a:lt_headings) == type({})
    let headings.as_tree = a:lt_headings
    let headings.as_list = s:Tree.flatten(a:lt_headings)
  else
    let headings.as_tree = s:Tree.build(a:lt_headings)
    let headings.as_list = a:lt_headings
  endif
  return headings
endfunction

function! s:builtin_extract_headings(context)
  let outline_info = a:context.outline_info
  let [which, pattern] = s:build_heading_pattern(outline_info)

  let has_create_heading = has_key(outline_info, 'create_heading')
  let num_lines = line('$')

  let skip_ranges = s:get_skip_ranges(a:context)
  call add(skip_ranges, [num_lines + 1, num_lines + 2]) | " sentinel
  let srp = 0 | " skip range pointer

  let headings = []
  call cursor(1, 1)
  while 1
    let step  = 1
    let found = 0
    " Search the buffer for the next heading.
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
          let a:context.heading_lnum = lnum + 1
          let a:context.matched_lnum = lnum
          let step  = 2
          let found = 1
        elseif next_line =~ '\S' && lnum < num_lines - 4
          " See one more next.
          let next_line = getline(lnum + 2)
          if next_line =~ '[[:punct:]]\@!\S'
            let a:context.heading_lnum = lnum + 2
            let a:context.matched_lnum = lnum
            let step  = 3
            let found = 1
          endif
        endif
      elseif which[submatch] ==# 'heading'
        " Matched: heading
        let a:context.heading_lnum = lnum
        let a:context.matched_lnum = lnum
        let found = 1
      elseif which[submatch] ==# 'heading+1' && lnum > 0
        " Matched: heading+1
        let a:context.heading_lnum = lnum - 1
        let a:context.matched_lnum = lnum
        let prev_line = getline(lnum - 1)
        let found = (prev_line =~ '[[:punct:]]\@!\S')
      endif
      if found
        let heading_line = getline(a:context.heading_lnum)
        let matched_line = getline(a:context.matched_lnum)
        if has_create_heading
          let heading = outline_info.create_heading(
                \ which[submatch], heading_line, matched_line, a:context)
        else
          let heading = heading_line
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading, a:context))
        endif
        if len(headings) >= g:unite_source_outline_max_headings
          call unite#print_message("[unite-outline] " . 
                \ "Too many headings, the extraction was interrupted.")
          break
        endif
      endif
    endif
    if lnum == num_lines
      break
    endif
    call cursor(lnum + step, 1)
  endwhile
  return headings
endfunction

" Merge heading-1, heading, heading+1 patterns into one heading pattern for
" use of searchpos().
"
" Example of the return value:
"
"   [ ['dummy', 'dummy', 'heading-1', 'heading', 'heading+1'],
"     '\%(\(heading-1\)\|\(heading\)\|\(heading+1\)\)' ]
"
function! s:build_heading_pattern(outline_info)
  let which = ['dummy', 'dummy']
  " NOTE: searchpos() returns submatch counted from 2.
  let sub_patterns = []
  if has_key(a:outline_info, 'heading-1')
    call add(which, 'heading-1')
    call add(sub_patterns, a:outline_info['heading-1'])
  endif
  if has_key(a:outline_info, 'heading')
    call add(which, 'heading')
    call add(sub_patterns, a:outline_info.heading)
  endif
  if has_key(a:outline_info, 'heading+1')
    call add(which, 'heading+1')
    call add(sub_patterns, a:outline_info['heading+1'])
  endif
  call map(sub_patterns, 's:_substitue_sub_pattern(v:val)')
  let pattern = '\%(' . join(sub_patterns, '\|') . '\)'
  return [which, pattern]
endfunction
function! s:_substitue_sub_pattern(pattern)
  " Substitute all '\(' with '\%('
  let meta_lparen = '\(\(^\|[^\\]\)\(\\\{2}\)*\)\@<=\\('
  return '\(' . substitute(a:pattern, meta_lparen, '\\%(', 'g') . '\)'
endfunction

" Returns a List of ranges to be skipped while the extraction.
"
function! s:get_skip_ranges(context)
  let outline_info = a:context.outline_info
  if !has_key(outline_info, 'skip') | return [] | endif
  let ranges = []
  if has_key(outline_info.skip, 'header')
    let header_range = s:get_header_range(a:context)
    if !empty(header_range)
      call add(ranges, header_range)
    endif
  endif
  if has_key(outline_info.skip, 'block')
    let block = outline_info.skip.block
    let num_lines = line('$')
    call cursor(1, 1)
    while 1
      let beg_lnum = search(block.begin, 'cW')
      if beg_lnum == 0 || beg_lnum == num_lines
        break
      endif
      let end_lnum = search(block.end, 'W')
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

function! s:get_header_range(context)
  let outline_info = a:context.outline_info
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

function! s:extract_folding_Headings()
  let l_headings = []
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
      call add(l_headings, heading)
      if len(l_headings) >= g:unite_source_outline_max_headings
        call unite#print_message("[unite-outline] " .
              \ "Too many l_headings, the extraction was interrupted.")
        break
      endif
    endif
    let curr_level = foldlevel
    let lnum += 1
  endwhile
  call map(l_headings, 's:normalize_heading(v:val)')
  let headings = s:Headings_new(l_headings)
  return headings
endfunction

function! s:normalize_heading(heading, context)
  if type(a:heading) == type("")
    " Normalize to a Dictionary.
    let level = s:Util.get_indent_level(a:context, a:context.heading_lnum)
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
        \ 'lnum' : a:context.heading_lnum,
        \ 'keyword': heading.word,
        \ 'is_marked' : 1,
        \ 'is_matched': 0,
        \ }, 'keep')
  let heading.line = a:context.lines[heading.lnum]
  let heading.signature = s:calc_signature(heading.lnum, a:context.lines)
  let outline_info = a:context.outline_info
  if a:context.extract_method !=# 'folding' && !has_key(heading, 'group')
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

function! s:normalize_heading_word(word)
  let word = substitute(substitute(a:word, '^\s*', '', ''), '\s*$', '', '')
  let word = substitute(word, '\s\+', ' ', 'g')
  return word
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
    let line = matchstr(line, '^\%(.\{5}\)\{,20}')
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
function! s:filter_Headings(headings, ignore_types)
  if empty(a:ignore_types) | return a:headings | endif
  let headings = a:headings

  " Remove comment a:headings.
  if index(a:ignore_types, 'comment') >= 0
    call filter(headings.as_list, 'v:val.type !=# "comment"')
    let headings = s:Headings_new(headings.as_list)
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
  call s:Tree.remove(headings.as_tree, predicate)
  let headings = s:Headings_new(headings.as_tree)

  return headings
endfunction

function! s:convert_headings_to_candidates(headings, unite_context)
  if empty(a:headings.as_list) | return [] | endif
  let bufnr = a:unite_context.source__outline_source_bufnr
  let path = fnamemodify(bufname(bufnr), ':p')
  let candidates = map(copy(a:headings.as_list), 's:create_candidate(v:val, path)')
  let candidates[0].source__headings = a:headings
  return candidates
endfunction

function! s:create_candidate(heading, path)
  " NOTE:
  "   abbr - String for displaying
  "   word - String for narrowing
  let indent = repeat(' ', (a:heading.level - 1) * g:unite_source_outline_indent_width)
  let cand = {
        \ 'abbr': indent . a:heading.word,
        \ 'word': a:heading.keyword,
        \ 'source': 'outline',
        \ 'kind'  : 'jump_list',
        \ 'action__path': a:path,
        \ 'action__line': a:heading.lnum,
        \ 'action__pattern'  : '^' . unite#util#escape_pattern(a:heading.line) . '$',
        \ 'action__signature': a:heading.signature,
        \ 'source__heading'  : a:heading,
        \ }
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
  " Scroll the cursor line down to the best position.
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

"-----------------------------------------------------------------------------
" Auto-update

function! s:register_autocmds()
  augroup plugin-unite-source-outline
    autocmd! * <buffer>
    autocmd CursorHold   <buffer> call s:on_cursor_hold()
    autocmd BufWritePost <buffer> call s:on_buf_write_post()
  augroup END
endfunction

augroup plugin-unite-source-outline-win-enter
  autocmd!
  autocmd BufWinEnter * call s:on_buf_win_enter()
augroup END

function! s:on_cursor_hold()
  let bufnr = bufnr('%')
  if !s:has_outline_data(bufnr)
    return
  endif
  call s:Util.print_debug('event', 'on_cursor_hold at buffer #' . bufnr)
  call s:update_buffer_changenr()
  if s:should_update('hold')
    call s:update_headings(bufnr)
  endif
endfunction

function! s:on_buf_write_post()
  let bufnr = bufnr('%')
  if !s:has_outline_data(bufnr)
    return
  endif
  call s:Util.print_debug('event', 'on_buf_write_post at buffer #' . bufnr)
  call s:update_buffer_changenr()
  if s:should_update('write')
    call s:update_headings(bufnr)
  endif
endfunction

" Update the change count of the current buffer.
"
function! s:update_buffer_changenr()
  call s:set_outline_data(bufnr('%'), 'buffer_changenr', changenr())
endfunction

" Returns True if the current buffer has been changed and the headings of the
" buffer should be updated.
"
function! s:should_update(event)
  let auto_update_enabled = s:get_filetype_option(&l:filetype, 'auto_update')
  if !auto_update_enabled
    return 0
  endif
  let auto_update_event = s:get_filetype_option(&l:filetype, 'auto_update_event')
  if auto_update_event ==# 'write' && a:event ==# 'hold'
    return 0
  endif
  let bufnr = bufnr('%')
  let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
  let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
  call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
        \ ', model = ' . model_changenr)
  return (buffer_changenr != model_changenr)
  " NOTE: The current changenr may smaller than the last one because undo
  " commands decrease the changenr.
endfunction

function! s:update_headings(bufnr)
  call s:Util.print_debug('event', 'update_headings')
  " Update Model data (headings).
  call s:get_Headings(a:bufnr, { 'event': 'auto_update', 'is_force': 1 })
  " Update View (unite.vim' buffer) if the visible outline buffer exists.
  let outline_bufnrs = s:find_outline_buffers(a:bufnr)
  " NOTE: An outline buffer is an unite.vim's buffer that is displaying the
  " candidates from outline source.
  for bufnr in outline_bufnrs
    call s:Util.print_debug('event', 'redraw outline buffer #' . bufnr)
    call unite#force_redraw(bufwinnr(bufnr))
  endfor
endfunction

" Returns a List of bufnrs of the outline buffers that are displaying the
" heading list of the buffer {src_bufnr}.
"
function! s:find_outline_buffers(src_bufnr)
  let outline_bufnrs = []
  let bufnr = 1
  while bufnr <= bufnr('$')
    if bufwinnr(bufnr) > 0
      try
        " NOTE: This code depands on the current implementation of unite.vim.
        if s:is_unite_buffer(bufnr)
          let unite = getbufvar(bufnr, 'unite')
          let outline_source = s:Unite_find_outline_source(unite)
          if !empty(outline_source)
            let unite_context = outline_source.unite__context
            if unite_context.source__outline_source_bufnr == a:src_bufnr
              call add(outline_bufnrs, bufnr)
            endif
          endif
        endif
      catch
        call unite#util#print_error(v:throwpoint)
        call unite#util#print_error(v:exception)
      endtry
    endif
    let bufnr += 1
  endwhile
  return outline_bufnrs
endfunction

function! s:is_unite_buffer(bufnr)
  return (getbufvar(a:bufnr, '&filetype') ==# 'unite')
endfunction

function! s:Unite_find_outline_source(unite)
  let result = filter(copy(a:unite.sources), 'v:val.name ==# "outline"')
  if empty(result)
    return {}
  else
    return result[0]
  endif
endfunction

function! s:on_buf_win_enter()
  let winnr = winnr()
  if !s:has_outline_buffer_ids(winnr)
    return
  endif
  let new_bufnr = bufnr('%')
  if s:is_unite_buffer(new_bufnr)
    " NOTE: When -no-split.
    return
  endif
  let old_bufnr = bufnr('#')
  call s:Util.print_debug('event', 'on_buf_win_enter at window #' . winnr .
        \ ' from buffer #' . old_bufnr . ' to #' . new_bufnr)
  call s:unite_outline_initialize()
  call s:swap_headings(s:get_outline_buffer_ids(winnr), new_bufnr)
endfunction

" Swaps the heading lists displayed in the outline buffers whose buffer ids
" are one of {outline_buffer_ids} for the heading list of buffer {new_bufnr}.
"
function! s:swap_headings(outline_buffer_ids, new_bufnr)
  let bufnr = 1
  while bufnr <= bufnr('$')
    if bufwinnr(bufnr) > 0
      try
        " NOTE: This code depands on the current implementation of unite.vim.
        if s:is_unite_buffer(bufnr)
          let unite = getbufvar(bufnr, 'unite')
          let outline_source = s:Unite_find_outline_source(unite)
          if !empty(outline_source)
            let unite_context = outline_source.unite__context
            if index(a:outline_buffer_ids, unite_context.source__outline_buffer_id) >= 0
              let unite_context.source__outline_source_bufnr = a:new_bufnr
              let unite_context.source__outline_is_swap = 1
              call s:Util.print_debug('event', 'redraw outline buffer #' . bufnr)
              call unite#force_redraw(bufwinnr(bufnr))
            endif
          endif
        endif
      catch
        call unite#util#print_error(v:throwpoint)
        call unite#util#print_error(v:exception)
      endtry
    endif
    let bufnr += 1
  endwhile
endfunction

" vim: filetype=vim
