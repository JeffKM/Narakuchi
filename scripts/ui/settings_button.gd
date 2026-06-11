class_name SettingsButton
extends Button
## 셸 코너 설정 기어 (→ ADR 0004) — 설정 패널(음소거·볼륨·초기화) 진입점.
## 기존 코너 스피커(원탭 음소거)를 승격해 교체한다. 베젤 우상단(LCD 바깥)의 작은 글리프 버튼.
## 누르면 pressed_gear 방출 → ShellFrame 가 settings_requested 로 올린다. 상태는 안 들고 진입만.
## 비활성(스플래시 연출 중)일 땐 흐리게 + 입력 무시(set_enabled).

signal pressed_gear

var _enabled := true


func _ready() -> void:
  flat = true
  focus_mode = Control.FOCUS_NONE
  tooltip_text = "설정"
  # 좌상단 로스터(교체) 진입 버튼과 동일 프레임 — charcoal 0.9 바탕 + 골드 1px 테두리(라운드 6).
  # 평소/호버/눌림 모두 정적(로스터 frame 처럼 고정). 글리프는 _draw 가 그 위에 얹는다.
  var box := StyleBoxFlat.new()
  box.bg_color = Color(Palette.CHARCOAL.r, Palette.CHARCOAL.g, Palette.CHARCOAL.b, 0.9)
  box.set_corner_radius_all(6)
  box.set_border_width_all(1)
  box.border_color = Palette.GOLD
  add_theme_stylebox_override("normal", box)
  add_theme_stylebox_override("hover", box)
  add_theme_stylebox_override("pressed", box)
  add_theme_stylebox_override("disabled", box)
  add_theme_stylebox_override("focus", StyleBoxEmpty.new())
  pressed.connect(_on_pressed)


## 활성/비활성 — 스플래시 연출 중엔 꺼서 진입을 막는다(흐리게 + 입력 무시).
## 프레임·글리프를 한 번에 흐리도록 modulate 로 처리(글리프 색 분기 대신).
func set_enabled(on: bool) -> void:
  _enabled = on
  disabled = not on
  mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
  modulate.a = 1.0 if on else 0.4
  queue_redraw()


func _on_pressed() -> void:
  if _enabled:
    pressed_gear.emit()


## 톱니바퀴 글리프 — 중앙 허브 + 바깥 톱니 8개(도트 결, 정수 좌표).
## 색은 항상 골드(프레임 위), 비활성 흐림은 set_enabled 의 modulate 가 처리한다.
func _draw() -> void:
  var c := size / 2.0
  var col := Palette.GOLD
  var r_in := 5.0    # 허브 반지름
  var r_out := 9.0   # 톱니 끝 반지름
  var tooth := 3.0   # 톱니 폭(절반)

  # 바깥 톱니 8개 — 허브 둘레에 사다리꼴로 박는다.
  for i in 8:
    var a := TAU * float(i) / 8.0
    var dir := Vector2(cos(a), sin(a))
    var perp := Vector2(-dir.y, dir.x)
    var quad := PackedVector2Array([
      c + dir * r_in + perp * tooth,
      c + dir * r_in - perp * tooth,
      c + dir * r_out - perp * (tooth - 1.0),
      c + dir * r_out + perp * (tooth - 1.0)])
    draw_colored_polygon(quad, col)

  # 허브 링 + 가운데 구멍
  draw_circle(c, r_in, col)
  draw_circle(c, r_in - 3.0, Palette.INK)
