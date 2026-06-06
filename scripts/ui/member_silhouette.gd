class_name MemberSilhouette
extends Control
## 잠긴 멤버 코드 실루엣 — 머리+어깨 흉상. (T21 잠긴 멤버 / 신규 에셋 0)
##
## 잠긴 멤버는 초상 에셋이 없으므로(미공개) 코드 드로잉으로 "누군가 온다"는 실루엣만 보여준다.
## 탭(작게, 24×24)과 확장 슬라이드(크게)에서 공용. 색만 바꿔 멤버를 구분한다.
##   _draw 플레이스홀더 관용구(CardCharm/HeartCursor 선례) — 도트 일관, 입력 무시.

var _color: Color = Palette.GREY_500


## 크기·실루엣 색 주입(트리 진입 전). 색은 멤버 액센트를 어둡게 깐 톤이 어울린다.
func setup(box: Vector2, color: Color) -> void:
  custom_minimum_size = box
  size = box
  _color = color


func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  queue_redraw()


## 머리(원) + 어깨(둥근 사다리꼴) 흉상. 크기에 비례해 그려 탭/슬라이드 양쪽에서 같은 형태.
func _draw() -> void:
  var w := size.x
  var h := size.y
  var head_c := Vector2(w * 0.5, h * 0.34)
  var head_r := w * 0.22
  draw_circle(head_c, head_r, _color)
  var shoulder_top := h * 0.56
  var shoulders := PackedVector2Array([
    Vector2(w * 0.16, h),
    Vector2(w * 0.30, shoulder_top),
    Vector2(w * 0.70, shoulder_top),
    Vector2(w * 0.84, h),
  ])
  draw_colored_polygon(shoulders, _color)
