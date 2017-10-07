doc/index.html: shioridll.nim
	nim doc -o:doc/index.html shioridll.nim

basic:
	nim c -r -p:. example/basic.nim
useful:
	nim c -r -p:. example/useful.nim
