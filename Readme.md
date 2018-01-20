# shioridll

The SHIORI DLL interface for Nim lang

## Install

```
nimble install shioridll
```

## Usage

**[API Document](https://narazaka.github.io/shioridll-nim/)**

### How to make SHIORI.DLL

write your myshiori.nim like below...

```nim
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
```

then make 32bit dll...

```
nim c --app:lib -d:release --cc:vcc --cpu:i386 myshiori.nim
```

You also may be able to use gcc or some other compilers.

### for common case

This module treats raw bytes as cstring so you must alloc/dealloc them, that is not safe operation.

You can use [shioridll-utf8](https://github.com/Narazaka/shioridll-utf8-nim) module for more safe and convenient shiori making.

## License

This is released under [MIT License](https://narazaka.net/license/MIT?2018).
