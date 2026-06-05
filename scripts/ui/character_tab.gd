class_name CharacterTab
extends Control
## 캐릭터 색인 탭 — 미니 초상 + (활성 시)이름. (→ 컬렉션북 장식 합의 2026-06-05)
##
## 바인더 색인 은유: 비활성=초상만 / 활성=초상+이름+강조 바탕 / locked=왁스 봉랍(이름·초상 없음).
##   - 초상은 portrait_{id}.png(24×24) 훅. 없으면 캐릭터색 플레이스홀더 박스.
##   - 활성(현재 페이지)=버건디 바탕 + 이름 노출. 포커스(평면 링 SELECT)=골드 테두리. 둘은 독립.
##
## 슬롯과 같은 관용구: 시각 요소 + 위를 덮는 투명 Button → pressed 중계(터치/포커스 공통 진입).

signal pressed

const TAB := Vector2(78, 30)
const PORTRAIT := Vector2(24, 24)

var id: String
var disp_name: String
var locked: bool = false

var _bg: Panel
var _name: Label
var _active := false
var _focused := false


## 식별자 주입(트리 진입 전).
func setup(tab_id: String, name: String, is_locked: bool) -> void:
  id = tab_id
  disp_name = name
  locked = is_locked


func _ready() -> void:
  custom_minimum_size = TAB
  size = TAB

  _bg = Panel.new()
  _bg.size = TAB
  _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_bg)

  if locked:
    # 잠긴 멤버 — 왁스 봉랍(참 재활용, 신규 에셋 0)
    var seal := CardCharm.new()
    seal.setup(CardCharm.KIND_SEAL)
    seal.position = (TAB - CardCharm.SIZE) / 2.0
    add_child(seal)
  else:
    _build_portrait()
    _name = _make_label(Fonts.SIZE_BODY, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
    _name.text = disp_name
    _name.position = Vector2(32, 0)
    _name.size = Vector2(TAB.x - 34, TAB.y)
    add_child(_name)

  _build_touch()
  _refresh()


## 현재 페이지 탭 여부(강조 바탕 + 이름).
func set_active(active: bool) -> void:
  _active = active
  _refresh()


## 평면 링 포커스 여부(골드 테두리).
func set_focused(focused: bool) -> void:
  _focused = focused
  _refresh()


# ── 구성 ─────────────────────────────────────────────────

## 미니 초상 — portrait_{id}.png 훅, 없으면 캐릭터색 플레이스홀더.
func _build_portrait() -> void:
  var path := "res://assets/sprites/portrait_%s.png" % id
  if ResourceLoader.exists(path):
    var tr := TextureRect.new()
    tr.texture = load(path) as Texture2D
    tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tr.size = PORTRAIT
    tr.position = Vector2(5, 3)
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(tr)
    return
  # 플레이스홀더: 캐릭터색 박스(옥자=버건디 / 시온이=그레이)
  var box := ColorRect.new()
  box.color = Palette.BURGUNDY if id == "okja" else Palette.GREY_300
  box.size = PORTRAIT
  box.position = Vector2(5, 3)
  box.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(box)


## 탭 전체를 덮는 투명 버튼 → pressed 중계.
func _build_touch() -> void:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.size = TAB
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(func() -> void: pressed.emit())
  add_child(btn)


## 활성/포커스 상태에 맞춰 바탕·이름 갱신.
func _refresh() -> void:
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.BURGUNDY if _active else Palette.GREY_900
  # 탭 모양 — 윗모서리만 둥글게
  sb.corner_radius_top_left = 8
  sb.corner_radius_top_right = 8
  sb.corner_radius_bottom_left = 2
  sb.corner_radius_bottom_right = 2
  var hot := _active or _focused
  sb.set_border_width_all(2 if hot else 1)
  sb.border_color = Palette.GOLD if hot else Palette.GOLD_DARK
  _bg.add_theme_stylebox_override("panel", sb)
  if _name:
    _name.visible = _active


func _make_label(font_size: int, color: Color, align: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = align
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
