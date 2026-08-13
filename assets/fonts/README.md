# 폰트

플레이스홀더다. 실제 게임에서는 브랜드 폰트로 교체하는 것을 전제로 넣었다.

| 파일 | 출처 | 라이선스 |
|---|---|---|
| `noto_sans_jp_regular.otf` | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) `Sans/SubsetOTF/JP/NotoSansJP-Regular.otf` | SIL OFL 1.1 (`ofl.txt`) |
| `noto_sans_kr_regular.otf` | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) `Sans/SubsetOTF/KR/NotoSansKR-Regular.otf` | SIL OFL 1.1 (`ofl.txt`) |

원본 그대로 받은 파일이다(수정 없음). 이름만 저장소 규약대로 lowercase snake_case로 바꿨다.

## 왜 SubsetOTF인가

같은 폰트의 다른 배포본과 비교하면:

- Google Fonts 가변 폰트 `NotoSansKR[wght].ttf` — 10.4MB (KR) / 9.6MB (JP)
- 전체 CJK `NotoSansCJKkr-Regular.otf` — 16.4MB
- **언어별 SubsetOTF Regular — 4.6MB (KR) / 4.5MB (JP)** ← 이걸 쓴다

굵기는 Regular 하나만 넣는다. 테마가 한 굵기만 쓴다.

## 왜 JP가 먼저이고 KR이 폴백인가

두 폰트의 실제 커버리지를 확인한 결과(`Font.has_char`):

| | 라틴 | 한글 | 가나 | 한자 |
|---|---|---|---|---|
| Noto Sans KR | O | O | O | O (한국 자형) |
| Noto Sans JP | O | **X** | O | O (일본 자형) |

한자 자형은 두 언어가 다르다(直, 骨 등). JP를 앞에 두면 한자·가나·라틴을 일본
자형으로 그리고, JP에 없는 한글만 KR로 넘어간다. 반대로 두면 일본어 한자가
한국 자형으로 그려진다 — 한국어 UI에 한자가 나올 일은 사실상 없으므로 이 순서가
손해가 적다.

체인은 `ui/theme/default_theme.tres`의 `FontVariation_default`에 있고,
`tests/test_fonts.gd`가 셰이핑 결과로 실제 공급자를 검증한다.
