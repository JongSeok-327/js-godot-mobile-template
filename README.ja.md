# js-godot-mobile-template

[한국어](README.md) · [English](README.en.md) · **日本語**

Godot 4.7.1 で作った 2D 縦画面モバイルゲームのテンプレートです。ゲームの中身は
入っておらず、ゲームを作るたびに毎回書き直すことになる共通部分だけが入っています。

## 入っているもの

ゲームが起動している間ずっと生きていて、どの画面からでも呼び出せる部品です。
Godot では autoload と呼びます。

- **SaveManager** — 進行状況を `user://save.json` に保存して読み込みます。あとで保存
  形式を変えても、古いファイルを新しい形式に移してくれる仕組みが入っています。保存は
  一時ファイルに書き終えてから差し替えるので、書き込み中にアプリが落ちてもファイルは
  壊れません。直前のファイルを `.bak` として残し、本体が壊れたらそこから復旧します。
- **Settings** — 音量、言語、バイブレーションです。セーブとは別のファイルに置いてあるので、進行状況を
  消しても設定は残ります。
- **AudioManager** — BGM は重なりながら切り替わり、効果音は 8 つまで同時に鳴ります。
  一時停止中も音は流れ続けます。広告が画面を覆っている間は BGM を止めます。iOS は
  広告が出てもアプリが止まらないので、別に止める必要があります。
- **SceneManager** — 画面の切り替えです。暗くなってから明るくなります。ファイルパス
  ではなく `"main_menu"` のような名前で呼びます。
- **Services** — 広告と課金が入る場所です。既定では何もせず成功だけを返すダミーが
  差してあります。おかげで Google の SDK をつなぐ前から報酬の受け取りまで試せますし、
  あとで本物をつなぐときもゲーム側のコードは変えずに済みます。本物の広告 SDK を
  つなぐときに守るべき約束（表示できなくても結果は必ず返す、など）は
  `scripts/services/ad_service.gd` に書いてあります。
- **EventBus** — 部品どうしがやり取りするシグナルの集まりです。ここにロジックは
  置きません。
- **DebugTools** — 左下の `DBG` ボタンです。フレームレート、画面へのジャンプ、言語の
  切り替え、セーブの削除ができます。ボタンが増えるとパネルの中でスクロールします。
  リリースビルドではまるごと外れます。

画面は boot → main_menu → game とつながり、その上に一時停止・設定・ゲームオーバーが
重なります。

そのほか:

- TouchController — タップ、長押し、ドラッグ、スワイプを見分けて知らせます
- ObjectPool — 弾のように次々現れては消えるものを、捨てずに使い回します
- 翻訳は ko / en / ja。設定で切り替えると再起動なしでその場で反映されます。空欄や CSV に
  ないキーはテストで引っかかります
- Noto Sans KR/JP フォントを同梱しています。システムフォント任せにすると端末ごとに
  字の形が変わってしまうためです
- Android の戻るボタンは、プレイ中は一時停止、メニューでは終了として動きます
- ホームボタンで出ると自動で保存します。Android はバックグラウンドのアプリを勝手に
  終了させるためです
- export preset は Android のデバッグ・リリース、iOS のリリース・デバッグの四つです。
  iOS ではメインメニューの終了ボタンを隠します。自分で終了するアプリは App Store の
  審査でリジェクトされます

## ツール

- `tools/verify.sh` — スモークテスト、全スクリプトのパースチェック、画面ごとの
  スモークテスト、単体テスト、メモリリークの基準を一度に確かめ、最後の行に `VERDICT: PASS` か `FAIL` を出します。
  GDScript のエラーは終了コード 0 で出るので出力を見る必要があり、それを代わりに
  やってくれます。
- `tools/device.sh` — Android 端末・エミュレータや iPhone 実機にビルドしてインストールし、
  起動します。画面キャプチャ、ログ、アプリデータの取り出しもできます。
- `debug/layout_shots.tscn` — iPhone と Android のいくつかの画面比で各画面を撮ります。
  Apple Silicon の Mac では Godot の iOS シミュレータ向けビルドが動かないので、
  その代わりです。
- `.githooks/pre-commit` — 署名キー、実際の広告キーが入った `config/*.cfg`、Team ID を
  入れた preset がコミットされないようにします。
- `.claude/` — Claude Code 用のスキルとエージェントです。修正 → 検証 → 実機確認 →
  リリース確認の順番を固定したもので、詳しくは [CLAUDE.md](CLAUDE.md) にあります。一部は
  [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) から
  取り入れて手を加えました。

## 入っていないもの

ゲームのロジックです。`scenes/game/game.tscn` の `Gameplay` ノードが空いている場所です。

## 動かす

Godot 4.7.1 が必要です。ほかのバージョンでは開けないことがあります。

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template

godot --headless --path . --import   # 最初の一度だけ
git config core.hooksPath .githooks  # 最初の一度だけ、コミット検査フックを有効にする
godot --path .
```

`--import` はフォントと翻訳を Godot が使う形に変換する作業です。出力が大きく、いつでも
作り直せるのでリポジトリには入れていません。エディタで開けば自動で行われます。

## 上に載せる

- ゲームは `scenes/game/game.tscn` の `Gameplay` の下に作ります。
- 画面を追加したら `autoload/scene_manager.gd` の `SCENES` に登録します。ファイルパスを
  コードのあちこちに直接書くと、ファイルを一つ移すたびに全部探して直すことになります。
- 文字は `locale/translations.csv` に一行足します。三言語が同じ行に入ります。
- 色と角の丸みは `ui/theme/default_theme.tres` の一か所を直せば全体が追随します。
- 公開前にアプリ ID（`com.jsgame.template`、Android と iOS の preset 両方）と
  `icon.svg` を変えます。アプリ ID はストアに一度出すと変更できません。
- 広告キーなどの実際の値は `config/*.cfg` に置きます。リポジトリには `.example` だけを
  入れ、export preset の `include_filter` に `config/*.cfg` を入れないとアプリに
  含まれません。
- iOS の Team ID は自分のマシンの preset にだけ入れ、コミットするときは空にします。

## フォルダ

```
autoload/   常に動いている部品
scenes/     画面とオーバーレイ
ui/         テーマ、使い回す部品
scripts/    広告・課金、タッチ入力、ユーティリティ
debug/      デバッグパネル（リリースビルドでは除外）
locale/     翻訳 csv
assets/     フォント、音、画像
tests/      チェック
tools/      検証、実機インストールのスクリプト
.githooks/  コミット検査
.claude/    Claude Code のスキル・エージェント
```

開発ルールと Android・iOS ビルドの手順は [CLAUDE.md](CLAUDE.md) にあります。

## ライセンス

コードは [MIT](LICENSE) です。同梱の素材はそれぞれのライセンスに従い、原文は各フォルダに
入れてあります。

- 効果音とスライダーのつまみ画像 — [Kenney](https://kenney.nl)、CC0
- Noto Sans KR / JP — Google Fonts、OFL
