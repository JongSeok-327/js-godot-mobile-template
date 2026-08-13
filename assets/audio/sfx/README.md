# 효과음

플레이스홀더다. 실제 게임에서는 교체하는 것을 전제로 넣었다.

| 파일 | 출처 | 라이선스 |
|---|---|---|
| `ui_click.ogg` | [Kenney Interface Sounds 1.0](https://kenney.nl/assets/interface-sounds) — `Audio/click_001.ogg` | CC0 1.0 (`kenney_license.txt`) |

원본 그대로 받은 파일이다(수정 없음). 이름만 저장소 규약대로 lowercase snake_case로 바꿨다.

103개짜리 팩에서 실제로 쓰는 한 개만 넣었다. `autoload/ui_sounds.gd`가 모든 버튼에
자동으로 연결한다. 다른 소리(뒤로가기·에러 등)가 필요해지면 같은 팩에서 받아
여기 추가하고 재생 지점에서 불러 쓰면 된다.
