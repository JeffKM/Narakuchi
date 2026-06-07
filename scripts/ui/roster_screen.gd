class_name RosterScreen
extends Control
## 로스터 선택 화면 (캐릭터 확장 #3) — 함께할 메인 + 펫을 자유 조합으로 고른다.
##
## 재사용 오버레이: ① 온보딩 첫 선택(반드시 결정) ② 카페에서 active_main·active_pet 교체(취소 가능).
## 메인(옥자·미호…)·펫(시온이…)을 Characters 레지스트리에서 데이터 주도로 카드화한다 —
##   신규 캐릭터는 레지스트리 1항 + 포트레이트만 있으면 카드가 저절로 늘어난다(잠금/화폐는 최후).
##
## 셸 3버튼 하이브리드: SELECT 커서 순환 · OK 카드 선택/결정 · CANCEL 취소(스왑만, 온보딩은 무시).
## 결정 시 confirmed(main_id, pet_id) 1회 방출 후 닫힘. 호출부가 저장·교체를 처리한다(단일 책임).
## LCD(333×480) 전체를 덮어 뒤(카페/온보딩) 입력을 막는다.

signal confirmed(main_id: String, pet_id: String)
signal closed

const LCD := Vector2(333, 480)
const MODE_ONBOARDING := "onboarding"
const MODE_SWAP := "swap"

const CARD := Vector2(96, 128)
const CARD_GAP := 14
const POR_PX := 24          # 포트레이트 원본(도트)
const POR_VIEW := 72        # 카드 안 표시 크기(정수 ×3 → Nearest 또렷)

var _mode := MODE_ONBOARDING
var _sel_main := ""
var _sel_pet := ""
var _closing := false

var _main_cards := {}  # id → Button(카드)
var _pet_cards := {}   # id → Button(카드)
var _confirm: Button
var _heart: HeartCursor
var _focus_nodes: Array = []  # 셸 커서 순환 대상: [{kind, group, id, node}] (카드들 + 결정 버튼)
var _cursor := 0


## 진입 전 주입 — 모드 + 현재 활성 메인/펫(스왑은 그 값을 미리 고른 상태로 연다).
func setup(mode: String, current_main := "", current_pet := "") -> void:
  _mode = mode
  _sel_main = current_main if Characters.is_main(current_main) else Characters.default_main()
  var pets := Characters.pets()
  _sel_pet = current_pet if current_pet in pets else Characters.default_pet()


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤(카페/온보딩) 입력 차단
  Sfx.event(&"popup_open")

  # 1) 딤 배경 — 선택에 집중하도록 충분히 어둑하게. 스왑이면 빈 곳 탭으로 닫기.
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.86, 0.2)

  # 2) 제목
  var title := _make_label(Palette.CANDLE, Fonts.SIZE_TITLE)
  title.text = "함께할 친구를 골라요" if _mode == MODE_ONBOARDING else "교체"
  title.position = Vector2(0, 20)
  title.size = Vector2(LCD.x, 28)
  add_child(title)

  # 3) 메인 섹션 — 카드 가로 정렬(가운데).
  _add_section_label("메인", 56)
  _build_card_row(Characters.mains(), _main_cards, Characters.MAIN, 74)

  # 4) 펫 섹션
  _add_section_label("펫", 214)
  _build_card_row(Characters.pets(), _pet_cards, Characters.PET, 232)

  # 5) 결정 버튼
  _confirm = Button.new()
  _confirm.text = "이 친구로 시작" if _mode == MODE_ONBOARDING else "교체하기"
  _confirm.size = Vector2(220, 44)
  _confirm.position = Vector2((LCD.x - 220) / 2.0, 404)
  UiTheme.style_button(_confirm)
  _confirm.add_theme_font_size_override("font_size", Fonts.SIZE_LEAD)
  _confirm.pressed.connect(_confirm_pick)
  add_child(_confirm)

  # 6) 포커스 골드 하트 커서
  _heart = HeartCursor.new()
  add_child(_heart)

  # 7) 입력 힌트
  var hint := _make_label(Palette.GREY_300, Fonts.SIZE_SMALL)
  hint.text = "SELECT ▶ 이동   OK ▶ 선택" if _mode == MODE_ONBOARDING \
    else "SELECT ▶ 이동   OK ▶ 선택   CANCEL ▶ 취소"
  hint.position = Vector2(0, 456)
  hint.size = Vector2(LCD.x, 14)
  add_child(hint)

  _build_focus_ring()
  _refresh_selection()
  _update_cursor()


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (호출부 → 여기). SELECT 순환 · OK 선택/결정 · CANCEL 취소(스왑만).
func handle_shell_action(action: StringName) -> void:
  if _closing:
    return
  match action:
    &"select": _move_cursor()
    &"ok": _activate(_cursor)
    &"cancel":
      if _mode == MODE_SWAP:
        _close()  # 변화 없이 닫기 — 호출부는 confirmed 가 없으면 그대로 유지


## 딤 탭: 온보딩은 무시(반드시 결정), 스왑은 빈 곳 탭으로 닫기.
func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    if _mode == MODE_SWAP:
      _close()
    accept_event()


## 셸 SELECT — 커서 다음 대상으로 순환.
func _move_cursor() -> void:
  Sfx.event(&"cursor_move")
  _cursor = (_cursor + 1) % _focus_nodes.size()
  _update_cursor()


## 커서가 가리키는 대상 실행 — 카드면 그 그룹 선택, 결정 버튼이면 확정.
func _activate(i: int) -> void:
  var item: Dictionary = _focus_nodes[i]
  match String(item["kind"]):
    "card": _select(String(item["group"]), String(item["id"]))
    "confirm": _confirm_pick()


## 카드 선택 — 그룹별 단일 선택을 갱신하고 테두리 강조를 다시 그린다.
func _select(group: String, id: String) -> void:
  if group == Characters.MAIN:
    _sel_main = id
  else:
    _sel_pet = id
  Sfx.event(&"tab_switch")
  _refresh_selection()


## 결정 — confirmed 1회 방출 후 닫는다. 저장·교체는 호출부 책임.
func _confirm_pick() -> void:
  if _closing:
    return
  Sfx.event(&"confirm")
  confirmed.emit(_sel_main, _sel_pet)
  _close()


# ── 구성 ─────────────────────────────────────────────────

## 섹션 라벨(좌측, 골드) — 카드 묶음 위 작은 머리글.
func _add_section_label(text: String, y: int) -> void:
  var lb := _make_label(Palette.GOLD, Fonts.SIZE_BODY)
  lb.text = text
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  lb.position = Vector2(20, y)
  lb.size = Vector2(LCD.x - 40, 18)
  add_child(lb)


## id 목록을 카드로 가로 가운데 정렬해 깐다(카드 수에 따라 폭 자동).
func _build_card_row(ids: Array, store: Dictionary, group: String, y: int) -> void:
  var n := ids.size()
  if n == 0:
    return
  var row_w := n * CARD.x + (n - 1) * CARD_GAP
  var x0 := (LCD.x - row_w) / 2.0
  for i in range(n):
    var id := String(ids[i])
    var card := _make_card(group, id)
    card.position = Vector2(x0 + i * (CARD.x + CARD_GAP), y)
    add_child(card)
    store[id] = card


## 카드 = 포트레이트 + 이름을 담은 버튼(스타일박스로 패널처럼). 클릭=그 그룹 선택.
func _make_card(group: String, id: String) -> Button:
  var card := Button.new()
  card.focus_mode = Control.FOCUS_NONE
  card.size = CARD
  card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  card.pressed.connect(_select.bind(group, id))

  # 포트레이트(24×24 → 72×72 정수 확대, Nearest)
  var por := TextureRect.new()
  var path := Characters.portrait(id)
  if ResourceLoader.exists(path):
    por.texture = load(path)
  por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  por.position = Vector2((CARD.x - POR_VIEW) / 2.0, 10)
  por.size = Vector2(POR_VIEW, POR_VIEW)
  por.mouse_filter = Control.MOUSE_FILTER_IGNORE
  card.add_child(por)

  # 이름(골드)
  var name_lb := _make_label(Palette.CREAM, Fonts.SIZE_BODY)
  name_lb.text = Characters.display_name(id)
  name_lb.position = Vector2(2, 86)
  name_lb.size = Vector2(CARD.x - 4, 18)
  card.add_child(name_lb)
  return card


## 셸 커서 순환 대상 모으기: 메인 카드 → 펫 카드 → 결정 버튼.
## 초기 커서는 현재 선택된 메인 카드(스왑은 활성 메인, 온보딩은 기본 메인).
func _build_focus_ring() -> void:
  _focus_nodes.clear()
  for id in Characters.mains():
    _focus_nodes.append({"kind": "card", "group": Characters.MAIN, "id": id, "node": _main_cards[id]})
  for id in Characters.pets():
    _focus_nodes.append({"kind": "card", "group": Characters.PET, "id": id, "node": _pet_cards[id]})
  _focus_nodes.append({"kind": "confirm", "group": "", "id": "", "node": _confirm})
  # 시작 커서를 선택된 메인 카드로.
  for i in range(_focus_nodes.size()):
    var it: Dictionary = _focus_nodes[i]
    if it["kind"] == "card" and it["group"] == Characters.MAIN and it["id"] == _sel_main:
      _cursor = i
      break


## 선택 상태 시각화 — 그룹별로 고른 카드만 액센트 테두리(밝은 바탕), 나머지는 차분하게.
func _refresh_selection() -> void:
  for id in _main_cards:
    _style_card(_main_cards[id], id == _sel_main, Characters.accent(id))
  for id in _pet_cards:
    _style_card(_pet_cards[id], id == _sel_pet, Characters.accent(id))


## 카드 스타일박스 — 선택=액센트 테두리 + 살짝 밝은 버건디, 비선택=차분한 회색 테두리.
func _style_card(card: Button, selected: bool, accent: Color) -> void:
  var sb := StyleBoxFlat.new()
  if selected:
    sb.bg_color = Color(Palette.BURGUNDY.r, Palette.BURGUNDY.g, Palette.BURGUNDY.b, 0.96)
    sb.set_border_width_all(3)
    sb.border_color = accent
  else:
    sb.bg_color = Color(Palette.CHARCOAL.r, Palette.CHARCOAL.g, Palette.CHARCOAL.b, 0.92)
    sb.set_border_width_all(2)
    sb.border_color = Palette.GREY_700
  sb.set_corner_radius_all(8)
  sb.shadow_color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.5)
  sb.shadow_size = 4
  for state in ["normal", "hover", "pressed"]:
    card.add_theme_stylebox_override(state, sb)


## 포커스 표시 — 커서가 가리키는 대상 위에 골드 하트. 결정 버튼은 강조 틀까지.
func _update_cursor() -> void:
  UiTheme.set_button_focused(_confirm, _focus_nodes[_cursor]["kind"] == "confirm")
  var node: Control = _focus_nodes[_cursor]["node"]
  _heart.position = node.position + Vector2(node.size.x / 2.0, -6)


func _close() -> void:
  if _closing:
    return
  _closing = true
  Sfx.event(&"popup_close")
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


func _make_label(color: Color, font_size: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
