class_name ExpansionSlide
extends Control
## 확장 슬라이드 (T21 잠긴 멤버) — 잠긴 탭 OK/터치 시 뜨는 "다음 업데이트 예고" 오버레이 1장.
##
## 컬렉션북 위 풀스크린 오버레이(CardDetail 패턴). collection_book 이 _slide 로 소유·위임한다.
## 파치먼트+가죽 톤(StyleBox — 신규 에셋 0)의 양피지 카드 한 장:
##   코드 실루엣(MemberSilhouette) · 멤버 이름 · "다음 업데이트에 만나요" · 펫 확장 한 줄.
## 입력: CANCEL / 바깥 탭 = 닫기(예고만 보여주는 정적 카드라 OK 동작 없음).

signal closed

const LCD := Vector2(333, 480)
const CARD := Vector2(220, 280)
# 펫 확장은 슬라이드 문구로만 예고(탭 없음). 코코·규종이=고양이, 선아·수아=강아지 → 중립 표현.
# (→ CONTEXT.md 펫 로스터 / T21 합의)
const PET_LINE := "그리고 곁을 지킬 친구들 — 코코·선아·수아·규종이"

var _name: String = ""
var _accent: Color = Palette.VIOLET
var _closing := false


## 멤버 이름 + 액센트 색 주입(트리 진입 전).
func setup(member_name: String, accent: Color) -> void:
  _name = member_name
  _accent = accent


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

  _build_card()


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계(CollectionBook → 여기). 예고 카드라 CANCEL/터치 닫기만 의미.
func handle_shell_action(action: StringName) -> void:
  match action:
    &"cancel": _close()
    &"ok": _close()


func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _close()
    accept_event()


# ── 구성 ─────────────────────────────────────────────────

## 양피지 카드 — 가죽 톤 테두리 + 크림 바탕(StyleBox). 안에 실루엣·이름·예고 문구.
func _build_card() -> void:
  var card := Panel.new()
  card.position = (LCD - CARD) / 2.0
  card.size = CARD
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.CREAM            # 파치먼트(크림 속지)
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(4)
  sb.border_color = Palette.WOOD         # 가죽 톤 테두리
  sb.shadow_color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.5)
  sb.shadow_size = 8
  card.add_theme_stylebox_override("panel", sb)
  card.mouse_filter = Control.MOUSE_FILTER_STOP  # 카드 안쪽 탭은 닫힘 방지(딤만 닫기)
  add_child(card)

  # 골드 속테두리(앤틱 액자 느낌) — StyleBox 한 겹 더.
  var inner := Panel.new()
  inner.position = Vector2(6, 6)
  inner.size = CARD - Vector2(12, 12)
  inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var isb := StyleBoxFlat.new()
  isb.bg_color = Color(0, 0, 0, 0)
  isb.set_corner_radius_all(7)
  isb.set_border_width_all(1)
  isb.border_color = Palette.GOLD_DARK
  inner.add_theme_stylebox_override("panel", isb)
  card.add_child(inner)

  # 코드 실루엣 — 카드 상단 중앙.
  var sil := MemberSilhouette.new()
  var sil_box := Vector2(96, 96)
  sil.setup(sil_box, _accent.darkened(0.35))
  sil.position = Vector2((CARD.x - sil_box.x) / 2.0, 26)
  card.add_child(sil)

  # 봉랍 — 실루엣 위 작게(잠김 표식, 신규 에셋 0).
  var seal := CardCharm.new()
  seal.setup(CardCharm.KIND_SEAL)
  seal.position = Vector2(CARD.x / 2.0 - 12.0, 100.0)
  card.add_child(seal)

  # 이름(골드, 크게)
  var name_lb := _make_label(Fonts.SIZE_TITLE, Palette.GOLD)
  name_lb.text = _name
  name_lb.position = Vector2(0, 132)
  name_lb.size = Vector2(CARD.x, 28)
  card.add_child(name_lb)

  # "다음 업데이트에 만나요"
  var tease := _make_label(Fonts.SIZE_LEAD, Palette.WOOD_DARK)
  tease.text = "다음 업데이트에 만나요"
  tease.position = Vector2(8, 170)
  tease.size = Vector2(CARD.x - 16, 20)
  card.add_child(tease)

  # 구분 룰(골드)
  var rule := ColorRect.new()
  rule.color = Palette.GOLD_DARK
  rule.position = Vector2(40, 202)
  rule.size = Vector2(CARD.x - 80, 1)
  rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
  card.add_child(rule)

  # 펫 확장 한 줄(작게, 줄바꿈 허용)
  var pets := _make_label(Fonts.SIZE_SMALL, Palette.WOOD)
  pets.text = PET_LINE
  pets.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  pets.position = Vector2(14, 212)
  pets.size = Vector2(CARD.x - 28, 36)
  card.add_child(pets)

  # 닫기 힌트
  var hint := _make_label(Fonts.SIZE_SMALL, Palette.GREY_300)
  hint.text = "CANCEL ▶ 닫기"
  hint.position = Vector2(0, CARD.y - 22)
  hint.size = Vector2(CARD.x, 14)
  card.add_child(hint)


func _close() -> void:
  if _closing:
    return
  _closing = true
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


func _make_label(font_size: int, color: Color) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.CREAM)
  lb.add_theme_constant_override("outline_size", 1)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
