# js-godot-mobile-template

[한국어](README.md) · **English** · [日本語](README.ja.md)

A 2D portrait mobile game template built with Godot 4.7.1. It contains no game content —
only the common parts you end up rewriting for every game.

## What's in it

Parts that stay alive the whole time the game is running and can be called from any
screen. Godot calls these autoloads.

- **SaveManager** — Saves progress to `user://save.json` and reads it back. It includes
  machinery that migrates old files to the new format if you change the save format later.
  Saves are written to a temporary file and then swapped in, so the file survives the app
  being killed mid-write, and the previous file is kept as `.bak` to recover from if the
  main one is ever corrupted.
- **Settings** — Volume, language, and vibration. Kept in a separate file from your save, so wiping
  progress leaves settings intact.
- **AudioManager** — Music crossfades instead of cutting off, and up to 8 sound effects
  play at once. Audio keeps running while the game is paused. Music pauses while an ad
  covers the screen; iOS doesn't suspend the app for ads, so this has to be done by hand.
- **SceneManager** — Screen transitions, fading through black. Screens are called by name
  like `"main_menu"` rather than by file path.
- **Services** — The slot where ads and purchases go. By default a stub is plugged in that
  does nothing and just reports success. That lets you click through reward payouts before
  attaching Google's SDK, and when you attach the real thing, game code doesn't change.
  The rules a real ad SDK implementation has to follow (always report a result, even when
  no ad could be shown, and so on) are written in `scripts/services/ad_service.gd`.
- **EventBus** — A collection of global signals. No logic lives here.
- **DebugTools** — The `DBG` button in the bottom-left: frame rate, jump to any screen,
  cycle languages, wipe save data. The panel scrolls once it has too many buttons. It's
  dropped entirely from release builds.

Screens run boot → main_menu → game, with pause, settings, and game over layered on top.

Also included:

- TouchController — tells tap, long press, drag, and swipe apart
- ObjectPool — reuses objects that appear and disappear constantly, like bullets
- Translations in ko / en / ja, switching instantly without a restart. Empty cells and keys
  missing from the CSV fail the tests
- Noto Sans KR/JP fonts, because leaving it to system fonts means different letterforms on
  every device
- Android back button pauses during gameplay and quits from the menu
- Leaving via the home button saves automatically, since Android kills backgrounded apps
  whenever it likes
- Four export presets: Android debug and release, iOS release and debug. On iOS the quit
  button on the main menu is hidden, because apps that close themselves get rejected in
  App Store review

## Tools

- `tools/verify.sh` — Runs the smoke test, a parse check of every script, a smoke test per
  screen, the unit tests, and a memory leak check, and ends with `VERDICT: PASS` or `FAIL`.
  GDScript errors exit with code 0, so the output has to be read; this does that for you.
- `tools/device.sh` — Builds, installs, and launches on an Android device or emulator, or
  on a real iPhone. It can also take screenshots, read logs, and pull app data.
- `debug/layout_shots.tscn` — Captures every screen at a range of iPhone and Android
  aspect ratios. Godot's iOS simulator build doesn't run on Apple Silicon Macs, so this
  stands in for it.
- `.githooks/pre-commit` — Blocks commits of signing keys, `config/*.cfg` files holding
  real ad keys, and presets with a Team ID filled in.
- `.claude/` — Skills and agents for Claude Code that fix the order of change → verify →
  device check → release check. Details are in [CLAUDE.md](CLAUDE.md). Some of it is adapted
  from [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios).

## What's not in it

Game logic. The `Gameplay` node in `scenes/game/game.tscn` is the empty slot.

## Running it

Godot 4.7.1 is required. Other versions may not open it.

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template

godot --headless --path . --import   # once, the first time
git config core.hooksPath .githooks  # once, turns on the commit check hook
godot --path .
```

`--import` converts fonts and translations into the form Godot uses. The output is large
and can be regenerated any time, so it isn't stored in the repository. Opening the project
in the editor does this for you.

## Building on it

- Put your game under `Gameplay` in `scenes/game/game.tscn`.
- Register any new screen in `SCENES` in `autoload/scene_manager.gd`. Writing file paths
  throughout your code means hunting down every one when you move a file.
- Add text as a row in `locale/translations.csv`. All three languages go on the same row.
- Colors and corner rounding live in `ui/theme/default_theme.tres`; change them there and
  everything follows.
- Before release, change the app ID (`com.jsgame.template`, in both the Android and iOS
  presets) and `icon.svg`. The app ID can't be changed once it's published to a store.
- Keep real values such as ad keys in `config/*.cfg`. Only the `.example` files go in the
  repository, and `config/*.cfg` has to be in the export preset's `include_filter` to end
  up in the app.
- Put your iOS Team ID only in the preset on your own machine, and leave it empty when
  committing.

## Layout

```
autoload/   parts that are always running
scenes/     screens and overlays
ui/         theme, reusable components
scripts/    ads/purchases, touch input, utilities
debug/      debug panel (excluded from release builds)
locale/     translation csv
assets/     fonts, sounds, images
tests/      checks
tools/      verification and device install scripts
.githooks/  commit checks
.claude/    Claude Code skills and agents
```

Development rules and Android/iOS build instructions are in [CLAUDE.md](CLAUDE.md).

## License

The code is [MIT](LICENSE). Bundled assets keep their own licenses, with the original texts
in their folders.

- Sound effect and slider grabber image — [Kenney](https://kenney.nl), CC0
- Noto Sans KR / JP — Google Fonts, OFL
