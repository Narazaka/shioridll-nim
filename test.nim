import std/unittest
import ./shioridll.nim as  shioridll

suite "main":
  test "success when function defined":
    shioriLoadCallback = proc(dirpath: string): bool = true
    shioriUnloadCallback = proc(): bool = true
    shioriRequestCallback = proc(requestStr: string) : string = "SAORI/1.0 200 OK\r\nResult:1\r\nCharset:UTF-8\r\n\r\n"
    let
      casePath = "C:/"
      caseRequest = @["GET Version SAORI/1.0\r\nSecurityLevel: External\r\n\r\n\0"]
    shioridll.main(casePath, caseRequest)
