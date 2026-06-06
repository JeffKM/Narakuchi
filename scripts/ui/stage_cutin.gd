class_name StageCutin
extends Control
## 관계 단계 상승 컷인 (T11) — 단골 등극(regular, 200) / 반말 해금(comfy, 600) 보상 연출. (→ docs/script-okja.md)
##
## 관계 단계가 처음 올라설 때 다음 입장에서 한 번 터지는 보상 연출. 티커 한 줄로 흘리지 않고,
##   옥자를 가운데 세워 대사 시퀀스 + 골드 배지로 못박는다.
##   - regular(단골 등극): 존댓말 유지, "단골 등극" 배지
##   - comfy(반말 해금)  : 존댓말→반말 전환, "반말 해금" 배지(핵심 보상)
## 대사/해금 줄/배지는 data/ticker.json 의 okja_cutin[stage] (콘텐츠 스튜디오 편집). Dialogue.okja_cutin 으로 로드.
## 셸 3버튼/탭으로 한 줄씩 진행, 마지막에 해금 배지 → 한 번 더로 닫힘. 닫히면 closed 신호.
## LCD(333×480) 전체를 덮는 오버레이(뒤 카페 입력 차단).

signal closed

const LCD := Vector2(333, 480)
const OKJA_FEET := Vector2(LCD.x / 2.0, 392)
const OkjaScript := preload("res://scripts/okja.gd")

var _nick := "손님"
var _stage := "comfy"     # 도달 단계("regular"|"comfy") — 컷인 데이터 키
var _lines: Array = []    # [{text:String, expr:StringName}] — okja_cutin[stage].lines
var _reveal := ""         # 마지막 줄 후 해금 줄
var _badge_text := ""     # 골드 배지 문구
var _idx := 0
var _unlocked := false  # 마지막 줄 후 해금 배지를 띄웠나
var _okja: Okja
var _panel: Panel
var _line: Label
var _hint: Label
var _badge: Control


## nick + 도달 단계("regular"|"comfy")로 컷인 데이터를 로드한다. 데이터 없으면 빈 시퀀스(즉시 닫힘).
func setup(nick: String, stage: String = "comfy") -> void:
  _nick = nick
  _stage = stage
  var data := Dialogue.okja_cutin(stage, nick)
  _lines = data.get("lines", [])
  _reveal = data.get("reveal", "")
  _badge_text = data.get("badge", "")


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP

  # 데이터가 비었으면(누락/오타) 연출 없이 즉시 닫는다 — 입장 흐름을 막지 않게.
  if _lines.is_empty():
    push_warning("StageCutin: okja_cutin['%s'] 비어 있음 — 컷인 생략" % _stage)
    call_deferred("_close")
    return

  # 1) 묵직한 딤(컷인 — 집중)
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.86, 0.25)

  # 2) 가운데 옥자 (자체 인스턴스 — 카페와 독립)
  _okja = OkjaScript.new()
  _okja.position = OKJA_FEET
  _okja.modulate.a = 0.0
  add_child(_okja)
  _okja.set_expression(_lines[0]["expr"])
  create_tween().tween_property(_okja, "modulate:a", 1.0, 0.3)

  # 3) 하단 대사 패널
  _panel = Panel.new()
  var pw := 297.0
  var ph := 78.0
  _panel.position = Vector2((LCD.x - pw) / 2.0, 392)
  _panel.size = Vector2(pw, ph)
  _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.BURGUNDY_DARK.r, Palette.BURGUNDY_DARK.g, Palette.BURGUNDY_DARK.b, 0.96)
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD
  _panel.add_theme_stylebox_override("panel", sb)
  add_child(_panel)

  _line = _make_label(Palette.CREAM, Fonts.SIZE_BODY)
  _line.position = _panel.position + Vector2(10, 8)
  _line.size = Vector2(pw - 20, ph - 16)
  _line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  add_child(_line)

  _hint = _make_label(Palette.GREY_300, Fonts.SIZE_SMALL)
  _hint.text = "OK ▶ 계속"
  _hint.position = Vector2(0, _panel.position.y + _panel.size.y + 4)
  _hint.size = Vector2(LCD.x, 14)
  add_child(_hint)

  _show_line()


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (Cafe → 여기). OK/SELECT/CANCEL 전부 '계속'(스킵 불가, 짧으니 끝까지).
func handle_shell_action(_action: StringName) -> void:
  _advance()


func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _advance()
    accept_event()


## 한 줄 진행 → 마지막 줄 후 해금 배지 → 한 번 더로 닫힘.
func _advance() -> void:
  if _idx < _lines.size() - 1:
    _idx += 1
    _okja.set_expression(_lines[_idx]["expr"])
    _show_line()
  elif not _unlocked:
    _reveal_unlock()
  else:
    _close()


func _show_line() -> void:
  # text 는 setup 에서 {nick} 치환 완료된 사본 — 그대로 표시.
  _line.text = String(_lines[_idx]["text"])


## 마지막 줄 후 — 해금 줄 + 골드 배지 + 옥자 폴짝(리워드 순간). 한 번 더로 닫힘.
func _reveal_unlock() -> void:
  _unlocked = true
  _okja.hop()  # smile 재사용 폴짝(리워드 순간)
  _line.text = _reveal
  _hint.text = "OK ▶ 닫기"

  _badge = _make_badge(_badge_text)
  add_child(_badge)


func _close() -> void:
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.2)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


# ── 헬퍼 ─────────────────────────────────────────────────

## 화면 상단 '반말 해금' 골드 배지 (맥동 등장).
func _make_badge(text: String) -> Control:
  var holder := Control.new()
  holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var lb := Label.new()
  lb.text = text
  lb.add_theme_font_size_override("font_size", Fonts.SIZE_TITLE)
  lb.add_theme_color_override("font_color", Palette.GOLD)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 3)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.position = Vector2(0, 96)
  lb.size = Vector2(LCD.x, 28)
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  holder.add_child(lb)

  holder.scale = Vector2(0.6, 0.6)
  holder.pivot_offset = Vector2(LCD.x / 2.0, 110)
  var t := create_tween()
  t.tween_property(holder, "scale", Vector2.ONE, 0.32) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  return holder


func _make_label(color: Color, font_size: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.add_theme_constant_override("line_spacing", 4)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
