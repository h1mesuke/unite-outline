"=============================================================================
" File    : autoload/unite/source/outline/_cache.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-05-14
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

function! unite#sources#outline#modules#cache#import(dir)
  let s:Cache.DIR = a:dir
  return s:Cache
endfunction

"-----------------------------------------------------------------------------

let s:Util = unite#sources#outline#import('Util')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:Cache = unite#sources#outline#modules#base#new('Cache', s:SID)
let s:Cache.VAR = 'NuOutline_cache'

if get(g:, 'unite_source_outline_debug', 0)
  let s:Cache.CLEANUP_FILE_COUNT = 10
  let s:Cache.CLEANUP_RATE = 1
  let s:Cache.EXPIRES = 60
else
  let s:Cache.CLEANUP_FILE_COUNT = 100
  let s:Cache.CLEANUP_RATE = 10
  let s:Cache.EXPIRES = 60 * 60 * 24 * 30
endif

function! s:Cache_has(buffer) dict
  let bufvars = getbufvar(a:buffer.nr, '')
  return (has_key(bufvars, s:Cache.VAR) || s:exists_cache_file(a:buffer.path))
endfunction
call s:Cache.function('has')

function! s:exists_cache_file(path)
  return (s:check_cache_dir() && filereadable(s:cache_file_path(a:path)))
endfunction

function! s:check_cache_dir()
  if isdirectory(s:Cache.DIR)
    return 1
  else
    try
      call mkdir(s:Cache.DIR, 'p')
    catch
      call unite#util#print_error("unite-outline: Couldn't create the cache directory.")
    endtry
    return isdirectory(s:Cache.DIR)
  endif
endfunction

function! s:cache_file_path(path)
    return s:Cache.DIR . '/' . s:encode_file_path(a:path)
endfunction

" Original source from Shougo's neocomplcache
" https://github.com/Shougo/neocomplcache
"
function! s:encode_file_path(path)
  if len(s:Cache.DIR) + len(a:path) < 150
    " encode the path to a base name
    return substitute(substitute(a:path, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  else
    " simple hash
    let sum = 0
    for idx in range(len(a:path))
      let sum += char2nr(a:path[idx]) * (idx + 1)
    endfor
    return printf('%X', sum)
  endif
endfunction

function! s:Cache_get(buffer) dict
  let bufvars = getbufvar(a:buffer.nr, '')
  if !has_key(bufvars, s:Cache.VAR) && s:exists_cache_file(a:buffer.path)
    let data = s:load_cache_file(a:buffer.path)
    call setbufvar(a:buffer.nr, s:Cache.VAR, data)
  endif
  let data = getbufvar(a:buffer.nr, s:Cache.VAR)
  return data
endfunction
call s:Cache.function('get')

function! s:load_cache_file(path)
  let cache_file = s:cache_file_path(a:path)
  let lines = readfile(cache_file)
  if !empty(lines)
    let dumped_data = lines[0]
    call s:Util.print_debug("[LOADED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't load the cache file: " . cache_file
  endif
  " touch; update the timestamp
  if writefile([dumped_data], cache_file) == 0
    call s:Util.print_debug("[TOUCHED] cache file: " . cache_file)
  endif
  let data = s:deserialize(dumped_data)
  return data
endfunction

function! s:deserialize(dumped_data)
  sandbox let data = eval(a:dumped_data)
  try
    " ids -> references
    let headings = data
    let heading_table = {}
    for heading in headings
      let heading_table[heading.id] = heading
    endfor
    for heading in headings
      if has_key(heading, 'parent')
        let heading.parent = heading_table[heading.parent]
      endif
      if has_key(heading, 'children')
        call map(heading.children, 'heading_table[v:val]')
      endif
    endfor
  catch
    call s:Util.print_debug(v:throwpoint)
    call s:Util.print_debug(v:exception)
    throw "CacheCompatibilityError:"
  endtry
  return data
endfunction

function! s:Cache_set(buffer, data, is_persistent) dict
  call setbufvar(a:buffer.nr, s:Cache.VAR, a:data)
  try
    if a:is_persistent && s:check_cache_dir()
      call s:save_cache_file(a:buffer.path, a:data)
    elseif s:exists_cache_file(a:buffer.path)
      call s:remove_file(s:cache_file_path(a:buffer.path))
    endif
  catch /^unite-outline:/
    call unite#util#print_error(v:exception)
  endtry
  call s:cleanup_cache_files()
endfunction
call s:Cache.function('set')

function! s:save_cache_file(path, data)
  let cache_file = s:cache_file_path(a:path)
  let dumped_data = s:serialize(a:data)
  if writefile([dumped_data], cache_file) == 0
    call s:Util.print_debug("[SAVED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't save the cache to: " . cache_file
  endif
endfunction

function! s:serialize(data)
  " references -> ids
  let headings = copy(a:data)
  let headings = map(headings, 'copy(v:val)')
  for heading in headings
    if has_key(heading, 'parent')
      let heading.parent = heading.parent.id
    endif
    if has_key(heading, 'children')
      let heading.children = map(copy(heading.children), 'v:val.id')
    endif
  endfor
  let dumped_data = string(headings)
  return dumped_data
endfunction

function! s:Cache_remove(buffer) dict
  let bufvars = getbufvar(a:buffer.nr, '')
  call remove(bufvars, s:Cache.VAR)

  if s:exists_cache_file(a:buffer.path)
    try
      call s:remove_file(s:cache_file_path(a:buffer.path))
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif
endfunction
call s:Cache.function('remove')

function! s:remove_file(path)
    if delete(a:path) == 0
      call s:Util.print_debug("[DELETED] cache file: " . a:path)
    else
      throw "unite-outline: Couldn't delete the cache file: " . a:path
    endif
endfunction

function! s:Cache_clear()
  if s:check_cache_dir()
    call s:cleanup_all_cache_files()
    echomsg "unite-outline: Deleted all cache files."
  else
    call unite#util#print_error("unite-outline: Cache directory doesn't exist.")
  endif
endfunction
call s:Cache.function('clear')

function! s:cleanup_all_cache_files()
  call s:cleanup_cache_files(1)
endfunction

function! s:cleanup_cache_files(...)
  let do_all = (a:0 ? a:1 : 0)
  let cache_files = split(globpath(s:Cache.DIR, '*'), "\<NL>")
  let del_files = []

  if do_all
    let del_files = cache_files
  elseif len(cache_files) > s:Cache.CLEANUP_FILE_COUNT
    let now = localtime()
    if now % s:Cache.CLEANUP_RATE == 0
      for path in cache_files
        if now - getftime(path) > s:Cache.EXPIRES
          call add(del_files, path)
        endif
      endfor
    endif
  endif
  for path in del_files
    try
      call s:remove_file(path)
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endfor
endfunction

" vim: filetype=vim
