# js-godot-mobile-template

**한국어** · [English](README.en.md) · [日本語](README.ja.md)

Godot 4.7.1로 만든 2D 세로 모바일 게임 템플릿입니다. 게임 내용은 들어있지 않고,
게임을 만들 때마다 매번 다시 짜게 되는 공통 부분만 들어있습니다.

## 들어있는 것

게임이 켜져 있는 동안 계속 살아있으면서 어느 화면에서든 부를 수 있는 부품들입니다.
Godot에서는 autoload라고 합니다.

- **SaveManager** — 진행 상황을 `user://save.json`에 저장하고 읽습니다. 나중에 저장
  형식을 바꿔도 예전 파일을 새 형식으로 옮겨주는 장치가 들어있습니다.
- **Settings** — 음량과 언어입니다. 세이브와 다른 파일에 넣어서, 진행 기록을 지워도
  설정은 남습니다.
- **AudioManager** — 배경음악은 겹치면서 바뀌고 효과음은 8개까지 동시에 납니다.
  일시정지 중에도 소리는 계속 나옵니다.
- **SceneManager** — 화면 전환입니다. 어두워졌다 밝아집니다. 파일 경로 대신
  `"main_menu"` 같은 이름으로 부릅니다.
- **Services** — 광고와 결제가 들어갈 자리입니다. 기본으로는 아무것도 안 하고
  성공했다고만 답하는 가짜가 끼워져 있습니다. 덕분에 구글 SDK를 붙이기 전에도 보상
  지급까지 눌러볼 수 있고, 나중에 진짜를 붙일 때 게임 쪽 코드는 안 고쳐도 됩니다.
- **EventBus** — 부품끼리 주고받는 신호 모음입니다. 여기엔 로직을 두지 않습니다.
- **DebugTools** — 왼쪽 아래 `DBG` 버튼입니다. 프레임 수, 화면 점프, 언어 순환,
  세이브 삭제를 할 수 있습니다. 출시용으로 빌드하면 통째로 빠집니다.

화면은 boot → main_menu → game 순으로 이어지고, 그 위에 일시정지·설정·게임오버가
겹쳐 뜹니다.

그 밖에:

- TouchController — 탭, 롱프레스, 드래그, 스와이프를 구분해서 알려줍니다
- ObjectPool — 총알처럼 계속 생겼다 없어지는 것을 버리지 않고 재사용합니다
- 번역 ko / en / ja. 설정에서 바꾸면 껐다 켤 필요 없이 그 자리에서 바뀝니다
- Noto Sans KR/JP 폰트가 들어있습니다. 시스템 폰트에 맡기면 기기마다 글자 모양이
  달라집니다
- 안드로이드 뒤로가기는 게임에서 일시정지, 메뉴에서 종료로 동작합니다
- 홈으로 나가면 자동 저장합니다. 안드로이드는 백그라운드에 있는 앱을 마음대로
  꺼버리기 때문입니다

## 없는 것

게임 로직입니다. `scenes/game/game.tscn`의 `Gameplay` 노드가 비어있는 자리입니다.

## 실행

Godot 4.7.1이 필요합니다. 다른 버전에서는 안 열릴 수 있습니다.

```bash
git clone https://github.com/JongSeok-327/js-godot-mobile-template.git
cd js-godot-mobile-template

godot --headless --path . --import   # 처음 한 번
godot --path .
```

`--import`는 폰트와 번역을 Godot이 쓰는 형태로 바꾸는 작업입니다. 결과물이 크고
언제든 다시 만들 수 있어서 저장소에 넣지 않았습니다. 에디터로 열면 자동으로 처리됩니다.

## 얹는 법

- 게임은 `scenes/game/game.tscn`의 `Gameplay` 아래에 만듭니다.
- 화면을 추가했으면 `autoload/scene_manager.gd`의 `SCENES`에 등록합니다. 파일 경로를
  코드 곳곳에 직접 쓰면 나중에 파일 하나 옮길 때 전부 찾아 고쳐야 합니다.
- 글자는 `locale/translations.csv`에 한 줄 추가합니다. 세 언어가 같은 줄에 들어갑니다.
- 색과 모서리는 `ui/theme/default_theme.tres` 한 곳만 고치면 전체가 따라옵니다.
- 출시 전에 앱 ID(`com.jsgame.template`)와 `icon.svg`를 바꿉니다. 앱 ID는 스토어에
  한 번 올리면 못 바꿉니다.

## 폴더

```
autoload/   항상 떠 있는 부품
scenes/     화면과 오버레이
ui/         테마, 재사용 컴포넌트
scripts/    광고·결제, 터치 입력, 유틸
debug/      디버그 패널 (출시 빌드에서 제외)
locale/     번역 csv
assets/     폰트, 소리, 이미지
tests/      검사
```

개발 규칙과 안드로이드 빌드 방법은 [CLAUDE.md](CLAUDE.md)에 있습니다.

## 라이선스

코드는 [MIT](LICENSE)입니다. 같이 든 소재는 각자 라이선스를 따르고, 원문은 해당
폴더에 있습니다.

- 효과음과 슬라이더 손잡이 이미지 — [Kenney](https://kenney.nl), CC0
- Noto Sans KR / JP — Google Fonts, OFL
