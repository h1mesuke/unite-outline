"=============================================================================
" File    : autoload/unite/source/outline/_cache.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-03-28
" Version : 0.3.2
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

function! unite#sources#outline#modules#cache#module()
  let s:tree = unite#sources#outline#import('tree')
  let s:util = unite#sources#outline#import('util')
  return s:cache
endfunction

function! s:Cache_has(path) dict
  return (has_key(self.data, a:path) || s:exists_cache_file(a:path))
endfunction

function! s:exists_cache_file(path)
  return (s:check_cache_dir() && filereadable(s:cache_file_path(a:path)))
endfunction

function! s:check_cache_dir()
  if isdirectory(s:cache.dir)
    return 1
  else
    try
      call mkdir(s:cache.dir, 'p')
    catch
      call unite#util#print_error("unite-outline: Couldn't create the cache directory.")
    endtry
    return isdirectory(s:cache.dir)
  endif
endfunction

function! s:cache_file_path(path)
    return s:cache.dir . '/' . s:encode_file_path(a:path)
endfunction

" Original source from Shougo' neocomplcache
" https://github.com/Shougo/neocomplcache
"
function! s:encode_file_path(path)
  if len(s:cache.dir) + len(a:path) < 150
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

function! s:Cache_get(path) dict
  if !has_key(self.data, a:path) && s:exists_cache_file(a:path)
    try
      let self.data[a:path] = s:load_cache_file(a:path)
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
      return []
    endtry
  endif
  let item = self.data[a:path]
  let item.touched = localtime()
  return item.candidates
endfunction

function! s:load_cache_file(path)
  let cache_file = s:cache_file_path(a:path)

  " load
  let lines = readfile(cache_file)
  if !empty(lines)
    let dumped_data = lines[0]
    call s:util.print_debug("[LOADED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't load the cache file: " . cache_file
  endif

  " touch; update the timestamp
  if writefile([dumped_data], cache_file) == 0
    call s:util.print_debug("[TOUCHED] cache file: " . cache_file)
  endif

  " deserialize
  sandbox let data = eval(dumped_data)
  call s:tree.convert_id_to_ref(data.candidates)

  return data
endfunction

function! s:Cache_set(path, candidates, should_serialize) dict
  let self.data[a:path] = {
        \ 'candidates': a:candidates,
        \ 'touched'   : localtime(),
        \ }

  let cache_items = items(self.data)
  let num_dels = len(cache_items) - g:unite_source_outline_cache_buffers
  if num_dels > 0
    call map(cache_items, '[v:val[0], v:val[1].touched]')
    call sort_by_ftime(cache_items)
    let del_buffs = map(cache_items[0 : num_dels - 1], 'v:val[0]')
    for path in del_buffs
      unlet self.data[path]
    endfor
  endif

  try
    if a:should_serialize && s:check_cache_dir()
      call s:save_cache_file(a:path, self.data[a:path])
    elseif s:exists_cache_file(a:path)
      call s:remove_file(s:cache_file_path(a:path))
    endif
  catch /^unite-outline:/
    call unite#util#print_error(v:exception)
  endtry
endfunction

function! s:save_cache_file(path, data)
  let cache_file = s:cache_file_path(a:path)

  " NOTE: Built-in string() function can't dump an object that has any cyclic
  " references because of E724, nested too deep error; therefore, we need to
  " substitute direct references to the object's parent and children with
  " their id numbers before serialization.
  "
  call s:tree.convert_ref_to_id(a:data.candidates)

  " serialize
  let dumped_data = string(a:data)

  " save
  if writefile([dumped_data], cache_file) == 0
    call s:util.print_debug("[SAVED] cache file: " . cache_file)
  else
    throw "unite-outline: Couldn't save the cache to: " . cache_file
  endif

  call s:cleanup_cache_files()
endfunction

function! s:Cache_remove(path) dict
  call remove(self.data, a:path)
  if s:exists_cache_file(a:path)
    try
      call s:remove_file(s:cache_file_path(a:path))
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif
endfunction

function! s:remove_file(path)
    if delete(a:path) == 0
      call s:util.print_debug("[DELETED] cache file: " . a:path)
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

function! s:cleanup_cache_files(...)
  let do_all = (a:0 ? a:1 : 0)
  let cache_files = split(globpath(s:cache.dir, '*'), "\<NL>")

  if do_all
    let del_files = cache_files
  else
    let num_dels = len(cache_files) - g:unite_source_outline_cache_buffers
    if num_dels > 0
      call map(cache_files, '[v:val, getftime(v:val)]')
      call sort_by_ftime(cache_files)
      let del_files = map(cache_files[0 : num_dels - 1], 'v:val[0]')
    else
      return
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

function! s:cleanup_all_cache_files()
  call s:cleanup_cache_files(1)
endfunction

function! s:sort_by_ftime(zipped_list)
  return sort(zipped_list, 's:compare_2nd')
endfunction
function! s:compare_2nd(pair1, pair2)
  let t1 = a:pair1[1]
  let t2 = a:pair2[1]
  return t1 == t2 ? 0 : t1 > t2 ? 1 : -1
endfunction

"-----------------------------------------------------------------------------

function! s:get_SID()
  return str2nr(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_'))
endfunction

let s:cache = unite#sources#outline#make_module(s:get_SID(), 'Cache')

let s:cache.dir  = g:unite_data_directory . '/.outline'
let s:cache.data = {}

" vim: filetype=vim
