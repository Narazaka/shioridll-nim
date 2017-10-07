# shioridll

SHIORI.DLLをNim言語で作るためのインターフェースです。

伺かのSHIORIサブシステムを高速で書きやすい汎用言語であるNim言語で作るためのライブラリです。

現状Windowsのみで動作確認しています。ninixとかで動かないと言う事案があればissueとかプルリクにあげてください。

## インストール

### 1. Nim言語をインストール

Nim言語のサイト https://nim-lang.org/install.html からzipを落として展開します。

DLLを32ビット版で作らなければいけない関係上、32ビット版のほうが混乱が少ないかも知れません。
ただ作者の環境では64ビット版でも動きました。

またgccが必要ならmingw32の方もダウンロードして展開してパス通して下さい。
こちらは少なくともmingw64だと上手くいかないっぽいです。

なお作者はVisual Studio Communityのclを使ってなんとかしました。

とりあえずnimとgccまたはvcが動く状態にして下さい。

### 2. ライブラリをインストール

```
# このライブラリ
nimble install shioridll
# SHIORIプロトコルを取り扱うライブラリ
nimble install shiori
```

## SHIORI.DLLの作り方

### コードを書く

myshiori.nim等の名前(shiori.nimはライブラリとかぶるので不可？)でこんな感じに書きます。

```nim
import shioridll
import shiori
import tables

var dirpath: string

shioriLoadCallback = proc(dirpathStr: string): bool =
  # SHIORI load()
  # 各種前処理等を行って下さい
  dirpath = dirpathStr
  return true

shioriRequestCallback = proc(requestStr: string): string =
  # SHIORI request()
  # メインのSHIORIプロトコル通信処理部分です

  # リクエストをパース
  let request = parseRequest(requestStr)

  # レスポンスを作る
  var response = newResponse(headers = {"Charset": "UTF-8", "Sender": "nimshiori"}.newOrderedTable)

  # SHIORI/3.0通信でなければ弾く
  if request.version != "3.0":
    response.statusCode = 400
    return $response

  # SHIORI/3.0リクエストのIDによる分岐
  # ここがゴーストを形作るものになるので、色々やってみて下さい。
  # requestとresponseの詳細はshioriライブラリのAPIドキュメントをご覧下さい。
  case request.id:
    of "name":
      response.value = "nimshiori" # 栞名 (必ず返す)
    of "version":
      response.value = "0.0.1" # 栞バージョン (必ず返す)
    of "craftman":
      response.value = "narazaka" # 栞作者 (必ず返す)
    of "craftmanw":
      response.value = "奈良阪" # 栞作者日本語 (必ず返す)
    of "OnBoot":
      response.value = r"\0\s[0]aaaaaa\e" # OnBootとか
    else:
      response.status = Status.No_Content

  return $response

shioriUnloadCallback = proc(): bool =
  # SHIORI unload()
  # 各種後処理等を行って下さい
  return true

# テストの時に与えたいリクエスト
when appType != "lib":
  main("C:\\ssp\\ghost\\nim\\", @[
    "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
    "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
  ])
```

### コンパイル

これが出来たら以下のように**32ビットのDLL**にコンパイルして下さい。
64ビットにしてしまうと読み込めません。

--app:libがdllを作る指定、-d:releaseがリリース版（つけないとデバッグ版）、--cc:vccがVisual Studioのclコンパイラを使う指定（つけないとgcc）、--cpu:i386が32ビット版指定です。
```
nim c --app:lib -d:release --cc:vcc --cpu:i386 myshiori.nim
```

gccの場合は-tとか-mとかもつけるらしいですが、これで試してないのでもし成功した人が居れば書き換えプルリク下さい。
```
nim c --app:lib -d:release --cpu:i386 -t:-m32 -l:-m32 myshiori.nim
```

もしdllがロード失敗する場合、[shioricaller](https://github.com/Narazaka/shioricaller)等を使ってエラーを探ってみると良いかも知れません。

### 簡易デバッグ

テスト中、SSP等を使わずに簡易に確認したい場合は、

```
nim c --cc:vcc myshiori.nim
```

あるいは

```
nim c myshiori.nim
```

などとすると、main()に与えたリクエストでテストが出来ます。

### リリース

無事DLLが出来れば、ゴーストに含めて必要に応じてdescript.txtを書くなどして下さい。

高速で書きやすいNim言語によって、既存の制約にとらわれない様々なゴーストなどが生まれることを願っています。

## 補足

ほとんど情報無いですがAPIドキュメントはこちらです。
型とかに困ったらこちらを見て下さい。

**[API Document](https://narazaka.github.io/shioridll-nim/)**

またエディタはVisual Studio Codeに拡張機能Nimを入れるのがとりあえずおすすめです。
ただしばらく書いていると補完が効かなくなったりする時があるので、立ち上げ直したりしてました。
別の良いエディタがあればそちらでも良いかと思います。

## ライセンス

このライブラリは[MITライセンス](https://narazaka.net/license/MIT?2017)です。

が、伺かの栞を作る用途においては、別にライセンステキストを含めるとかしなくてもかまいません。めんどくさいので。
