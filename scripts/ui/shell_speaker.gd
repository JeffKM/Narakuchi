class_name ShellSpeaker
extends Button
## 셸 코너 스피커 토글 (→ ADR 0004) — 플레이어 SFX on/off.
## 셸 베젤(LCD 바깥)에 얹는 작은 글리프 버튼. 누르면 켜짐/꺼짐 토글 + sfx_toggled 방출.
## 그림은 도트 결로 직접 _draw(스피커콘 + on=음파 / off=X). 상태 영속은 호출측(ShellFrame)이 세이브.

signal sfx_toggled(on: bool)

var _on := true


## 초기 상태 주입(세이브의 flags.sfx_on).
func setup(on: bool) -> void:
  _on = on
  queue_redraw()


func _ready() -> void:
  flat = true
  focus_mode = Control.FOCUS_NONE
  tooltip_text = "효과음 켜기/끄기"
  # 테마 배경 제거(글리프만 보이게) — 평소/호버/눌림 모두 빈 스타일.
  var empty := StyleBoxEmpty.new()
  add_theme_stylebox_override("normal", empty)
  add_theme_stylebox_override("hover", empty)
  add_theme_stylebox_override("pressed", empty)
  add_theme_stylebox_override("focus", empty)
  pressed.connect(_toggle)


func _toggle() -> void:
  _on = not _on
  queue_redraw()
  sfx_toggled.emit(_on)


## 스피커 글리프 — 좌측 콘 + (on 음파 / off X). 도트 또렷하게 정수 좌표.
func _draw() -> void:
  var cy := size.y / 2.0
  var col := Palette.GOLD if _on else Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.38)

  # 스피커 본체(자석 사각) + 콘(우측으로 벌어지는 사다리꼴)
  draw_rect(Rect2(6, cy - 3, 4, 6), col)
  var cone := PackedVector2Array([
    Vector2(10, cy - 3), Vector2(10, cy + 3),
    Vector2(17, cy + 9), Vector2(17, cy - 9)])
  draw_colored_polygon(cone, col)

  if _on:
    # 음파 2겹(우측 호)
    draw_arc(Vector2(17, cy), 6.0, -0.7, 0.7, 8, col, 2.0)
    draw_arc(Vector2(17, cy), 10.0, -0.7, 0.7, 10, col, 2.0)
  else:
    # 음소거 X
    var x0 := 22.0
    draw_line(Vector2(x0, cy - 5), Vector2(x0 + 8, cy + 5), col, 2.0)
    draw_line(Vector2(x0, cy + 5), Vector2(x0 + 8, cy - 5), col, 2.0)
