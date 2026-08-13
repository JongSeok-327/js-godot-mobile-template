class_name NullAdService
extends AdService
## SDK 없이 흐름만 돌리는 기본 구현. 로그를 찍고 즉시 성공으로 응답한다.
##
## 덕분에 광고 SDK를 붙이기 전에도 "리워드 광고 → 보상 지급" 경로를
## 끝까지 눌러볼 수 있다.
##
## 다만 signal은 `call_deferred`로 쏜다 — 요청 함수 안에서 동기로 쏘면
## 실제 SDK와 타이밍이 달라진다. 보상 지급 코드가 광고 요청 함수가 끝나기도
## 전에 도는 순서 버그를, Null 구현으로 테스트할 때만 못 잡게 된다.


func initialize() -> void:
	print("[ads] Null 광고 서비스로 초기화 — 실제 광고는 표시되지 않는다")
	initialized.emit.call_deferred(true)


func is_rewarded_ready() -> bool:
	return true


func show_rewarded(placement: String) -> void:
	print("[ads] 리워드 광고 요청(%s) — 즉시 시청 완료 처리" % placement)
	rewarded_completed.emit.call_deferred(placement, true)


func show_interstitial(placement: String) -> void:
	print("[ads] 전면 광고 요청(%s) — 즉시 닫힘 처리" % placement)
	interstitial_closed.emit.call_deferred(placement)
