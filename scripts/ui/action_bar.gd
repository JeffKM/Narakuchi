class_name ActionBar
extends Node2D
## 4버튼 액션 바 (T09 옥자 / T15 시온이) — 캐릭터별 버튼 세트.
##   - 옥자: 체키 주문 · 음료 주문 · 대화 · 선물
##   - 시온이: 체키 주문 · 간식 · 놀기 · 쓰담
## 입력 하이브리드:
##   - 터치: 버튼을 직접 눌러 즉시 선택.
##   - 셸 3버튼: SELECT 로 커서 순환, OK 로 포커스된 버튼 확인. (Cafe 가 셸 신호를 중계)
## 선택되면 action_chosen(id) 신호를 방출한다(호감도 처리는 Cafe).
## configure(actions) 를 add_child 전에 호출하면 버튼 세트를 바꾼다(미호출 = 옥자 기본).

signal action_chosen(id: String)

const LCD_W := 333
const MARGIN := 8
const GAP := 6
const BAR_Y := 410
const BTN_H := 42

# 4버튼 세트 (순서 = 커서 순환 순서)
const OKJA_ACTIONS := [
  {"id": "cheki", "label": "체키"},
  {"id": "drink", "label": "음료"},
  {"id": "talk",  "label": "대화"},
  {"id": "gift",  "label": "선물"},
]
const SION_ACTIONS := [
  {"id": "cheki", "label": "체키"},
  {"id": "snack", "label": "간식"},
  {"id": "play",  "label": "놀기"},
  {"id": "pet",   "label": "쓰담"},
]

var actions: Array = OKJA_ACTIONS  # 기본 = 옥자. configure()로 교체.

var _buttons: Array[Button] = []
var _cursor := 0
var _bw := 0.0          # 버튼 폭(커서 위치 계산용)
var _heart: HeartCursor # 포커스된 버튼 위 골드 하트 커서


## 버튼 세트 주입(트리 진입 전). 미호출 시 옥자 기본 세트.
func configure(action_set: Array) -> void:
  actions = action_set


func _ready() -> void:
  var n := actions.size()
  _bw = float(LCD_W - 2 * MARGIN - (n - 1) * GAP) / float(n)
  for i in range(n):
    var x := MARGIN + i * (_bw + GAP)
    _buttons.append(_make_button(i, x, _bw))
  _heart = HeartCursor.new()
  add_child(_heart)
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
  btn.text = actions[idx]["label"]
  btn.position = Vector2(x, BAR_Y)
  btn.size = Vector2(w, BTN_H)
  UiTheme.style_button(btn)  # 공용 지옥풍 버튼 테마 (커서는 우리가 직접 그린다)
  btn.pressed.connect(_choose.bind(idx))
  add_child(btn)
  return btn


## 터치/OK 공통: 커서를 그 버튼으로 옮기고 선택 통지.
func _choose(idx: int) -> void:
  _cursor = idx
  _update_cursor()
  action_chosen.emit(actions[idx]["id"])


## 포커스된 버튼만 강조 바탕 + 그 위에 골드 하트 커서를 둔다.
func _update_cursor() -> void:
  for i in range(_buttons.size()):
    UiTheme.set_button_focused(_buttons[i], i == _cursor)
  # 하트는 포커스 버튼의 상단 중앙 살짝 위에
  var bx := MARGIN + _cursor * (_bw + GAP) + _bw / 2.0
  _heart.position = Vector2(bx, BAR_Y - 6)
