class_name NullIAPService
extends IAPService
## SDK 없이 흐름만 돌리는 기본 구현. 로그를 찍고 모든 구매를 성공 처리한다.
##
## 구매 목록은 메모리에만 남는다 — 앱을 껐다 켜면 사라진다. 복원 흐름을
## 눌러볼 수 있게 하려는 것이지 결제를 흉내내려는 게 아니다.
##
## signal을 call_deferred로 쏘는 이유는 [NullAdService] 참고.

var _purchased := PackedStringArray()


func initialize() -> void:
	print("[iap] Null 결제 서비스로 초기화 — 실제 결제는 일어나지 않는다")
	initialized.emit.call_deferred(true)


func purchase(product_id: String) -> void:
	print("[iap] 구매 요청(%s) — 즉시 성공 처리" % product_id)
	if not _purchased.has(product_id):
		_purchased.append(product_id)
	purchase_completed.emit.call_deferred(product_id, true)


func restore_purchases() -> void:
	print("[iap] 복원 요청 — 이번 실행에서 구매한 %d건" % _purchased.size())
	purchases_restored.emit.call_deferred(_purchased)
