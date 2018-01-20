doc/index.html: shioridll.nim
	nim doc -o:doc/index.html shioridll.nim

basic:
	nim c -r -p:. example/basic.nim
basicvc:
	nim c -r -p:. --cc:vcc example/basic.nim
basicdll:
	cd example && nim c -p:.. --cc:vcc --app:lib -d:release --cpu:i386 basic.nim
useful:
	nim c -r -p:. example/useful.nim
usefulvc:
	nim c -r -p:. --cc:vcc example/useful.nim
usefuldll:
	cd example && nim c -p:.. --cc:vcc --app:lib -d:release --cpu:i386 useful.nim

clean:
	cd example && rm -rf nimcache *.exe *.lib *.exp *.ilk *.pdb *.dll
