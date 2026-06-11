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
const SCROLL_BAR_H := 6       # 가로 스크롤바 두께
const SCROLL_DEADZONE := 8    # 드래그-투-스크롤 임계(px): 이 이상 끌면 스크롤, 미만은 카드 탭으로 갈림
const ROW_H := 128 + 4 + SCROLL_BAR_H  # 카드 + 여백 + 바 (바가 카드 아래에 앉도록)
const POR_PX := 24          # 포트레이트 원본(도트)
const POR_VIEW := 72        # 카드 안 표시 크기(정수 ×3 → Nearest 또렷)

var _mode := MODE_ONBOARDING
var _sel_main := ""
var _sel_pet := ""
var _closing := false

var _main_cards := {}  # id → Button(카드)
var _pet_cards := {}   # id → Button(카드)
var _main_scroll: ScrollContainer  # 메인 카드 줄(인원 ↑ 시 가로 스크롤)
var _pet_scroll: ScrollContainer   # 펫 카드 줄(가로 스크롤)
var _confirm: Button
var _heart: HeartCursor
var _focus_nodes: Array = []  # 셸 커서 순환 대상: [{kind, group, id, node}] (카드들 + 결정 버튼)
var _cursor := 0

# 카드 위 드래그-투-스크롤 — 카드(Button)가 입력을 가로채 ScrollContainer가 못 받으므로 직접 처리한다.
var _drag_scroll: ScrollContainer = null  # 지금 끌고 있는 줄(누름 시작 시 결정)
var _drag_dist := 0.0                      # 누름 후 이동 누적(px) — 임계 넘으면 스크롤 제스처로 확정
var _drag_panning := false                 # 끌기로 확정됨 → release의 카드 클릭을 차단


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

  # 3) 메인 섹션 — 카드 가로 줄(인원이 폭을 넘으면 가로 스크롤).
  _add_section_label("메인", 56)
  _main_scroll = _build_card_row(Characters.mains(), _main_cards, Characters.MAIN, 74)

  # 4) 펫 섹션 (메인 줄이 바 자리만큼 길어져 살짝 내려 배치)
  _add_section_label("펫", 220)
  _pet_scroll = _build_card_row(Characters.pets(), _pet_cards, Characters.PET, 238)

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
  if _drag_panning:  # 끌어서 넘기는 중이면 선택 무시(accept_event가 놓친 경로 보조 방어)
    return
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


## id 목록을 가로 줄로 깐다 — 카드가 폭을 넘으면 가로 스크롤(터치 드래그 + 커서 자동 스크롤).
## 폭 안에 들면 가운데 정렬, 넘치면 8px 여백만 두고 스크롤. 신규 캐릭터가 늘어도 잘리지 않는다.
func _build_card_row(ids: Array, store: Dictionary, group: String, y: int) -> ScrollContainer:
  var scroll := ScrollContainer.new()
  scroll.position = Vector2(0, y)
  scroll.size = Vector2(LCD.x, ROW_H)  # 카드 + 바 자리(바가 카드 아래에 앉음)
  scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO   # 넘칠 때만 가로 바
  scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
  scroll.scroll_deadzone = SCROLL_DEADZONE  # 카드(Button) 위에서도 드래그하면 스크롤(모바일 터치 핵심)
  add_child(scroll)
  UiTheme.style_h_scrollbar(scroll.get_h_scroll_bar(), SCROLL_BAR_H)  # LCD 톤 얇은 캡슐 바

  var n := ids.size()
  if n == 0:
    return scroll
  # 내용이 폭에 들면 가운데, 넘치면 8px 양옆 여백. 카드는 plain Control 위에 절대배치(레이아웃 지연 없음).
  var content_w := n * CARD.x + (n - 1) * CARD_GAP
  var pad: float = maxf(8.0, (LCD.x - content_w) / 2.0)
  var inner := Control.new()
  inner.custom_minimum_size = Vector2(content_w + pad * 2.0, CARD.y)
  inner.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 빈 영역 드래그는 스크롤로, 카드는 그대로 클릭
  scroll.add_child(inner)

  for i in range(n):
    var id := String(ids[i])
    var card := _make_card(group, id)
    card.position = Vector2(pad + i * (CARD.x + CARD_GAP), 0)
    card.gui_input.connect(_on_card_drag.bind(scroll))  # 카드 위에서 끌면 이 줄을 가로 스크롤
    inner.add_child(card)
    store[id] = card
  return scroll


## 카드 위 드래그를 가로 스크롤로 — 카드는 Button(STOP)이라 ScrollContainer의 드래그 팬이 닿지 않는다.
## gui_input 시그널은 Button 내부 클릭 처리보다 먼저 오므로, 끌기로 확정되면 accept_event()로 클릭을 먹는다.
## 짧은 탭(임계 미만)은 그대로 흘려 카드 선택(_select)이 살아난다.
func _on_card_drag(event: InputEvent, scroll: ScrollContainer) -> void:
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    if event.pressed:
      _drag_scroll = scroll  # 이 줄을 끌 후보로
      _drag_dist = 0.0
      _drag_panning = false  # 새 누름마다 초기화(_select 가드의 단일 출처)
    else:
      if _drag_panning:
        accept_event()       # 끌었다면 이 release를 먹어 카드 클릭(_select) 차단
      _drag_scroll = null     # _drag_panning은 다음 누름까지 남겨 _select 가드를 보조
  elif event is InputEventMouseMotion and _drag_scroll == scroll:
    var dx: float = event.relative.x
    if dx == 0.0:
      return
    _drag_dist += absf(dx)
    scroll.scroll_horizontal -= int(round(dx))
    if _drag_dist > SCROLL_DEADZONE:
      _drag_panning = true
      accept_event()          # 끄는 동안 버튼 호버/프레스 시각 처리도 차단


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
## 카드는 스크롤 안에 있으니 ① 화면 밖이면 자동 스크롤 ② 하트는 스크롤 오프셋을 반영한 self 좌표로.
func _update_cursor() -> void:
  var item: Dictionary = _focus_nodes[_cursor]
  UiTheme.set_button_focused(_confirm, item["kind"] == "confirm")
  var node: Control = item["node"]
  if item["kind"] == "card":
    var scroll: ScrollContainer = _main_scroll if String(item["group"]) == Characters.MAIN else _pet_scroll
    scroll.ensure_control_visible(node)  # 커서 카드가 줄 밖이면 끌어와 보이게
    var hx := scroll.position.x + node.position.x - scroll.scroll_horizontal + node.size.x / 2.0
    var hy := scroll.position.y + node.position.y - 6.0
    _heart.position = Vector2(hx, hy)
  else:
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
