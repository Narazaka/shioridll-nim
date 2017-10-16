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

  shioriLoadCallback = proc(str: string): bool =
    true

  shioriRequestCallback = proc(str: string): string =
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

Useful way
=============

You can use `shiori <https://github.com/Narazaka/shiori-nim>`_ module for parsing SHIORI request and building SHIORI response as below...

.. code-block:: Nim
  import shioridll
  import shiori
  import tables

  var dirpath: string

  shioriLoadCallback = proc(dirpathStr: string): bool =
    dirpath = dirpathStr
    return true

  shioriRequestCallback = proc(requestStr: string): string =
    let request = parseRequest(requestStr)
    var response = newResponse(headers = {"Charset": "UTF-8", "Sender": "nimshiori"}.newOrderedTable)
    if request.version != "3.0":
      response.statusCode = 400
      return $response

    case request.id:
      of "name":
        response.value = "nimshiori"
      of "version":
        response.value = "0.0.1"
      of "craftman":
        response.value = "narazaka"
      of "OnBoot":
        response.value = r"\0\s[0]aaaaaa\e"
      else:
        response.status = Status.No_Content

    $response

  shioriUnloadCallback = proc(): bool =
    true

  # for test
  when appType != "lib":
    main("C:\\ssp\\ghost\\nim\\", @[
      "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
      "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
    ])

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

var shioriLoadCallback*: proc(dirpath: string): bool ## SHIORI load()
var shioriRequestCallback*: proc(requestStr: string): string ## SHIORI request()
var shioriUnloadCallback*: proc(): bool ## SHIORI unload()

proc load(h: MemoryHandle, len: clong): bool {.cdecl,exportc,dynlib.} =
  var dirpathStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * (len + 1)))
  copyMem(dirpathStrPtr, cast[cstring](h), len)
  shioriFree(h)
  dirpathStrPtr[len] = '\0'
  let dirpathStr = $dirpathStrPtr
  dealloc(dirpathStrPtr)
  shioriLoadCallback(dirpathStr)

proc unload(): bool {.cdecl,exportc,dynlib.} =
  shioriUnloadCallback()

proc request(h: MemoryHandle, len: ptr clong): MemoryHandle {.cdecl,exportc,dynlib.} =
  var requestStrPtr: cstring = cast[cstring](alloc(sizeof(cchar) * (len[] + 1)))
  copyMem(requestStrPtr, cast[cstring](h), len[])
  shioriFree(h)
  requestStrPtr[len[]] = '\0'
  let requestStr = $requestStrPtr
  dealloc(requestStrPtr)
  let responseStr = cstring(shioriRequestCallback(requestStr))
  len[] = cast[clong](responseStr.len())
  var reth = shioriAlloc(sizeof(char) * len[])
  copyMem(cast[pointer](reth), responseStr, len[])
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
