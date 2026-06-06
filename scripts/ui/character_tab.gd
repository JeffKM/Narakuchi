class_name CharacterTab
extends Control
## 캐릭터 색인 탭 — 미니 초상-only 정사각 칩. (→ 컬렉션북 개선 2026-06-06)
##
## 바인더 색인 은유: 초상만 노출, 활성/포커스는 바탕·테두리로만 구분 / locked=왁스 봉랍.
##   - 초상은 portrait_{id}.png(24×24) 훅. 없으면 캐릭터색 플레이스홀더 박스.
##   - 활성(현재 페이지)=버건디 바탕 + 굵은 골드 테두리. 포커스(평면 링 SELECT)=골드 테두리. 둘은 독립.
##   - 이름은 탭에서 제거 → 헤더("체키북 · 옥자")가 방향감을 담당(CollectionBook).
##
## 슬롯과 같은 관용구: 시각 요소 + 위를 덮는 투명 Button → pressed 중계(터치/포커스 공통 진입).

signal pressed

const TAB := Vector2(30, 30)       # 초상-only 정사각 칩(24 초상 + 사방 3 패딩)
const PORTRAIT := Vector2(24, 24)
const PAD := 3.0                   # (TAB - PORTRAIT) / 2 — 초상 가운데 정렬

var id: String
var disp_name: String
var locked: bool = false
var accent: Color = Palette.GREY_500   # 잠긴 멤버 실루엣 구분색 (locked 일 때만 사용)

var _bg: Panel
var _active := false
var _focused := false


## 식별자 주입(트리 진입 전). accent 는 잠긴 멤버 실루엣 색(멤버 구분).
func setup(tab_id: String, name: String, is_locked: bool, member_accent: Color = Palette.GREY_500) -> void:
  id = tab_id
  disp_name = name
  locked = is_locked
  accent = member_accent


func _ready() -> void:
  custom_minimum_size = TAB
  size = TAB

  _bg = Panel.new()
  _bg.size = TAB
  _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_bg)

  if locked:
    _build_locked()
  else:
    _build_portrait()

  _build_touch()
  _refresh()


## 현재 페이지 탭 여부(강조 바탕).
func set_active(active: bool) -> void:
  _active = active
  _refresh()


## 평면 링 포커스 여부(골드 테두리).
func set_focused(focused: bool) -> void:
  _focused = focused
  _refresh()


# ── 구성 ─────────────────────────────────────────────────

## 잠긴 멤버 — 코드 실루엣(누구인지 미공개) + 우하단 작은 왁스 봉랍 배지(잠김 표식, 신규 에셋 0).
func _build_locked() -> void:
  var sil := MemberSilhouette.new()
  sil.setup(PORTRAIT, accent.darkened(0.3))
  sil.position = Vector2(PAD, PAD)
  add_child(sil)

  # 봉랍 — 우하단 배지로 작게(실루엣을 가리지 않게 0.6배).
  var seal := CardCharm.new()
  seal.setup(CardCharm.KIND_SEAL)
  seal.scale = Vector2(0.62, 0.62)
  seal.position = Vector2(TAB.x - 17.0, TAB.y - 17.0)
  add_child(seal)


## 미니 초상 — portrait_{id}.png 훅(가운데 정렬), 없으면 캐릭터색 플레이스홀더.
func _build_portrait() -> void:
  var path := "res://assets/sprites/portrait_%s.png" % id
  if ResourceLoader.exists(path):
    var tr := TextureRect.new()
    tr.texture = load(path) as Texture2D
    tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tr.size = PORTRAIT
    tr.position = Vector2(PAD, PAD)
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(tr)
    return
  # 플레이스홀더: 캐릭터색 박스(옥자=버건디 / 시온이=그레이)
  var box := ColorRect.new()
  box.color = Palette.BURGUNDY if id == "okja" else Palette.GREY_300
  box.size = PORTRAIT
  box.position = Vector2(PAD, PAD)
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


## 활성/포커스 상태에 맞춰 바탕·테두리 갱신.
func _refresh() -> void:
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.BURGUNDY if _active else Palette.GREY_900
  # 탭 모양 — 윗모서리만 둥글게(아래 선반에 꽂힌 색인 혀)
  sb.corner_radius_top_left = 8
  sb.corner_radius_top_right = 8
  sb.corner_radius_bottom_left = 2
  sb.corner_radius_bottom_right = 2
  var hot := _active or _focused
  sb.set_border_width_all(2 if hot else 1)
  sb.border_color = Palette.GOLD if hot else Palette.GOLD_DARK
  _bg.add_theme_stylebox_override("panel", sb)
