# shioridll

The SHIORI DLL interface for Nim lang

## Install

```
nimble install shioridll
```

## Usage

**[API Document](https://narazaka.github.io/shioridll-nim/)**

[日本語チュートリアル](Tutorial.ja.md)

### How to make SHIORI.DLL

write your myshiori.nim like below...

```nim
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
```

then make 32bit dll...

```
nim c --app:lib -d:release --cc:vcc --cpu:i386 myshiori.nim
```

You also may be able to use gcc or some other compilers.

### Useful way

You can use [shiori](https://github.com/Narazaka/shiori-nim) module for parsing SHIORI request and building SHIORI response
and can use [shiori_charset_convert](https://github.com/Narazaka/shiori_charset_convert-nim) module for auto converting charset
as below...

```nim
import shioridll
import shiori
import shiori_charset_convert
import tables

var dirpath: string

shioriLoadCallback = proc(dirpathStr: string): bool =
  dirpath = dirpathStr
  true

shioriRequestCallback = autoConvertShioriMessageCharset(proc(requestStr: string): string =
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
)

shioriUnloadCallback = proc(): bool =
  true

# for test
when appType != "lib":
  main("C:\\ssp\\ghost\\nim\\", @[
    "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
    "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
  ])
```

## License

This is released under [MIT License](https://narazaka.net/license/MIT?2017).
