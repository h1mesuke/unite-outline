"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-10-23
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

" NOTE: source <- [aliases...]
let s:OUTLINE_ALIASES = {
      \ 'markdown': ['mkd'],
      \ 'cpp'     : ['c'],
      \ 'dosini'  : ['cfg'],
      \ 'tex'     : ['plaintex'],
      \ 'conf'    : ['snippet'],
      \ 'html'    : ['eruby', 'xhtml'],
      \ 'sh'      : ['zsh'],
      \ }

let s:OUTLINE_CACHE_DIR = g:unite_data_directory . '/outline'

" Rename the cache directory if its name is still old, dotted style name.
" See http://d.hatena.ne.jp/tyru/20110824/unite_file_mru
"
let old_cache_dir = g:unite_data_directory . '/.outline'
if isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir) 
    call unite#print_message("[unite-outline] Warning: Please remove the old cache directory: ")
    call unite#print_message("[unite-outline] " . old_cache_dir)
  endif
else " if !isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir)
    if rename(old_cache_dir, s:OUTLINE_CACHE_DIR) != 0
      let s:OUTLINE_CACHE_DIR = old_cache_dir
      call unite#util#print_error("unite-outline: Couldn't rename the cache directory.")
    endif
  endif
endif
unlet old_cache_dir

let s:FILECACHE_FORMAT_VERSION = 2
let s:FILECACHE_FORMAT_VERSION_KEY = '__unite_outline_filecache_format_version__'

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
  call s:define_filetype_aliases(a:filetype, a:alias)
endfunction

let s:{"filetype"}_alias_table = {}
" NOTE: Workaround for Vim's syntax highlight bug.

function! s:define_filetype_aliases(filetype, ...)
  for alias in a:000
    let s:filetype_alias_table[alias] = a:filetype
  endfor
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
  return s:get_outline_info(a:filetype)
endfunction

function! s:get_outline_info(filetype, ...)
  echomsg "hoge"
  let reload = (a:0 ? a:1 : 0)
  for filetype in s:resolve_filetype(a:filetype)
    if has_key(g:unite_source_outline_info, filetype)
      return g:unite_source_outline_info[filetype]
    endif
    for dir in s:OUTLINE_INFO_PATH
      let load_func  = substitute(substitute(dir, '^autoload/', '', ''), '/', '#', 'g')
      let load_func .= substitute(filetype, '\.', '_', 'g') . '#outline_info'
      try
        let outline_info = {load_func}()
      catch /^Vim\%((\a\+)\)\=:E117:/
        " E117: Unknown function:
        continue
      endtry
      if reload
        let outline_info = s:reload_outline_info(load_func)
      endif
      call s:initialize_outline_info(outline_info)
      return outline_info
    endfor
  endfor
endfunction

" Reloads the outline info for {load_func}.
"
function! s:reload_outline_info(load_func)
  " path#to#filetype#outline_info() -> autoload/path/to/filetype.vim
  let path_list = split(a:load_func, '#')
  let rel_path = 'autoload/' . join(path_list[:-2], '/') . '.vim'
  let script_path = get(split(globpath(&runtimepath, rel_path), "\<NL>"), 0, '')
  " Reload the outline info.
  let script_path = fnamemodify(script_path, ':p')
  source `=script_path`
  return {a:load_func}()
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
" filetypes and aliases of each of them.
"
"   {filetype}
"     |/
"   (1)aaa.bbb.ccc -> (2)aliases
"   (3)aaa/bbb/ccc -> (4)aliases
"     |/
"   (5)aaa.bbb     -> (6)aliases
"   (7)aaa/bbb     -> (8)aliases
"     |/
"   (9)aaa         -> ($)aliases
"
function! s:resolve_filetype(filetype)
  let ftcands = []
  let ftype = a:filetype
  while 1
    call add(ftcands, ftype)
    let ftcands += s:resolve_filetype_alias(ftype)
    if ftype =~ '\.'
      let dsl_ftype = substitute(ftype, '\.', '/', 'g')
      call add(ftcands, dsl_ftype)
      let ftcands += s:resolve_filetype_alias(dsl_ftype)
    endif
    if ftype =~ '[./]\w\+$'
      let ftype = substitute(ftype, '[./]\w\+$', '', '')
    else
      break
    endif
  endwhile
  call add(ftcands, '*')
  return ftcands
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
        \ ? g:unite_source_outline_highlight[a:name] : s:default_highlight[a:name])
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
      \ 'expanded': 'Constant',
      \ 'function': 'Function',
      \ 'id'      : 'Special',
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

" Define the default filetype aliases.
for [filetype, aliases] in items(s:OUTLINE_ALIASES)
  call call('s:define_filetype_aliases', [filetype] + aliases)
endfor

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
  call s:initialize_outline_data()
  call s:attach_outline_buffer(s:outline_buffer_id)
  let s:outline_buffer_id += 1
endfunction
let s:source.hooks.on_init = function(s:SID . 'Source_Hooks_on_init')

" Initialize the current buffer's outline data and register autocommands to
" manage the data if the buffer hasn't been initialized yet.
"
function! s:initialize_outline_data()
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
function! s:attach_outline_buffer(buffer_id)
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
  if context.extracted_by ==# 'filetype'
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
    " NOTE: Folding headings are not highlighted at all.
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

    let bufnr = a:unite_context.source__outline_source_bufnr
    let options = s:parse_source_arguments(a:source_args, a:unite_context)

    let auto_update = s:get_filetype_option(getbufvar(bufnr, '&filetype'), 'auto_update', 0)
    if auto_update
      let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
      let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
      if model_changenr != buffer_changenr
        " The source buffer has been changed since the last extraction.
        " Need to update the candidates.
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr)
        let options.is_force = 1
      endif
    endif

    let candidates = s:get_candidates(bufnr, options)

    if auto_update
      if get(g:, 'unite_source_outline_event_debug', 0)
        let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
        let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr)
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
        \ 'extracted_by': '?',
        \ }
  for value in a:source_args
    if value =~# '^\%(ft\|fi\%[letype]\)$'
      let options.extracted_by = 'filetype'
    elseif value =~# '^fo\%[lding]$'
      let options.extracted_by = 'folding'
    elseif value =~# '^\%(update\|!\)$'
      let options.is_force = 1
    endif
  endfor
  if a:unite_context.is_redraw
    let options.is_force = 1
  endif
  if has_key(a:unite_context, 'source__outline_swapping')
    unlet a:unite_context.source__outline_swapping
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
        \ 'sw'  : getbufvar(a:bufnr, '&shiftwidth'),
        \ 'ts'  : getbufvar(a:bufnr, '&tabstop'),
        \ }
  let buffer.filetypes = split(getbufvar(a:bufnr, '&filetype'), '\.')
  let buffer.filetype = buffer.filetypes[0]
  let context = {
        \ 'trigger': 'user', 'is_force': 0, 'buffer': buffer,
        \ 'extracted_by': '?',
        \ }
  call extend(context, (a:0 ? a:1 : {}))
  return context
endfunction

" Returns True if the cached {candidates} is valid and reusable.
"
function! s:is_valid_candidates(candidates, context)
  let last_method = (!empty(a:candidates) &&
        \ a:candidates[0].source__heading_type ==# 'folding' ? 'folding' : 'filetype')
  if a:context.extracted_by == '?'
    let a:context.extracted_by = last_method
  endif
  return (a:context.extracted_by ==# last_method)
endfunction

" Returns False if {cache_data}'s format is not compatible with the current
" version of unite-outline.
"
function! s:is_valid_filecache(cache_data)
  return (type(a:cache_data) == type({})
        \ && has_key(a:cache_data, s:FILECACHE_FORMAT_VERSION_KEY)
        \ && a:cache_data[s:FILECACHE_FORMAT_VERSION_KEY] == s:FILECACHE_FORMAT_VERSION)
endfunction

function! s:get_candidates(bufnr, options)
  " Update the context Dictionary.
  let context = s:create_context(a:bufnr, a:options)
  call s:set_outline_data(a:bufnr, 'context', context)
  if context.is_force || !s:has_outline_data(a:bufnr, 'outline_info')
    " If triggered by <C-l>, reload the outline info.
    let reload = (context.is_force && context.trigger ==# 'user')
    let outline_info = s:get_outline_info(context.buffer.filetype, reload)
    call s:set_outline_data(a:bufnr, 'outline_info', outline_info)
  else
    let outline_info = s:get_outline_data(a:bufnr, 'outline_info')
  end
  let context.outline_info = outline_info

  if !context.is_force && s:has_outline_data(a:bufnr, 'candidates')
    " Path A: Get candidates from the buffer local cache.
    let candidates = s:get_outline_data(a:bufnr, 'candidates')
    if s:is_valid_candidates(candidates, context)
      return candidates
    endif
  endif

  if !context.is_force && s:FileCache.has(a:bufnr)
    " Path B: Get candidates from the file cache.
    try
      let cache_data = s:FileCache.get(a:bufnr)
      if s:is_valid_filecache(cache_data)
        let candidates = cache_data.candidates
        if s:is_valid_candidates(candidates, context)
          " Save the candidates to the buffer local cache.
          call s:set_outline_data(a:bufnr, 'candidates', candidates)
          return candidates
        endif
      endif
      " Fallback to Path C.
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif

  " Path C: Candidates are invalid or haven't been cached, so try to get
  " candidates by extracting headings from the buffer.

  " Get headings by parsing the buffer.
  let headings = s:extract_headings(context)
  " Convert the headings into candidates.
  let candidates = s:convert_headings_to_candidates(headings, a:bufnr)

  let is_volatile = get(context.outline_info, 'is_volatile', 0)
  if !is_volatile
    " Save the candidates to the buffer local cache.
    call s:set_outline_data(a:bufnr, 'candidates', candidates)
    let is_persistant = (context.__num_lines__ > g:unite_source_outline_cache_limit)
    if is_persistant
      let cache_data = { 'candidates': candidates }
      let cache_data[s:FILECACHE_FORMAT_VERSION_KEY] = s:FILECACHE_FORMAT_VERSION
      call s:FileCache.set(a:bufnr, cache_data)
    elseif s:FileCache.has(a:bufnr)
      " Remove the invalid file cache.
      call s:FileCache.remove(a:bufnr)
    endif
  endif
  return candidates
endfunction

function! s:extract_headings(context)
  let src_winnr = bufwinnr(a:context.buffer.nr)
  if src_winnr == -1
    throw "NoWindowError:"
  endif

  " Print a progress message.
  if a:context.trigger ==# 'auto_update'
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
    let cur_winnr = winnr()
    execute src_winnr . 'wincmd w'
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
    if a:context.extracted_by !=# 'folding'
      " Path C_1: Extract headings in filetype-specific way using the
      " filetype's outline info.
      let a:context.extracted_by = 'filetype'
      let headings = s:extract_filetype_headings(a:context)
    else
      " Path C_2: Extract headings using folds' information.
      let a:context.extracted_by = 'folding'
      let headings = s:extract_folding_headings(a:context)
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
    execute cur_winnr . 'wincmd w'

    " Restore the Vim options.
    let &lazyredraw  = save_lazyredraw
    let &winheight   = save_winheight
    let &winwidth    = save_winwidth
    let &eventignore = save_eventignore

    if success
      " Print a progress message.
      if a:context.trigger ==# 'auto_update'
        if g:unite_source_outline_verbose
          call s:Util.print_progress("Update headings...done.")
        endif
      else
        call s:Util.print_progress("Extract headings...done.")
      endif
      call s:benchmark_stop(start_time, a:context.__num_lines__)
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

function! s:benchmark_stop(start_time, num_lines)
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    let used_time = s:get_reltime() - a:start_time
    let used_time_100l = used_time * (str2float("100") / a:num_lines)
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
function! s:extract_filetype_headings(context)
  let buffer  = a:context.buffer
  let outline_info = a:context.outline_info
  if empty(outline_info)
    if empty(buffer.filetype)
      call unite#print_message("[unite-outline] Please set the filetype.")
    else
      call unite#print_message("[unite-outline] " .
            \ "Sorry, " . toupper(buffer.filetype) . " is not supported.")
    endif
    return []
  endif

  " Extract headings.
  if has_key(outline_info, 'initialize')
    call outline_info.initialize(a:context)
  endif
  if has_key(outline_info, 'extract_headings')
    let headings = outline_info.extract_headings(a:context)
    let headings_normalized = 0
  else
    let headings = s:builtin_extract_headings(a:context)
    let headings_normalized = 1
  endif
  if has_key(outline_info, 'finalize')
    call outline_info.finalize(a:context)
  endif

  " Normalize headings.
  if type(headings) == type({})
    let heading_tree = headings | unlet headings
    let headings = s:Tree.flatten(heading_tree)
  else
    let headings = s:Tree.List.normalize_levels(headings)
  endif
  if !headings_normalized
    call map(headings, 's:normalize_heading(v:val, a:context)')
  endif

  " Filter headings.
  let ignore_types = unite#sources#outline#get_filetype_option(buffer.filetype, 'ignore_types')
  let headings = s:filter_headings(headings, ignore_types)

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

function! s:extract_folding_headings(context)
  let headings = []
  let cur_level = 0
  let lnum = 1 | let num_lines = line('$')
  while lnum < num_lines
    let foldlevel = foldlevel(lnum)
    if foldlevel > cur_level
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
      call add(headings, s:normalize_heading(heading, a:context))
      if len(headings) >= g:unite_source_outline_max_headings
        call unite#print_message("[unite-outline] " .
              \ "Too many headings, the extraction was interrupted.")
        break
      endif
    endif
    let cur_level = foldlevel
    let lnum += 1
  endwhile
  return headings
endfunction

function! s:normalize_heading(heading, context)
  let outline_info = a:context.outline_info
  let a:heading.id = s:heading_id
  let a:heading.word = s:normalize_heading_word(a:heading.word)
  call extend(a:heading, {
        \ 'level': 1,
        \ 'type' : 'generic',
        \ 'lnum' : a:context.heading_lnum,
        \ 'keyword': a:heading.word,
        \ }, 'keep')
  let a:heading.line = a:context.lines[a:heading.lnum]
  let a:heading.signature = s:calc_signature(a:heading.lnum, a:context.lines)
  " group
  if !has_key(a:heading, 'group')
    let group_map = get(outline_info, 'heading_group_map', {})
    let a:heading.group = get(group_map, a:heading.type, 'generic')
  endif
  " keyword => candidate.word
  if has_key(outline_info, '__not_match_pattern__')
    let a:heading.keyword =
          \ substitute(a:heading.word, outline_info.__not_match_pattern__, '', 'g')
  endif
  let s:heading_id += 1
  return a:heading
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
function! s:filter_headings(headings, ignore_types)
  if empty(a:ignore_types) | return a:headings | endif
  let headings = a:headings
  let ignore_types = copy(a:ignore_types)

  " Remove comment headings.
  let idx = index(ignore_types, 'comment')
  if idx >= 0
    call filter(headings, 'v:val.type !=# "comment"')
    let headings = s:Tree.List.normalize_levels(headings)
    call remove(ignore_types, idx)
  endif
  " Remove headings to be ignored.
  call map(ignore_types, 'unite#util#escape_pattern(v:val)')
  let ignore_types_pattern = '^\%(' . join(ignore_types, '\|') . '\)$'
  let pred = 'v:val.type =~# ' . string(ignore_types_pattern)
  let headings = s:Tree.List.remove(headings, pred)
  return headings
endfunction

function! s:convert_headings_to_candidates(headings, bufnr)
  if empty(a:headings) | return [] | endif
  let path = fnamemodify(bufname(a:bufnr), ':p')
  let candidates = map(copy(a:headings), 's:create_candidate(v:val, path)')
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
        \ 'action__pattern': '^' . unite#util#escape_pattern(a:heading.line) . '$',
        \ 'action__signature': a:heading.signature,
        \ 'source__heading_id': a:heading.id,
        \ 'source__heading_level': a:heading.level,
        \ 'source__heading_type' : a:heading.type,
        \ 'source__heading_group': a:heading.group,
        \}
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
  " Update the Model data (headings).
  call s:get_candidates(a:bufnr, { 'trigger': 'auto_update', 'is_force': 1 })

  " Update the View (unite.vim' buffer) if the visible outline buffer exists.
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
  if unite#is_win()
    return (bufname(a:bufnr) =~# '^\[unite\]')
  else
    return (bufname(a:bufnr) =~# '^\*unite\*')
  endif
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
  call s:initialize_outline_data()
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
              let unite_context.source__outline_swapping = 1
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
