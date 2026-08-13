extends Node
## 전역 signal 허브.
##
## 여기에는 signal 선언만 둔다. 로직·상태를 넣지 말 것 —
## 발신자와 수신자가 서로를 몰라도 되게 만드는 것이 유일한 목적이다.

## SceneManager가 페이드 아웃을 시작할 때. scene_id는 SceneManager.SCENES의 키.
signal scene_change_started(scene_id: String)

## 새 씬이 붙고 페이드 인이 끝났을 때.
signal scene_change_finished(scene_id: String)

## 일시정지 상태가 바뀌었을 때.
signal game_paused(paused: bool)

## 게임 오버.
signal game_over

## Settings.set_locale()로 언어가 바뀌었을 때.
signal language_changed(locale: String)

## SaveManager가 디스크 기록을 마쳤을 때.
signal save_completed
