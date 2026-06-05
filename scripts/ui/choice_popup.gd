class_name ChoicePopup
extends Control
## 대화/선물 2~N지선다 팝업 (T11) — 옥자 질문 한 줄 + 선택 버튼 → 고르면 반응 한 줄.
##
## 표정 9할 원칙: 풀딤이 아니라 살짝만 어둑하게(옥자 얼굴은 보이게) + 하단 비주얼노벨식 패널.
## 두 단계: ask(선택지 노출) → reply(옥자 반응 + 닫기). 고르는 순간 chosen(choice) 1회 방출 →
##   Cafe 가 스태미나 소모 + 호감도(tier→Balance.AFF_*) + 옥자 표정 + (필요 시) 반말 컷인 예약.
## 셸 3버튼 하이브리드: SELECT 커서 순환 · OK 확인 · CANCEL 취소(닫기) · 터치 직접.
## LCD(333×480) 전체를 덮어 뒤(카페) 입력을 막는다. 닫히면 closed 신호.

signal chosen(choice: Dictionary)
signal closed

const LCD := Vector2(333, 480)
const PANEL := Rect2(16, 244, 301, 188)  # 하단 패널 (옥자 상반신·얼굴은 위로 노출)
const PAD := 14                           # 패널 안쪽 여백
const BTN_H := 34
const BTN_GAP := 6

var _prompt_text := ""
var _choices: Array = []
var _phase := "ask"  # ask → reply → done
var _cursor := 0
var _prompt: Label
var _hint: Label
var _buttons: Array[Button] = []
var _heart: HeartCursor
var _picked: Dictionary


## prompt(옥자 질문) + choices(Array[{label, reply, tier, expr}]) 주입(트리 진입 전).
func setup(prompt: String, choices: Array) -> void:
  _prompt_text = prompt
  _choices = choices


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤(카페) 입력 차단

  # 1) 옅은 딤 — 옥자 얼굴은 보이게(표정 9할). 탭은 reply 단계에서만 닫기.
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.42, 0.2)

  # 2) 하단 패널 (버건디 + 골드 테두리, 살짝 떠오르며 등장)
  var panel := Panel.new()
  panel.position = PANEL.position
  panel.size = PANEL.size
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.BURGUNDY_DARK.r, Palette.BURGUNDY_DARK.g, Palette.BURGUNDY_DARK.b, 0.96)
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD
  sb.shadow_color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.6)
  sb.shadow_size = 6
  panel.add_theme_stylebox_override("panel", sb)
  add_child(panel)

  # 3) 옥자 질문 한 줄 (패널 상단, 자동 줄바꿈)
  _prompt = _make_label(Palette.CANDLE, Fonts.SIZE_BODY)
  _prompt.text = _prompt_text
  _prompt.position = PANEL.position + Vector2(PAD, PAD)
  _prompt.size = Vector2(PANEL.size.x - PAD * 2, 0)
  add_child(_prompt)

  # 4) 선택 버튼 스택 (패널 하단부터 위로 쌓아 질문과 안 겹치게)
  var n := _choices.size()
  var bw := PANEL.size.x - PAD * 2
  var stack_h := n * BTN_H + (n - 1) * BTN_GAP
  var y0 := PANEL.position.y + PANEL.size.y - PAD - stack_h
  for i in range(n):
    var btn := Button.new()
    btn.text = String(_choices[i]["label"])
    btn.position = Vector2(PANEL.position.x + PAD, y0 + i * (BTN_H + BTN_GAP))
    btn.size = Vector2(bw, BTN_H)
    UiTheme.style_button(btn)
    btn.pressed.connect(_choose.bind(i))
    add_child(btn)
    _buttons.append(btn)

  # 5) 포커스 골드 하트 커서 (Node2D — Control 위에 그려진다)
  _heart = HeartCursor.new()
  add_child(_heart)

  # 6) 입력 힌트 (패널 아래 한 줄)
  _hint = _make_label(Palette.GREY_300, Fonts.SIZE_SMALL)
  _hint.text = "OK ▶ 선택"
  _hint.position = Vector2(0, PANEL.position.y + PANEL.size.y + 4)
  _hint.size = Vector2(LCD.x, 14)
  add_child(_hint)

  _update_cursor()

  # 패널 등장(살짝 상승 + 페이드)
  panel.modulate.a = 0.0
  panel.position.y += 12
  var t := create_tween().set_parallel(true)
  t.tween_property(panel, "modulate:a", 1.0, 0.2)
  t.tween_property(panel, "position:y", PANEL.position.y, 0.22) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (Cafe → 여기). ask: SELECT 순환·OK 선택·CANCEL 취소 / reply: 아무거나 닫기.
func handle_shell_action(action: StringName) -> void:
  if _phase == "ask":
    match action:
      &"select": _move_cursor()
      &"ok": _choose(_cursor)
      &"cancel": _close()  # 취소 — 호감도 변화 없음(스태미나도 보존)
  elif _phase == "reply":
    _close()


## 딤 탭: ask 단계는 무시(반드시 버튼 선택), reply 단계는 닫기.
func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    if _phase == "reply":
      _close()
      accept_event()


## 셸 SELECT — 커서 다음 선택지로 순환.
func _move_cursor() -> void:
  _cursor = (_cursor + 1) % _buttons.size()
  _update_cursor()


## 선택 확정 — chosen 1회 방출 후 reply 단계(옥자 반응 + 닫기 대기)로.
func _choose(i: int) -> void:
  if _phase != "ask":
    return
  _cursor = i
  _picked = _choices[i]
  _phase = "reply"
  chosen.emit(_picked)  # Cafe 가 호감도·표정·컷인 처리

  for b in _buttons:
    b.hide()
  _heart.hide()
  _prompt.text = String(_picked["reply"])
  _hint.text = "OK ▶ 닫기"


## 포커스 버튼만 강조 + 그 위에 골드 하트.
func _update_cursor() -> void:
  for i in range(_buttons.size()):
    UiTheme.set_button_focused(_buttons[i], i == _cursor)
  var b := _buttons[_cursor]
  _heart.position = b.position + Vector2(b.size.x / 2.0, -5)


func _close() -> void:
  if _phase == "done":
    return
  _phase = "done"
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


# ── 헬퍼 ─────────────────────────────────────────────────

func _make_label(color: Color, font_size: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.add_theme_constant_override("line_spacing", 3)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
