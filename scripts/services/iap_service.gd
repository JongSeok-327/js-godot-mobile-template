@abstract
class_name IAPService
extends RefCounted
## 인앱 결제 SDK 인터페이스. 게임 코드는 이 타입만 본다.
##
## 실제 구현(Google Play Billing 등)을 붙일 때는 이 클래스를 상속해서
## Services.iap에 꽂는다. 게임 코드는 한 줄도 바뀌지 않는다.
##
## 복원(restore_purchases)은 선택이 아니다 — 기기를 바꾼 사용자가 비소모성
## 상품을 되찾을 방법이 없으면 스토어 심사에서 걸린다.

## initialize() 결과.
signal initialized(success: bool)

## 구매 시도가 끝났을 때. success=false면 취소·실패 — 상품을 주면 안 된다.
signal purchase_completed(product_id: String, success: bool)

## 복원이 끝났을 때. 이미 소유한 상품 ID 목록(없으면 빈 배열).
signal purchases_restored(product_ids: PackedStringArray)


## SDK 초기화 + 상품 목록 조회. 앱 시작 시 한 번 — Services가 대신 불러준다.
@abstract func initialize() -> void


## product_id는 스토어에 등록한 상품 ID.
@abstract func purchase(product_id: String) -> void


@abstract func restore_purchases() -> void
