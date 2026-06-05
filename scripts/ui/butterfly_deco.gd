class_name ButterflyDeco
extends Control
## 페이지 장식 나비 — 은은히 떠다님(코드 트윈). (→ 컬렉션북 장식 합의 2026-06-05)
##
## 나라카 시그니처 생동감(나비체키 모티프). 입력 무시, 카드 위를 가리지 않게 가장자리에 배치.
## 지금은 _draw 플레이스홀더. 에셋(butterfly_deco.png 16×16)이 들어오면 텍스처로 교체.

const TEX_PATH := "res://assets/sprites/butterfly_deco.png"
const SIZE := Vector2(16, 16)

var _tex: Texture2D
var _hue: Color = Palette.VIOLET


## 날개 색 + 위치 주입(트리 진입 전 position 설정 → _ready 가 그 자리를 기준으로 부유).
func setup(hue: Color) -> void:
  _hue = hue


func _ready() -> void:
  custom_minimum_size = SIZE
  size = SIZE
  pivot_offset = SIZE / 2.0
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  if ResourceLoader.exists(TEX_PATH):
    _tex = load(TEX_PATH) as Texture2D
  _float()
  queue_redraw()


func _draw() -> void:
  if _tex:
    draw_texture_rect(_tex, Rect2(Vector2.ZERO, SIZE), false)
    return
  var c := SIZE / 2.0
  # 윗날개 2 + 아랫날개 2(살짝 어둡게) + 몸통
  draw_colored_polygon(PackedVector2Array([c, c + Vector2(-7, -6), c + Vector2(-7, 1)]), _hue)
  draw_colored_polygon(PackedVector2Array([c, c + Vector2(7, -6), c + Vector2(7, 1)]), _hue)
  draw_colored_polygon(PackedVector2Array([c, c + Vector2(-6, 6), c + Vector2(-1, 4)]), _hue.darkened(0.18))
  draw_colored_polygon(PackedVector2Array([c, c + Vector2(6, 6), c + Vector2(1, 4)]), _hue.darkened(0.18))
  draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Palette.INK, 1.0)


## 위아래 부유(bob) + 미세한 날갯짓(scale_x 펄럭). 기준 = 부모가 잡아준 현재 position.
func _float() -> void:
  var base := position
  var bob := create_tween().set_loops()
  bob.tween_property(self, "position:y", base.y - 4.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  bob.tween_property(self, "position:y", base.y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  var flap := create_tween().set_loops()
  flap.tween_property(self, "scale:x", 0.7, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  flap.tween_property(self, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
