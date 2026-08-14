# js-godot-mobile-template

[한국어](README.md) · **English** · [日本語](README.ja.md)

A 2D portrait mobile game template built with Godot 4.7.1. It contains no game content —
only the common parts you end up rewriting for every game.

## What's in it

Parts that stay alive the whole time the game is running and can be called from any
screen. Godot calls these autoloads.

- **SaveManager** — Saves progress to `user://save.json` and reads it back. It includes
  machinery that migrates old files to the new format if you change the save format later.
- **Settings** — Volume and language. Kept in a separate file from your save, so wiping
  progress leaves settings intact.
- **AudioManager** — Music crossfades instead of cutting off, and up to 8 sound effects
  play at once. Audio keeps running while the game is paused.
- **SceneManager** — Screen transitions, fading through black. Screens are called by name
  like `"main_menu"` rather than by file path.
- **Services** — The slot where ads and purchases go. By default a stub is plugged in that
  does nothing and just reports success. That lets you click through reward payouts before
  attaching Google's SDK, and when you attach the real thing, game code doesn't change.
- **EventBus** — A collection of global signals. No logic lives here.
- **DebugTools** — The `DBG` button in the bottom-left: frame rate, jump to any screen,
  cycle languages, wipe save data. It's dropped entirely from release builds.

Screens run boot → main_menu → game, with pause, settings, and game over layered on top.

Also included:

- TouchController — tells tap, long press, drag, and swipe apart
- ObjectPool — reuses objects that appear and disappear constantly, like bullets
- Translations in ko / en / ja, switching instantly without a restart
- Noto Sans KR/JP fonts, because leaving it to system fonts means different letterforms on
  every device
- Android back button pauses during gameplay and quits from the menu
- Leaving via the home button saves automatically, since Android kills backgrounded apps
  whenever it likes

## What's not in it

Game logic. The `Gameplay` node in `scenes/game/game.tscn` is the empty slot.

## Running it

Godot 4.7.1 is required. Other versions may not open it.

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template

godot --headless --path . --import   # once, the first time
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
- Before release, change the app ID (`com.jsgame.template`) and `icon.svg`. The app ID
  can't be changed once it's published to a store.

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
```

Development rules and Android build instructions are in [CLAUDE.md](CLAUDE.md).

## License

The code is [MIT](LICENSE). Bundled assets keep their own licenses, with the original texts
in their folders.

- Sound effect and slider grabber image — [Kenney](https://kenney.nl), CC0
- Noto Sans KR / JP — Google Fonts, OFL
