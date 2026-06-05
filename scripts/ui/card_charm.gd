class_name CardCharm
extends Control
## 칸 상태 참(charm) — empty=✦반짝임 / locked=왁스 봉랍. (→ 컬렉션북 장식 합의 2026-06-05)
##
## 미보유 칸은 둘 다 "표지를 보이며 꽂힌 카드"라 거의 똑같다 → 이 참이 유일한 구분자다.
##   sparkle = 밝은 골드 반짝임(능동적 초대: "지금 채울 수 있다")
##   seal    = 어두운 버건디 봉랍(봉인된 미래: "곧 온다") — 탭 locked 표식과 겸용.
##
## 지금은 _draw 플레이스홀더(HeartCursor 도트 선례). 에셋이 들어오면 TEX_PATH 가 자동으로 텍스처로 교체.
##   sparkle → assets/sprites/sparkle.png (16×16) · seal → assets/sprites/seal_wax.png (24×24)

const KIND_SPARKLE := "sparkle"
const KIND_SEAL := "seal"
const SIZE := Vector2(24, 24)

const TEX_PATH := {
  "sparkle": "res://assets/sprites/sparkle.png",
  "seal": "res://assets/sprites/seal_wax.png",
}

var kind: String = KIND_SPARKLE
var _tex: Texture2D


## 종류 주입(트리 진입 전).
func setup(charm_kind: String) -> void:
  kind = charm_kind


func _ready() -> void:
  custom_minimum_size = SIZE
  size = SIZE
  pivot_offset = SIZE / 2.0
  mouse_filter = Control.MOUSE_FILTER_IGNORE

  var p: String = TEX_PATH.get(kind, "")
  if p != "" and ResourceLoader.exists(p):
    _tex = load(p) as Texture2D

  if kind == KIND_SPARKLE:
    _twinkle()
  queue_redraw()


func _draw() -> void:
  if _tex:
    draw_texture_rect(_tex, Rect2(Vector2.ZERO, SIZE), false)
    return
  match kind:
    KIND_SPARKLE: _draw_sparkle()
    KIND_SEAL: _draw_seal()


## ✦ 4각 별(아웃/인 반지름 교차) + 캔들 중심점.
func _draw_sparkle() -> void:
  var c := SIZE / 2.0
  var pts := PackedVector2Array()
  for i in 8:
    var ang := i * PI / 4.0
    var rad := 10.0 if i % 2 == 0 else 3.0
    pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
  draw_colored_polygon(pts, Palette.GOLD)
  draw_circle(c, 1.5, Palette.CANDLE)


## 왁스 봉랍 — 버건디 원 + 블러드 안쪽 + 골드 링/중심점.
func _draw_seal() -> void:
  var c := SIZE / 2.0
  draw_circle(c, 10.0, Palette.BURGUNDY)
  draw_circle(c, 6.0, Palette.BLOOD)
  draw_arc(c, 10.0, 0.0, TAU, 28, Palette.GOLD, 1.5, true)
  draw_circle(c, 1.5, Palette.GOLD)


## 반짝임 가벼운 점멸 + 맥동.
func _twinkle() -> void:
  var t := create_tween().set_loops()
  t.set_parallel(true)
  t.tween_property(self, "modulate:a", 0.55, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.tween_property(self, "scale", Vector2(1.15, 1.15), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.chain().set_parallel(true)
  t.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.tween_property(self, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
