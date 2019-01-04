# shioridll

SHIORI.DLLをNim言語で作るためのインターフェースです。

伺かのSHIORIサブシステムを高速で書きやすい汎用言語であるNim言語で作るためのライブラリです。

現状Windowsのみで動作確認しています。ninixとかで動かないと言う事案があればissueとかプルリクにあげてください。

## インストール

### 1. Nim言語をインストール

Nim言語のサイト https://nim-lang.org/install.html からzipを落として展開し、環境変数にPATHを通します。

DLLを32ビット版で作らなければいけない関係上、32ビット版のほうが混乱が少ないかも知れません。
ただ作者の環境では64ビット版でも動きました。

### 2. Cコンパイラーをインストール

[Visual Studio Community](https://visualstudio.microsoft.com/ja/vs/community/)をインストールしてください。
インストール時には「C++によるデスクトップ開発」がオンになっていることを確認してください。

Communityは無料版ですが有料版を既に持っていたらそちらで大丈夫です。
少なくともVS2017でコンパイルできることを確認していますが、2015などでもいけるのではないかと思います。

gccでも動くようです（このライブラリとしては未検証）。mingw32をダウンロードして展開してパス通して下さい。mingw64だと上手くいかないっぽいです。

なお作者はVisual Studio Communityを使ってなんとかしました。
とりあえずnimとvcまたはgccが動く状態にして下さい。

### 2. ライブラリをインストール

このライブラリと同時にSHIORIプロトコルを取り扱う[shiori](https://github.com/Narazaka/shiori-nim)ライブラリ、
及び文字コードを自動でUTF-8に変換してくれる[shiori_charset_convert](https://github.com/Narazaka/shiori_charset_convert-nim)ライブラリを使うと便利です。

```
nimble install shioridll
nimble install shiori
```

## SHIORI.DLLの作り方

### コードを書く

myshiori.nim等の名前(shiori.nimはライブラリとかぶるので不可？)でこんな感じに書きます。

```nim
import shioridll
import shiori
import shiori_charset_convert
import tables

var dirpath: string

shioriLoadCallback = proc(dirpathStr: string): bool =
  # SHIORI load()
  # 各種前処理等を行って下さい
  dirpath = dirpathStr
  true

# autoConvertShioriMessageCharset()はベースウェアからのリクエストをUTF-8に変換してくれます。
# またレスポンスをベースウェアに渡す前にCharsetヘッダに書かれた文字コードに変換してくれます。
shioriRequestCallback = autoConvertShioriMessageCharset(proc(requestStr: string): string =
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
      response.value = "myshiori" # 栞名 (必ず返す)
    of "version":
      response.value = "0.0.1" # 栞バージョン (必ず返す)
    of "craftman":
      response.value = "me" # 栞作者 (必ず返す)
    of "craftmanw":
      response.value = "私" # 栞作者日本語 (必ず返す)
    of "OnBoot":
      response.value = r"\0\s[0]aaaaaa\e" # OnBootとか
    else:
      response.status = Status.No_Content

  $response
)

shioriUnloadCallback = proc(): bool =
  # SHIORI unload()
  # 各種後処理等を行って下さい
  true

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

#### Visual Studioの場合

スタートメニューのVisual Studioの下にある「開発者コマンド プロンプト for VS 2017」あるいは「Developer Command Prompt for VS 2017」を開いてその中で作業します（2017のところは適宜読み替え下さい）。

そのコマンド上でソースのある所までフォルダ移動し、以下のコマンドを叩きます。

--app:libがdllを作る指定、-d:releaseがリリース版（つけないとデバッグ版）、--cc:vccがVisual Studioのclコンパイラを使う指定（つけないとgcc）、--cpu:i386が32ビット版指定です。
```
nim c --app:lib -d:release --cc:vcc --cpu:i386 myshiori.nim
```

#### GCCの場合

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

このライブラリ自体にはほとんど意味が無いですが、APIドキュメントはこちらです。
型とかに困ったらこちらを見て下さい。

**[API Document](https://narazaka.github.io/shioridll-nim/)**

どちらかというと[shiori](https://github.com/Narazaka/shiori-nim)ライブラリのAPI Documentの方を良く参照することになると思います。

またエディタはVisual Studio Codeに拡張機能Nimを入れるのがとりあえずおすすめです。
ただしばらく書いていると補完が効かなくなったりする時があるので、立ち上げ直したりしてました。
別の良いエディタがあればそちらでも良いかと思います。

## ライセンス

このライブラリは[MITライセンス](https://narazaka.net/license/MIT?2017)です。

が、伺かの栞を作る用途においては、別にライセンステキストを含めるとかしなくてもかまいません。めんどくさいので。
