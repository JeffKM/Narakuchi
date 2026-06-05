class_name FocusBrackets
extends Control
## 포커스 코너 브래킷 ⌜ ⌝ ⌞ ⌟ — 평면 링 SELECT 표시(뷰파인더 느낌). (→ 컬렉션북 장식 합의 2026-06-05)
##
## 사각 테두리 대신 네 모서리 골드 L자만 그려 "카드를 집어든다"는 촉각을 준다.
## 슬롯의 hop·글로우와 함께 쓰여 어디 선택됐는지 즉시 보이게 한다(터치가 주입력, 3버튼 보조).
## 셰이더 없이 _draw 도트(정수 좌표)라 Nearest 톤 유지.

const ARM := 9.0     # 브래킷 한 변 길이
const THICK := 2.0   # 두께
const INSET := 1.0   # 모서리에서 안쪽 여백

var _size: Vector2 = Vector2(120, 180)


## 그릴 영역 크기 주입(보통 카드 풋프린트).
func setup(target_size: Vector2) -> void:
  _size = target_size


func _ready() -> void:
  size = _size
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  queue_redraw()


func _draw() -> void:
  var col := Palette.GOLD
  var w := _size.x
  var h := _size.y
  var i := INSET
  # 좌상
  draw_rect(Rect2(i, i, ARM, THICK), col)
  draw_rect(Rect2(i, i, THICK, ARM), col)
  # 우상
  draw_rect(Rect2(w - i - ARM, i, ARM, THICK), col)
  draw_rect(Rect2(w - i - THICK, i, THICK, ARM), col)
  # 좌하
  draw_rect(Rect2(i, h - i - THICK, ARM, THICK), col)
  draw_rect(Rect2(i, h - i - ARM, THICK, ARM), col)
  # 우하
  draw_rect(Rect2(w - i - ARM, h - i - THICK, ARM, THICK), col)
  draw_rect(Rect2(w - i - THICK, h - i - ARM, THICK, ARM), col)
