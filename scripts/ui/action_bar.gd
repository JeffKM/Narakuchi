class_name ActionBar
extends Node2D
## 옥자 4버튼 액션 바 (T09) — 체키 주문 · 음료 주문 · 대화 · 선물.
## 입력 하이브리드:
##   - 터치: 버튼을 직접 눌러 즉시 선택.
##   - 셸 3버튼: SELECT 로 커서 순환, OK 로 포커스된 버튼 확인. (Cafe 가 셸 신호를 중계)
## 선택되면 action_chosen(id) 신호를 방출한다(호감도 처리는 Cafe).

signal action_chosen(id: String)

const LCD_W := 333
const MARGIN := 8
const GAP := 6
const BAR_Y := 410
const BTN_H := 42

# 4버튼 정의 (순서 = 커서 순환 순서)
const ACTIONS := [
  {"id": "cheki", "label": "체키"},
  {"id": "drink", "label": "음료"},
  {"id": "talk",  "label": "대화"},
  {"id": "gift",  "label": "선물"},
]

var _buttons: Array[Button] = []
var _cursor := 0


func _ready() -> void:
  var n := ACTIONS.size()
  var bw := float(LCD_W - 2 * MARGIN - (n - 1) * GAP) / float(n)
  for i in range(n):
    var x := MARGIN + i * (bw + GAP)
    _buttons.append(_make_button(i, x, bw))
  _update_cursor()


## 셸 SELECT — 커서를 다음 버튼으로 순환.
func move_cursor() -> void:
  _cursor = (_cursor + 1) % _buttons.size()
  _update_cursor()


## 셸 OK — 현재 포커스된 버튼을 확인.
func activate_focused() -> void:
  _choose(_cursor)


# ── 내부 ─────────────────────────────────────────────────

func _make_button(idx: int, x: float, w: float) -> Button:
  var btn := Button.new()
  btn.text = ACTIONS[idx]["label"]
  btn.position = Vector2(x, BAR_Y)
  btn.size = Vector2(w, BTN_H)
  btn.focus_mode = Control.FOCUS_NONE  # 커서는 우리가 직접 그린다
  btn.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  btn.add_theme_color_override("font_color", Palette.CREAM)
  btn.add_theme_color_override("font_hover_color", Palette.WHITE)
  btn.add_theme_color_override("font_pressed_color", Palette.WHITE)
  btn.add_theme_stylebox_override("normal", _style(false))
  btn.add_theme_stylebox_override("hover", _style(false))
  btn.add_theme_stylebox_override("pressed", _style(true))
  btn.pressed.connect(_choose.bind(idx))
  add_child(btn)
  return btn


## 버튼 스타일 박스. focused=true 면 골드 테두리(커서 표시).
func _style(focused: bool) -> StyleBoxFlat:
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.WOOD if focused else Palette.WOOD_DARK
  sb.set_corner_radius_all(4)
  sb.set_border_width_all(2 if focused else 1)
  sb.border_color = Palette.GOLD if focused else Palette.GOLD_DARK
  return sb


## 터치/OK 공통: 커서를 그 버튼으로 옮기고 선택 통지.
func _choose(idx: int) -> void:
  _cursor = idx
  _update_cursor()
  action_chosen.emit(ACTIONS[idx]["id"])


## 포커스된 버튼만 골드 테두리로 강조.
func _update_cursor() -> void:
  for i in range(_buttons.size()):
    var focused := i == _cursor
    _buttons[i].add_theme_stylebox_override("normal", _style(focused))
    _buttons[i].add_theme_stylebox_override("hover", _style(focused))
