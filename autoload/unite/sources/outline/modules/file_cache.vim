"=============================================================================
" File    : autoload/unite/source/outline/_cache.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
" Version : 0.5.1
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

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#outline#modules#file_cache#import(dir)
  let s:FileCache.DIR = a:dir
  return s:FileCache
endfunction

"-----------------------------------------------------------------------------

let s:Util = unite#sources#outline#import('Util')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

" FileCache module provides functions to access and manage the cache data
" stored in files on the local filesystem.
"
let s:FileCache = unite#sources#outline#modules#base#new('FileCache', s:SID)

if get(g:, 'unite_source_outline_debug', 0)
  let s:FileCache.CLEANUP_FILE_COUNT = 10
  let s:FileCache.CLEANUP_RATE = 1
  let s:FileCache.EXPIRES = 60
else
  let s:FileCache.CLEANUP_FILE_COUNT = 300
  let s:FileCache.CLEANUP_RATE = 10
  let s:FileCache.EXPIRES = 60 * 60 * 24 * 30
endif

" Returns True if the cached data associated with buffer {bufnr} is available.
"
function! s:FileCache_has(bufnr) dict
  let path = s:get_buffer_path(a:bufnr)
  return s:cache_file_exists(path)
endfunction
call s:FileCache.function('has')

" Returns True if the cache file associated with file {path} exists.
"
function! s:cache_file_exists(path)
  return (s:cache_dir_exists() && filereadable(s:get_cache_file_path(a:path)))
endfunction

" Returns True if the cache directory exists.
"
function! s:cache_dir_exists()
  if isdirectory(s:FileCache.DIR)
    return 1
  else
    try
      call mkdir(iconv(s:FileCache.DIR, &encoding, &termencoding), 'p')
    catch
      call unite#util#print_error("unite-outline: Couldn't create the cache directory.")
    endtry
    return isdirectory(s:FileCache.DIR)
  endif
endfunction

" Returns a full pathname of the file opened at the buffer {bufnr}.
"
function! s:get_buffer_path(bufnr)
  return fnamemodify(bufname(a:bufnr), ':p')
endfunction

" Returns a full pathname of the cache file for the file {path}.
"
function! s:get_cache_file_path(path)
  return s:FileCache.DIR . '/' . s:encode_file_path(a:path)
endfunction

" Encodes a full pathname to a basename.
"
" Original source from Shougo's neocomplcache
" https://github.com/Shougo/neocomplcache
"
function! s:encode_file_path(path)
  if len(s:FileCache.DIR) + len(a:path) < 150
    " Encode {path} to a basename.
    return substitute(substitute(a:path, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  else
    " Calculate a simple hash.
    let sum = 0
    for idx in range(len(a:path))
      let sum += char2nr(a:path[idx]) * (idx + 1)
    endfor
    return printf('%X', sum)
  endif
endfunction

" Returns the cached data associated with buffer {bufnr}.
"
function! s:FileCache_get(bufnr) dict
  let path = s:get_buffer_path(a:bufnr)
  let data = s:load_cache_file(path)
  return data
endfunction
call s:FileCache.function('get')

function! s:load_cache_file(path)
  let cache_file = s:get_cache_file_path(a:path)
  let lines = readfile(cache_file)
  if !empty(lines)
    let dumped_data = lines[0]
    call s:print_debug("[LOADED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't load the cache file: " . cache_file
  endif
  " Touch; Update the timestamp.
  if writefile([dumped_data], cache_file) == 0
    call s:print_debug("[TOUCHED] cache file: " . cache_file)
  endif
  sandbox let data = eval(dumped_data)
  return data
endfunction

" Saves {data} to the cache file.
"
function! s:FileCache_set(bufnr, data) dict
  let path = s:get_buffer_path(a:bufnr)
  try
    if s:cache_dir_exists()
      call s:save_cache_file(path, a:data)
    elseif s:cache_file_exists(path)
      call s:remove_file(s:get_cache_file_path(path))
    endif
  catch /^unite-outline:/
    call unite#util#print_error(v:exception)
  endtry
  call s:cleanup_cache_files()
endfunction
call s:FileCache.function('set')

function! s:save_cache_file(path, data)
  let cache_file = s:get_cache_file_path(a:path)
  let dumped_data = string(a:data)
  if writefile([dumped_data], cache_file) == 0
    call s:print_debug("[SAVED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't save the cache to: " . cache_file
  endif
endfunction

" Remove the cached data associated with buffer {bufnr}.
"
function! s:FileCache_remove(bufnr) dict
  let path = s:get_buffer_path(a:bufnr)
  if s:cache_file_exists(path)
    try
      call s:remove_file(s:get_cache_file_path(path))
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif
endfunction
call s:FileCache.function('remove')

function! s:remove_file(path)
    if delete(a:path) == 0
      call s:print_debug("[DELETED] cache file: " . a:path)
    else
      throw "unite-outline: Couldn't delete the cache file: " . a:path
    endif
endfunction

" Remove all cache files.
"
function! s:FileCache_clear()
  if s:cache_dir_exists()
    call s:cleanup_all_cache_files()
    echomsg "unite-outline: Deleted all cache files."
  else
    call unite#util#print_error("unite-outline: Cache directory doesn't exist.")
  endif
endfunction
call s:FileCache.function('clear')

function! s:cleanup_all_cache_files()
  call s:cleanup_cache_files(1)
endfunction

" Remove old cache files.
"
function! s:cleanup_cache_files(...)
  let delete_all = (a:0 ? a:1 : 0)
  let cache_files = split(globpath(s:FileCache.DIR, '*'), "\<NL>")
  let dlt_files = []

  if delete_all
    let dlt_files = cache_files
  elseif len(cache_files) > s:FileCache.CLEANUP_FILE_COUNT
    let now = localtime()
    if now % s:FileCache.CLEANUP_RATE == 0
      for path in cache_files
        if now - getftime(path) > s:FileCache.EXPIRES
          call add(dlt_files, path)
        endif
      endfor
    endif
  endif
  for path in dlt_files
    try
      call s:remove_file(path)
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endfor
endfunction

function! s:print_debug(msg)
  call s:Util.print_debug('cache', a:msg)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
