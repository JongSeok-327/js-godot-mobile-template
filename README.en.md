# JS Godot Mobile Game Template

[한국어](README.md) · **English** · [日本語](README.ja.md)

A Godot project where **everything except the game itself is already built**, so you can
just drop your game in.

---

## Why would you want this?

Making a game means building a lot of things that aren't the game.

- The title screen and its buttons
- A settings menu for adjusting volume
- Saving your progress and loading it back
- Pausing mid-game
- Switching between Korean / English / Japanese
- Screens that fade smoothly instead of snapping

The catch is that **these are nearly identical in every game you make**. Rebuilding them
from scratch each time is wasted effort.

Think of building a house: this project is **an empty house with the frame up and the
wiring and plumbing already run**. All that's left is picking wallpaper and moving in
furniture — that is, the actual game.

## Current state

- **The game itself is empty.** That's the part you fill in.
- Everything listed above is built and working.
- It's been installed and launched on Android to confirm it really runs.
- 121 automated checks pass.

---

## What's inside?

### Parts that are always running

These stay alive from the moment the game starts until it closes, and any screen can call
on them. (Godot calls these **autoloads**.)

| Name | What it does |
|---|---|
| **SaveManager** | Saves your progress to a file and loads it back. It includes machinery that **converts old save files to the new format automatically** if the format ever changes. |
| **Settings** | Remembers volume and language. Kept in a **separate** file from your save data, so wiping your progress doesn't reset your settings. |
| **AudioManager** | Handles music and sound effects. When music changes, tracks overlap and fade rather than cutting off. Music keeps playing while the game is paused. |
| **SceneManager** | Handles screen changes — the screen darkens and brightens as it moves. |
| **Services** | A **placeholder** for ads and purchases. More on this below. |
| **EventBus** | A channel for parts to send news to each other. More on this below. |
| **DebugTools** | A developer panel that only appears while developing. More on this below. |

### Screens

Splash → main menu → game screen are already wired together, along with the panels that
appear on top of them (pause, settings, game over).

### Everything else

- **Touch input** — distinguishes tap, long press, drag, and swipe for you.
- **Korean / English / Japanese** — switching in settings takes effect immediately, no restart.
- **CJK fonts bundled** — without shipping the fonts, letters look different on every device.
- **ObjectPool** — **recycles** objects that appear and disappear constantly, like bullets, instead of throwing them away. Constantly creating new ones makes the game stutter.
- **Android back button** — pauses during gameplay, quits from the menu.
- **When you leave via the home button** — it pauses and saves automatically. Android can kill a backgrounded app at any moment, so anything not saved on the way out is lost.

---

## A few concepts explained

### EventBus — parts talking to each other

Say several parts need to know that the game is over. If you make them call each other
directly, they get tangled like a spiderweb, and later a single change breaks things
everywhere.

So there's a **bulletin board**. Anything worth announcing gets posted, and whoever cares
subscribes. Neither side needs to know the other exists.

### Services — a fake version of ads and purchases

Ads and in-app purchases only work for real once you attach separate software from Google.
That's fiddly to set up, and until you do, you can't test any of it.

So there's a **fake version that does nothing and simply reports success**. Press "watch an
ad for a reward" and the reward arrives immediately, no ad. That lets you test the whole
game flow start to finish before real ads exist.

When you do attach real ads later, **you won't change a single line of game code** — you
swap the fake for the real one.

### DebugTools — the developer panel

Press the `DBG` button in the bottom-left corner. You get a frame rate readout, jump-to-any-screen,
language switching, and a button to wipe save data.

**This panel is removed entirely from release builds.** That removal has been verified.

---

## Getting started

### 1. Install Godot

Get version **4.7.1** from [godotengine.org](https://godotengine.org). Other versions may
not work.

### 2. Clone

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template
```

### 3. First-time setup (once, and it's required)

```bash
GODOT=/Applications/Godot_4.7.1.app/Contents/MacOS/Godot   # your install path

"$GODOT" --headless --path . --import
```

**Why?** Files like fonts and translations have to be converted once into a form Godot can
use. Those converted files are large and can be regenerated any time, so they aren't stored
in the repository. You generate them yourself after cloning.

Opening the project in the editor does this automatically too.

### 4. Run

```bash
"$GODOT" --path .            # run the game
"$GODOT" --path . --editor   # open the editor
./tests/run_all.sh           # run the checks
```

---

## Building your own game on it

1. **Add your gameplay.** Open `scenes/game/game.tscn` and you'll find an empty
   `Gameplay` slot. Build under it.
2. **If you add a new screen,** register its name in the `SCENES` list in
   `autoload/scene_manager.gd`. Don't write screen file paths directly throughout your code —
   move a file later and you'll have to hunt down every one.
3. **To add text,** add a row to `locale/translations.csv`. All three languages go on the
   same row.
4. **To restyle,** change the colors and corner rounding in `ui/theme/default_theme.tres`
   and the whole app follows.
5. **Before release,** change the app ID (`com.jsgame.template`) and the icon (`icon.svg`).
   ⚠️ The app ID **can never be changed once published to a store.**

---

## Folder layout

```
autoload/   parts that are always running
scenes/     screens (splash, menu, game, overlay panels)
ui/         design theme, reusable pieces
scripts/    ad/purchase placeholders, touch input, utilities
debug/      debug panel (excluded from release builds)
locale/     translation file
assets/     fonts, sounds, images
tests/      automated checks
```

Detailed development rules and Android build instructions live in [`CLAUDE.md`](CLAUDE.md).

---

## License

The code in this project is under the [MIT License](LICENSE). Use it, change it, sell it.

The bundled assets keep their own licenses. All three are fine for commercial use, and the
original license texts are included in their folders.

| Asset | Source | License |
|---|---|---|
| Sound effect, slider grabber image | [Kenney](https://kenney.nl) | CC0 (public domain) |
| Noto Sans KR / JP fonts | Google Fonts | OFL |
