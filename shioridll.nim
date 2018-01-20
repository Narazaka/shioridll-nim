##[
The SHIORI DLL interface

This is released under `MIT License <https://narazaka.net/license/MIT?2017>`_.

- `Repository <https://github.com/Narazaka/shioridll-nim>`_

How to make SHIORI.DLL
=============

write your myshiori.nim like below...

.. code-block:: Nim
  import shioridll
  import strutils

  shioriLoadCallback = proc(strPtr: cstring): bool =
    dealloc(strPtr)
    true

  shioriRequestCallback = proc(strPtr: cstring): cstring =
    let str = $strPtr
    dealloc(strPtr)
    let retStr =
      if str.contains("SHIORI/2"):
        "SHIORI/3.0 400 Bad Reuqest\nCharset: UTF-8\nSender: nimshiori\n\n"
      elif str.contains("ID: name"):
        "SHIORI/3.0 200 OK\nCharset: UTF-8\nSender: nimshiori\nValue: nimshiori\n\n"
      elif str.contains("ID: version"):
        "SHIORI/3.0 200 OK\nCharset: UTF-8\nSender: nimshiori\nValue: 0.0.1\n\n"
      elif str.contains("ID: craftman"):
        "SHIORI/3.0 200 OK\nCharset: UTF-8\nSender: nimshiori\nValue: narazaka\n\n"
      elif str.contains("ID: OnBoot"):
        "SHIORI/3.0 200 OK\nCharset: UTF-8\nSender: nimshiori\nValue: \\0\\s[0]aaaaaa\\e\n\n"
      else:
        "SHIORI/3.0 204 No Content\nCharset: UTF-8\nSender: nimshiori\n\n"
    var retStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * (retStr.len() + 1)))
    copyMem(retStrPtr, cstring(retStr), retStr.len() + 1)
    retStrPtr

  shioriUnloadCallback = proc(): bool =
    true

  # for test
  when appType != "lib":
    main("C:\\ssp\\ghost\\nim\\", @[
      "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
      "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
    ])

then make 32bit dll...

.. code-block::
  nim c --app:lib -d:release --cc:vcc --cpu:i386 myshiori.nim

You also may be able to use gcc or some other compilers.

for common case
=============

This module treats raw bytes as cstring so you must alloc/dealloc them, that is not safe operation.

You can use `shioridll-utf8 <https://github.com/Narazaka/shioridll-utf8-nim>`_ module for more safe and convenient shiori making.


]##

when defined(windows):
  import winlean
  type MemoryHandle = Handle
  proc GlobalAlloc(uFlags: cuint, dwBytes: Natural): Handle {.importc,header:"<windows.h>".}
  proc GlobalFree(hMem: Handle): Handle {.importc,header:"<windows.h>".}
  const GMEM_FIXED: cuint = 0x0
  proc shioriAlloc(size: Natural): MemoryHandle {.inline.} = GlobalAlloc(GMEM_FIXED, size)
  proc shioriFree(p: MemoryHandle): void {.inline.} = discard GlobalFree(p)
else:
  type MemoryHandle = ptr cchar
  proc shioriAlloc(size: Natural): MemoryHandle {.inline.} = cast[ptr cchar](alloc(size))
  proc shioriFree(p: MemoryHandle): void {.inline.} = dealloc(p)

var shioriLoadCallback*: proc(dirpath: cstring): bool ## SHIORI load()
var shioriRequestCallback*: proc(requestStr: cstring): cstring ## SHIORI request()
var shioriUnloadCallback*: proc(): bool ## SHIORI unload()

proc load(h: MemoryHandle, len: clong): bool {.cdecl,exportc,dynlib.} =
  var dirpathStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * (len + 1)))
  copyMem(dirpathStrPtr, cast[cstring](h), len)
  shioriFree(h)
  dirpathStrPtr[len] = '\0'
  shioriLoadCallback(dirpathStrPtr)

proc unload(): bool {.cdecl,exportc,dynlib.} =
  shioriUnloadCallback()

proc request(h: MemoryHandle, len: ptr clong): MemoryHandle {.cdecl,exportc,dynlib.} =
  var requestStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * (len[] + 1)))
  copyMem(requestStrPtr, cast[cstring](h), len[])
  shioriFree(h)
  requestStrPtr[len[]] = '\0'
  let responseStrPtr = shioriRequestCallback(requestStrPtr)
  len[] = cast[clong](responseStrPtr.len())
  var reth = shioriAlloc(sizeof(char) * len[])
  copyMem(cast[pointer](reth), responseStrPtr, len[])
  dealloc(responseStrPtr)
  reth

# for test
when appType != "lib":
  proc main*(dirpathStr: string, requestStrs: seq[string]): void =
    ## performs load() request()s unload() for test
    ##
    ## this will removed when --app:lib
    let dirpathStrLen = dirpathStr.len()
    var dirpathStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * dirpathStrLen))
    copyMem(dirpathStrPtr, cstring(dirpathStr), dirpathStrLen)
    echo "--\nload(" & dirpathStr & ")"
    echo "result = " & $load(cast[MemoryHandle](dirpathStrPtr), cast[clong](dirpathStrLen))

    for requestStr in requestStrs:
      let requestStrLen = requestStr.len()
      var requestStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * requestStrLen))
      copyMem(requestStrPtr, cstring(requestStr), requestStrLen)
      var len: ptr clong = cast[ptr clong](alloc(sizeof(clong)))
      len[] = cast[clong](requestStrLen)
      echo "--\nrequest(" & requestStr & ", " & $requestStrLen & ")"
      var responseStrPtr = request(cast[MemoryHandle](requestStrPtr), len)
      var responseStrPtr2: cstring = cast[cstring](alloc(sizeof(cchar) * (len[] + 1)))
      copyMem(responseStrPtr2, cast[cstring](responseStrPtr), len[])
      shioriFree(responseStrPtr)
      responseStrPtr2[len[]] = '\0'
      echo "result = " & $responseStrPtr2

    echo "--\nunload()"
    echo "result = " & $unload()
