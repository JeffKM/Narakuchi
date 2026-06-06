class_name Splash
extends Node2D
## 진입 스플래시 — 귀여운 지옥문이 열리며 옥자가 맞이한다(데일리 출석 연출, ROADMAP T14 흡수). (→ ADR 0001)
## 셸 LCD(333×480) 안에 오버레이로 올라가고, 끝나면 finished 로 Main 에 통지한다.
##
## 연출: bg + 옥자(상황별 표정) + 골드 하트 인사 카드 위에 지옥문 통짜 1장을
##   좌/우 반쪽으로 잘라, 각 반쪽을 GateDoor(경첩 폴드 + 슬랩 옆면)로 여닫는다 —
##   열릴수록 앞면이 압축되고 어두운 두께 옆면이 드러나 종이가 아닌 "문" 두께감을 준다.
## 자동 진행(타이머) + 탭/셸 OK·CANCEL 로 즉시 스킵.
## 출석/방치 판정은 Meters.evaluate_session()(읽기전용) — 실제 적용은 Cafe.start()의 begin_session().

signal finished

const LCD_W := 333
const LCD_H := 480
const BG_TEX := "res://assets/sprites/bg_naraka.png"
const GATE_TEX := "res://assets/sprites/gate_naraka.png"
const OkjaScript := preload("res://scripts/okja.gd")

const SPLIT_X := 166       # 문 분할 x (가운데 이음선)
const DOOR_THICK := 16.0   # 문짝 슬랩 두께(열렸을 때 드러나는 옆면 폭)
const SHUT_HOLD := 0.25    # 열기 전 닫힌 문을 잠깐
const OPEN_TIME := 1.4     # 문 열림 시간(경첩 폴드)
const CARD_FADE := 0.3     # 인사 카드 페이드인
const HOLD_TIME := 0.9     # 다 열린 뒤 머무는 시간
const OKJA_FEET := Vector2(LCD_W / 2.0, 400)

var _eval: Dictionary
var _gate_l: GateDoor  # 좌문(경첩 폴드 + 슬랩 옆면)
var _gate_r: GateDoor  # 우문
var _card: Control
var _okja: Okja
var _seq: Tween
var _done := false


func _ready() -> void:
  _eval = Meters.evaluate_session()
  _build()
  _play()


## 셸 OK/CANCEL → 즉시 스킵.
func handle_shell_action(action: StringName) -> void:
  if action == &"ok" or action == &"cancel":
    _finish()


# ── 화면 구성 ─────────────────────────────────────────────

func _build() -> void:
  # 1) 배경 (맨 뒤)
  var bg := Sprite2D.new()
  bg.texture = load(BG_TEX)
  bg.centered = false
  bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(bg)

  # 2) 옥자 (상황별 표정) — 처음엔 문 뒤라 안 보임
  _okja = OkjaScript.new()
  _okja.position = OKJA_FEET
  add_child(_okja)
  _okja.set_expression(_okja_expr())

  # 3) 인사 카드 (하단) — 처음엔 투명, 문 열린 뒤 페이드인
  _card = _make_card()
  _card.modulate.a = 0.0
  add_child(_card)

  # 4) 지옥문 좌/우 문짝 (맨 앞, 닫힘) — 경첩은 바깥 모서리(좌 x=0 / 우 x=LCD_W).
  var tex := load(GATE_TEX)
  _gate_l = _make_gate_half(tex, Rect2(0, 0, SPLIT_X, LCD_H), true, 0)
  _gate_r = _make_gate_half(tex, Rect2(SPLIT_X, 0, LCD_W - SPLIT_X, LCD_H), false, LCD_W)
  add_child(_gate_l)
  add_child(_gate_r)

  # 5) 탭 스킵 영역 (맨 위 투명 버튼)
  var skip := Button.new()
  skip.flat = true
  skip.focus_mode = Control.FOCUS_NONE
  skip.position = Vector2.ZERO
  skip.size = Vector2(LCD_W, LCD_H)
  var empty := StyleBoxEmpty.new()
  skip.add_theme_stylebox_override("normal", empty)
  skip.add_theme_stylebox_override("hover", empty)
  skip.add_theme_stylebox_override("pressed", empty)
  skip.pressed.connect(_finish)
  add_child(skip)


## 지옥문 한쪽 문짝 GateDoor 구성. 경첩은 hinge_x(좌 0 / 우 LCD_W) 모서리.
func _make_gate_half(tex: Texture2D, region: Rect2, is_left: bool, hinge_x: float) -> GateDoor:
  var d := GateDoor.new()
  d.tex = tex
  d.region = region
  d.face_w = region.size.x
  d.thickness = DOOR_THICK
  d.is_left = is_left
  d.position = Vector2(hinge_x, 0)
  return d


## 하단 인사 카드 (골드 테두리 패널 + 상황별 한 줄). 표정/문구는 _eval·관계 단계로 분기.
func _make_card() -> Control:
  var nick := String(SaveManager.get_value("player.nickname", "손님"))
  var stage := Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0)))
  var onboarded := bool(SaveManager.get_value("flags.onboarded", false))

  var title := ""
  var sub := ""
  if not onboarded:
    title = "나라카에 어서 와요"
  elif bool(_eval["was_neglected"]):
    title = Dialogue.okja_line("neglect", stage, nick)
    sub = "그래도, 와줘서."
  else:
    title = Dialogue.okja_line("enter", stage, nick)
    sub = "%d일째 방문" % int(_eval["streak"])

  var cw := 280
  var ch := 72
  var panel := Panel.new()
  panel.position = Vector2((LCD_W - cw) / 2.0, 296)
  panel.size = Vector2(cw, ch)
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.78)
  sb.set_corner_radius_all(8)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD
  panel.add_theme_stylebox_override("panel", sb)

  var lb := _label(title, Palette.CREAM)
  if sub == "":
    # 단일 인사(첫 방문 등) — 박스 전체 높이에 세로 중앙 정렬(위 붙음·하단 공백 해소)
    lb.position = Vector2(8, 0)
    lb.size = Vector2(cw - 16, ch)
    lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    panel.add_child(lb)
  else:
    # 인사 + 부제 — VBox 로 세로 중앙 스택. 인사가 길어 두 줄로 줄바꿈돼도 부제가
    # 밀려나 겹치지 않는다(고정 좌표는 인사 1줄을 가정해 두 줄일 때 부제와 겹쳤음).
    var box := VBoxContainer.new()
    box.position = Vector2(8, 0)
    box.size = Vector2(cw - 16, ch)
    box.alignment = BoxContainer.ALIGNMENT_CENTER  # 스택 블록을 박스 세로 중앙에
    box.add_theme_constant_override("separation", 4)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(lb)  # autowrap=on → VBox 폭(cw-16)에서 줄바꿈, 높이 자동
    var lb2 := _label(sub, Palette.CANDLE)
    lb2.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
    box.add_child(lb2)
    panel.add_child(box)
  return panel


## 가운데 정렬 + 외곽선 라벨 헬퍼.
func _label(text: String, color: Color) -> Label:
  var lb := Label.new()
  lb.text = text
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  lb.add_theme_font_size_override("font_size", Fonts.SIZE_LEAD)  # 인사 글자 키움(11→14)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.add_theme_constant_override("line_spacing", 4)
  return lb


## 상황별 옥자 표정: 첫 접속=기본 / 방치 복귀=시무룩 / 평상 재방문=웃음.
func _okja_expr() -> StringName:
  if not bool(SaveManager.get_value("flags.onboarded", false)):
    return &"idle"
  if bool(_eval["was_neglected"]):
    return &"sad"
  return &"smile"


# ── 연출 ─────────────────────────────────────────────────

func _play() -> void:
  _seq = create_tween()
  _seq.tween_interval(SHUT_HOLD)                  # 닫힌 문 잠깐
  # 좌우 양문을 경첩 기준으로 접어 연다 (open 0→1, 병렬) — 앞면 압축 + 두께 옆면 노출로 입체감
  _seq.tween_property(_gate_r, "open", 1.0, OPEN_TIME) \
    .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
  _seq.parallel().tween_property(_gate_l, "open", 1.0, OPEN_TIME) \
    .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
  # 문 열린 직후: 평상 재방문(웃음)이면 옥자 폴짝 + 카드 등장
  _seq.tween_callback(_on_opened)
  _seq.tween_property(_card, "modulate:a", 1.0, CARD_FADE)
  _seq.tween_interval(HOLD_TIME)
  _seq.tween_callback(_finish)


## 문이 다 열린 순간 — 웃는 표정일 때만 폴짝(시무룩/기본은 그대로 둠).
func _on_opened() -> void:
  if _okja.current == &"smile":
    _okja.hop()


func _finish() -> void:
  if _done:
    return
  _done = true
  if _seq and _seq.is_valid():
    _seq.kill()
  finished.emit()
