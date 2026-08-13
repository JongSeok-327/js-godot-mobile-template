# UI 스프라이트

플레이스홀더다. 실제 게임에서는 교체하는 것을 전제로 넣었다.

| 파일 | 출처 | 라이선스 |
|---|---|---|
| `slider_grabber.png` | [Kenney UI Pack 2.0](https://kenney.nl/assets/ui-pack) — `PNG/Grey/Double/slide_hangle.png` | CC0 1.0 (`kenney_license.txt`) |

원본 그대로 받은 파일이다(수정 없음). 이름만 저장소 규약대로 lowercase snake_case로 바꿨다.

## 왜 이것 하나뿐인가

이 템플릿의 UI 테마(`ui/theme/default_theme.tres`)는 **의도적으로 코드 정의**다 —
StyleBoxFlat으로 색·모서리·여백만 지정한다. 색 몇 줄만 바꾸면 리스타일되므로
재사용 템플릿에는 이쪽이 낫다. Kenney의 9-patch 버튼 PNG로 갈아끼우면 리스타일할 때마다
새 아트를 그려야 한다.

반면 HSlider의 그래버는 테마가 지정하지 않으면 **엔진 내장 아이콘**으로 그려진다 —
Godot 버전에 따라 모양이 바뀌고 손가락으로 잡기엔 작다. 여기만 스프라이트로 못 박았다.
1315개짜리 팩에서 실제로 쓰는 한 장만 넣은 이유다.
