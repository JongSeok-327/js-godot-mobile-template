# js-godot-mobile-template

[한국어](README.md) · [English](README.en.md) · **日本語**

Godot 4.7.1 で作った 2D 縦画面モバイルゲームのテンプレートです。ゲームの中身は
入っておらず、ゲームを作るたびに毎回書き直すことになる共通部分だけが入っています。

## 入っているもの

ゲームが起動している間ずっと生きていて、どの画面からでも呼び出せる部品です。
Godot では autoload と呼びます。

- **SaveManager** — 進行状況を `user://save.json` に保存して読み込みます。あとで保存
  形式を変えても、古いファイルを新しい形式に移してくれる仕組みが入っています。
- **Settings** — 音量と言語です。セーブとは別のファイルに置いてあるので、進行状況を
  消しても設定は残ります。
- **AudioManager** — BGM は重なりながら切り替わり、効果音は 8 つまで同時に鳴ります。
  一時停止中も音は流れ続けます。
- **SceneManager** — 画面の切り替えです。暗くなってから明るくなります。ファイルパス
  ではなく `"main_menu"` のような名前で呼びます。
- **Services** — 広告と課金が入る場所です。既定では何もせず成功だけを返すダミーが
  差してあります。おかげで Google の SDK をつなぐ前から報酬の受け取りまで試せますし、
  あとで本物をつなぐときもゲーム側のコードは変えずに済みます。
- **EventBus** — 部品どうしがやり取りするシグナルの集まりです。ここにロジックは
  置きません。
- **DebugTools** — 左下の `DBG` ボタンです。フレームレート、画面へのジャンプ、言語の
  切り替え、セーブの削除ができます。リリースビルドではまるごと外れます。

画面は boot → main_menu → game とつながり、その上に一時停止・設定・ゲームオーバーが
重なります。

そのほか:

- TouchController — タップ、長押し、ドラッグ、スワイプを見分けて知らせます
- ObjectPool — 弾のように次々現れては消えるものを、捨てずに使い回します
- 翻訳は ko / en / ja。設定で切り替えると再起動なしでその場で反映されます
- Noto Sans KR/JP フォントを同梱しています。システムフォント任せにすると端末ごとに
  字の形が変わってしまうためです
- Android の戻るボタンは、プレイ中は一時停止、メニューでは終了として動きます
- ホームボタンで出ると自動で保存します。Android はバックグラウンドのアプリを勝手に
  終了させるためです

## 入っていないもの

ゲームのロジックです。`scenes/game/game.tscn` の `Gameplay` ノードが空いている場所です。

## 動かす

Godot 4.7.1 が必要です。ほかのバージョンでは開けないことがあります。

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template

godot --headless --path . --import   # 最初の一度だけ
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
- 公開前にアプリ ID（`com.jsgame.template`）と `icon.svg` を変えます。アプリ ID は
  ストアに一度出すと変更できません。

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
```

開発ルールと Android ビルドの手順は [CLAUDE.md](CLAUDE.md) にあります。

## ライセンス

コードは [MIT](LICENSE) です。同梱の素材はそれぞれのライセンスに従い、原文は各フォルダに
入れてあります。

- 効果音とスライダーのつまみ画像 — [Kenney](https://kenney.nl)、CC0
- Noto Sans KR / JP — Google Fonts、OFL
