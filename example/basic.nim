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
