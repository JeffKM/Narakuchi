class_name GroupChip
extends Control
## 그룹 토글 칩 — 체키북 탭 줄 좌측의 "메인"/"펫" 세그먼트. (→ 체키북 메인/펫 탭 분리 2026-06-10)
##
## CharacterTab 과 같은 관용구(시각 요소 + 투명 Button → pressed 중계, set_active/set_focused)로
## 평면 포커스 링이 탭과 균일하게 다룬다. 초상 대신 갈무리 텍스트 라벨(신규 에셋 0).
##   - 활성(현재 보는 그룹)=버건디 바탕 + 캔들 텍스트 + 굵은 골드 테두리.
##   - 비활성=먹빛 바탕 + 흐린 텍스트 + 얇은 골드다크 테두리.
##   - 포커스(평면 링 SELECT)=골드 테두리. 탭과 동일 언어라 한 줄에서 위화감 없다.

signal pressed

const CHIP := Vector2(30, 30)       # 탭과 같은 높이의 정사각 칩(한 줄 정렬)

var label_text: String

var _bg: Panel
var _lb: Label
var _active := false
var _focused := false


## 라벨 주입(트리 진입 전).
func setup(text: String) -> void:
  label_text = text


func _ready() -> void:
  custom_minimum_size = CHIP
  size = CHIP

  _bg = Panel.new()
  _bg.size = CHIP
  _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_bg)

  _lb = Label.new()
  _lb.text = label_text
  _lb.add_theme_font_size_override("font_size", Fonts.SIZE_SMALL)
  _lb.add_theme_color_override("font_outline_color", Palette.INK)
  _lb.add_theme_constant_override("outline_size", 2)
  _lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _lb.size = CHIP
  _lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_lb)

  _build_touch()
  _refresh()


## 현재 보는 그룹 여부(강조 바탕).
func set_active(active: bool) -> void:
  _active = active
  _refresh()


## 평면 링 포커스 여부(골드 테두리).
func set_focused(focused: bool) -> void:
  _focused = focused
  _refresh()


## 칩 전체를 덮는 투명 버튼 → pressed 중계(CharacterTab 과 동일 관용구).
func _build_touch() -> void:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.size = CHIP
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(func() -> void: pressed.emit())
  add_child(btn)


## 활성/포커스 상태에 맞춰 바탕·테두리·글자색 갱신(CharacterTab 탭 모양과 동일 언어).
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

  if _lb != null:
    _lb.add_theme_color_override("font_color", Palette.CANDLE if _active else Palette.GREY_300)
