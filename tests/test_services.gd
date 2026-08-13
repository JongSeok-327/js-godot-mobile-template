extends RefCounted
## Null 서비스 mock 흐름 — 요청 → 결과 signal → 지급 경로.
##
## Null 구현은 signal을 call_deferred로 쏜다. 그래서 요청 직후에는 아직
## 아무 일도 일어나지 않아야 하고, 한 프레임 넘긴 뒤에 결과가 와야 한다.
## 이 타이밍 자체가 검증 대상이다 — 실제 SDK도 동기로 답하지 않는다.
##
## 상태를 남기는 결제 쪽은 autoload를 건드리지 않고 새 인스턴스로 돌린다.


func run(t: Node) -> void:
	_test_locator_defaults(t)
	await _test_rewarded_flow(t)
	await _test_interstitial_flow(t)
	await _test_purchase_and_restore(t)


func _test_locator_defaults(t: Node) -> void:
	t.check(Services.ads is NullAdService, "Services.ads 기본값은 NullAdService")
	t.check(Services.iap is NullIAPService, "Services.iap 기본값은 NullIAPService")
	t.check(Services.ads.is_rewarded_ready(), "Null 광고는 항상 준비 상태")


## 실제 게임이 쓰는 경로 그대로 — Services.ads로 요청하고 보상을 지급한다.
func _test_rewarded_flow(t: Node) -> void:
	# 람다는 지역 변수를 값으로 캡처한다 — 참조 타입에 담아야 밖에서 보인다.
	var wallet := {"coins": 0}
	var handler := func(placement: String, rewarded: bool) -> void:
		if rewarded and placement == "double_reward":
			wallet["coins"] += 10

	Services.ads.rewarded_completed.connect(handler)
	Services.ads.show_rewarded("double_reward")
	t.eq(wallet["coins"], 0, "요청 직후에는 보상이 없다 — 동기 emit이 아니다")

	await t.get_tree().process_frame
	Services.ads.rewarded_completed.disconnect(handler)
	t.eq(wallet["coins"], 10, "리워드 완료 signal을 받고 보상을 지급한다")


func _test_interstitial_flow(t: Node) -> void:
	var closed: Array[String] = []
	var handler := func(placement: String) -> void: closed.append(placement)

	Services.ads.interstitial_closed.connect(handler)
	Services.ads.show_interstitial("level_end")

	await t.get_tree().process_frame
	Services.ads.interstitial_closed.disconnect(handler)
	t.eq(closed, ["level_end"] as Array[String], "전면 광고가 닫힘 signal로 돌아온다")


## 구매 목록이 남으므로 autoload 대신 새 인스턴스로 돌린다.
func _test_purchase_and_restore(t: Node) -> void:
	var iap := NullIAPService.new()
	var results: Array = []
	var restored: Array = []
	var on_purchase := func(product_id: String, success: bool) -> void:
		results.append([product_id, success])
	var on_restore := func(product_ids: PackedStringArray) -> void:
		restored.assign(product_ids)

	iap.purchase_completed.connect(on_purchase)
	iap.purchases_restored.connect(on_restore)

	iap.purchase("remove_ads")
	t.check(results.is_empty(), "구매도 요청 직후에는 결과가 없다")

	await t.get_tree().process_frame
	t.eq(results, [["remove_ads", true]], "구매 완료 signal이 성공으로 돌아온다")

	iap.purchase("remove_ads")  # 같은 상품을 또 사도 목록은 하나여야 한다
	iap.restore_purchases()
	await t.get_tree().process_frame
	t.eq(restored, ["remove_ads"], "복원하면 이번 실행에서 산 상품이 돌아온다")
