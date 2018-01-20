import shioridll
import shiori
import tables

var dirpath: string

shioriLoadCallback = proc(dirpathStr: string): bool =
  dirpath = dirpathStr
  true

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
