class_name CardDetail
extends Control
## 컬렉션북 카드 확대 모달 (T16 + T17 잔여 내비) — 보유 카드 풀뷰 + 플립 + 이전/다음. (→ ADR 0003)
##
## ChekiReveal(획득 언박싱)과 목적이 달라 별도 컴포넌트. ChekiCard 만 공유한다.
##   - 진입 시 사진 면부터(그리드와 연속감). OK/탭 → 플립(사진↔표지).
##   - SELECT(또는 ◀▶) → 현재 캐릭터의 "보유" 칸만 순환(없는 카드는 못 봄).
##   - 공유 버튼은 자리만(스텁) — 실제 이미지 내보내기는 T19.
## 셸 3버튼: OK=플립 · SELECT=다음 · CANCEL=닫기. 터치는 카드=플립 / ◀▶=내비 / 공유.
## LCD(333×480) 전체를 덮는 오버레이. 닫히면 closed 신호.

signal closed

const LCD := Vector2(333, 480)
const DISPLAY := 2.0  # 120×180 → 240×360

var _character: String
var _events: Array          # 현재 캐릭터의 보유 이벤트 id(LIST 순서)
var _index: int = 0

var _card: ChekiCard
var _caption: Label
var _hint: Label
var _closing := false


## 보유 카드 목록 + 시작 인덱스 주입(트리 진입 전).
func setup(character_id: String, owned_events: Array, start_index: int) -> void:
  _character = character_id
  _events = owned_events
  _index = clampi(start_index, 0, max(0, owned_events.size() - 1))


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤(책) 입력 차단

  # 딤 배경(탭하면 닫기)
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.82, 0.2)

  # 카드(2배 홀더) — 화면 중앙(캡션 자리 위로 살짝)
  var holder := Control.new()
  var card_size := ChekiCard.CARD * DISPLAY
  holder.position = (LCD - card_size) / 2.0 + Vector2(0, -16)
  holder.scale = Vector2(DISPLAY, DISPLAY)
  holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(holder)

  _card = ChekiCard.new()
  holder.add_child(_card)

  # 이전/다음 화살표(터치) — 카드 좌우
  _make_nav_arrow("◀", 8, func() -> void: _step(-1))
  _make_nav_arrow("▶", LCD.x - 32, func() -> void: _step(1))

  # 캡션(이벤트명) + 입력 힌트
  _caption = _make_label(Fonts.SIZE_BODY, Palette.CANDLE, 408)
  add_child(_caption)
  _hint = _make_label(Fonts.SIZE_SMALL, Palette.GREY_300, 436)
  _hint.text = "OK ▶ 뒤집기 · SELECT ▶ 다음 · CANCEL ▶ 닫기"
  add_child(_hint)

  # 공유 버튼(스텁 — 동작은 T19)
  _build_share_button()

  _render()


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (CollectionBook → 여기).
func handle_shell_action(action: StringName) -> void:
  match action:
    &"ok": _flip()
    &"select": _step(1)
    &"cancel": _close()


func _on_dim_input(event: InputEvent) -> void:
  # 딤(카드 바깥) 탭 = 닫기. 카드 자체 탭은 _card_button 이 플립으로 가져감.
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _close()
    accept_event()


# ── 동작 ─────────────────────────────────────────────────

## 보유 목록 내 이동(순환). 빈 목록이면 무시.
func _step(dir: int) -> void:
  if _events.size() <= 1:
    return
  _index = (_index + dir + _events.size()) % _events.size()
  _render()


func _flip() -> void:
  if _card:
    _card.flip()


func _close() -> void:
  if _closing:
    return
  _closing = true
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


## 현재 인덱스 카드로 갱신(사진 면부터).
func _render() -> void:
  if _events.is_empty():
    _close()
    return
  var ev := String(_events[_index])
  var r := Cheki.record(_character, ev)
  _card.setup(_character, ev, bool(r["butterfly"]),
    String(r["nickname"]), int(r["acquired_at"]))
  _card.show_face(true)  # 사진 면부터(그리드와 연속감)
  _caption.text = Events.cheki_day_label(ev)
  # 카드 위 탭 영역(플립) — 매 렌더 보장(setup 으로 내부가 재구성되진 않으나 안전)
  _ensure_card_button()


# ── 구성 헬퍼 ─────────────────────────────────────────────

## 카드 위 투명 버튼(탭=플립). 딤 탭(닫기)과 분리.
func _ensure_card_button() -> void:
  if has_node("CardButton"):
    return
  var card_size := ChekiCard.CARD * DISPLAY
  var btn := Button.new()
  btn.name = "CardButton"
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = (LCD - card_size) / 2.0 + Vector2(0, -16)
  btn.size = card_size
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(_flip)
  add_child(btn)


func _make_nav_arrow(glyph: String, x: float, cb: Callable) -> void:
  if _events.size() <= 1:
    return  # 한 장뿐이면 화살표 숨김
  var btn := Button.new()
  btn.text = glyph
  UiTheme.style_button(btn)
  btn.position = Vector2(x, LCD.y / 2.0 - 28)
  btn.size = Vector2(24, 40)
  btn.pressed.connect(cb)
  add_child(btn)


## 공유 버튼(스텁) — 하단. T19 에서 이미지 내보내기로 채움.
func _build_share_button() -> void:
  var btn := Button.new()
  btn.text = "공유 (준비중)"
  UiTheme.style_button(btn)
  btn.position = Vector2(LCD.x / 2.0 - 56, 456)
  btn.size = Vector2(112, 22)
  btn.pressed.connect(func() -> void:
    _hint.text = "공유는 곧 — 이미지 내보내기 준비중")
  add_child(btn)


func _make_label(font_size: int, color: Color, y: float) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.position = Vector2(0, y)
  lb.size = Vector2(LCD.x, 18)
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
