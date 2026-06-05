class_name ChekiSlot
extends Control
## 컬렉션북 칸 1개 (T16 + 장식 패스) — 3-상태 렌더 + 코너 브래킷 포커스. (→ ADR 0002·0003 / 장식 합의 2026-06-05)
##
## 상태(Cheki.grade + Events.cheki_art_ready 로 판정):
##   owned  = 보유 → ChekiCard 재사용(사진 면 고정, 플립 안 함). 탭 → 확대 모달.
##   empty  = 아트 준비됨·미보유 → 표지(뒷면) 디밍 재활용 + ✦반짝임 참 + 점선 골드 외곽 + 데이 라벨.
##            "지금 채울 수 있다"는 능동적 초대.
##   locked = 아트 미준비(미래 이벤트) → 표지 더 디밍 + 봉인 스크림 + 왁스 봉랍 참 + 데이 라벨.
##            "봉인된 미래"(콘텐츠 예고). ⚠️ 데모 동안 이름 노출, 데모 후 미스터리("??? 데이")로 전환 예정.
##   ⚠️ empty/locked 둘 다 "표지를 보이며 꽂힌 카드"(미보유 = 뒤집힌 카드) — 차이는 참 + 디밍/스크림으로만.
##
## 포커스(평면 링 SELECT)=set_focused() → 코너 브래킷 + 살짝 떠오름(hop) + 은은한 골드 글로우.
##   시각 요소는 _content 안에 모아 GridContainer 레이아웃과 싸우지 않고 hop 한다.
## 슬롯 자체는 카드 native 풋프린트(120×180). 위를 덮는 투명 Button → pressed(터치/포커스 공통).

const STATE_OWNED := "owned"
const STATE_EMPTY := "empty"
const STATE_LOCKED := "locked"

# 미보유 표지 디밍 강도(재활용 표지를 얼마나 어둡게) — empty 는 읽히게, locked 는 봉인되게.
const DIM_EMPTY := Color(0.66, 0.62, 0.68)
const DIM_LOCKED := Color(0.42, 0.42, 0.52)

const HOP := 3.0  # 포커스 시 떠오르는 픽셀

signal pressed

var character: String
var event: String
var state: String = STATE_LOCKED

var _content: Control      # 모든 시각 요소(hop 단위)
var _glow: Panel           # 포커스 골드 글로우(평소 투명)
var _brackets: FocusBrackets
var _hop_tw: Tween
var _glow_tw: Tween


## 칸 식별자 주입(트리 진입 전). _ready 에서 상태 판정 후 렌더.
func setup(character_id: String, event_id: String) -> void:
  character = character_id
  event = event_id


func _ready() -> void:
  custom_minimum_size = ChekiCard.CARD
  size = ChekiCard.CARD
  state = _resolve_state()

  _build_glow()  # 콘텐츠 뒤(먼저 추가)
  _content = Control.new()
  _content.size = ChekiCard.CARD
  _content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_content)

  match state:
    STATE_OWNED: _build_owned()
    STATE_EMPTY: _build_unowned(false)
    STATE_LOCKED: _build_unowned(true)

  _build_brackets()  # 콘텐츠 맨 위(hop 같이)
  _build_touch()


## 보유 가능 여부(owned 만 모달을 연다). CollectionBook 의 prev/next 스코프 필터.
func is_owned() -> bool:
  return state == STATE_OWNED


## 평면 링 포커스 표시 — 코너 브래킷 + hop + 글로우.
func set_focused(focused: bool) -> void:
  if _brackets:
    _brackets.visible = focused
  _set_glow(focused)
  _hop(focused)


# ── 상태 판정 ─────────────────────────────────────────────

func _resolve_state() -> String:
  if Cheki.owned(character, event):
    return STATE_OWNED
  if Events.cheki_art_ready(event):
    return STATE_EMPTY
  return STATE_LOCKED


# ── 렌더 ─────────────────────────────────────────────────

## 보유 칸 — ChekiCard 재사용. 사진 면 고정(그리드에선 플립 안 함, 탭=모달).
func _build_owned() -> void:
  var r := Cheki.record(character, event)
  var card := ChekiCard.new()
  _content.add_child(card)
  card.setup(character, event, bool(r["butterfly"]),
    String(r["nickname"]), int(r["acquired_at"]))
  card.show_face(true)  # 사진 면 고정


## 미보유 칸 — 표지(공용 레이어) 디밍 재활용 + 참으로 empty/locked 구분.
func _build_unowned(locked: bool) -> void:
  var dim := DIM_LOCKED if locked else DIM_EMPTY

  # 1) 디밍된 표지 배경(파치먼트) — "뒤집힌 카드가 꽂힘"
  var cover := TextureRect.new()
  cover.texture = _tex(ChekiCard.COVER_BG)
  cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  cover.size = ChekiCard.CARD
  cover.modulate = dim
  cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _content.add_child(cover)

  # 2) 디밍된 등급 엠블럼(일반=날개) — 표지 공용 레이어
  var emblem := TextureRect.new()
  emblem.texture = _tex(ChekiCard.EMBLEM_WING)
  emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  if emblem.texture:
    emblem.size = emblem.texture.get_size()
    emblem.position = Vector2((ChekiCard.CARD.x - emblem.size.x) / 2.0, 52)
  emblem.modulate = dim
  emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _content.add_child(emblem)

  if locked:
    # 3-L) 봉인 스크림(더 어둡게)
    var scrim := ColorRect.new()
    scrim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.35)
    scrim.size = ChekiCard.CARD
    scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _content.add_child(scrim)
  else:
    # 3-E) 점선 느낌 골드 외곽(채울 수 있음 신호) — book_*.png 불필요, StyleBox
    var outline := Panel.new()
    outline.size = ChekiCard.CARD
    outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0, 0, 0, 0)
    sb.set_corner_radius_all(4)
    sb.set_border_width_all(1)
    sb.border_color = Palette.GOLD_DARK
    outline.add_theme_stylebox_override("panel", sb)
    _content.add_child(outline)

  # 4) 참(charm) — empty=✦반짝임 / locked=왁스 봉랍 (유일한 구분자)
  var charm := CardCharm.new()
  charm.setup(CardCharm.KIND_SEAL if locked else CardCharm.KIND_SPARKLE)
  charm.position = (ChekiCard.CARD - CardCharm.SIZE) / 2.0 + Vector2(0, -4)
  _content.add_child(charm)

  # 5) 데이 라벨(예고형) + 상태 문구
  var name_lb := _make_label(Fonts.SIZE_SMALL, Palette.GREY_200 if not locked else Palette.GREY_300, HORIZONTAL_ALIGNMENT_CENTER)
  name_lb.text = Events.cheki_day_label(event)
  name_lb.position = Vector2(2, ChekiCard.CARD.y - 36)
  name_lb.size = Vector2(ChekiCard.CARD.x - 4, 14)
  _content.add_child(name_lb)

  var note := _make_label(Fonts.SIZE_SMALL, Palette.GREY_400, HORIZONTAL_ALIGNMENT_CENTER)
  note.text = "준비중" if locked else "모으는 중"
  note.position = Vector2(2, ChekiCard.CARD.y - 20)
  note.size = Vector2(ChekiCard.CARD.x - 4, 14)
  _content.add_child(note)


## 포커스 글로우(평소 투명) — 콘텐츠 뒤에 깔리는 골드 헤일로.
func _build_glow() -> void:
  _glow = Panel.new()
  var pad := 4.0
  _glow.position = Vector2(-pad, -pad)
  _glow.size = ChekiCard.CARD + Vector2(pad * 2.0, pad * 2.0)
  _glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.30)
  sb.set_corner_radius_all(7)
  _glow.add_theme_stylebox_override("panel", sb)
  _glow.modulate.a = 0.0
  add_child(_glow)


## 포커스 코너 브래킷(평소 숨김) — 콘텐츠 맨 위(카드/표지를 덮음, hop 같이).
func _build_brackets() -> void:
  _brackets = FocusBrackets.new()
  _brackets.setup(ChekiCard.CARD)
  _brackets.visible = false
  _content.add_child(_brackets)


## 칸 전체를 덮는 투명 탭 버튼 → pressed 중계.
func _build_touch() -> void:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.size = ChekiCard.CARD
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(func() -> void: pressed.emit())
  add_child(btn)


# ── 포커스 모션 ───────────────────────────────────────────

func _hop(focused: bool) -> void:
  if _hop_tw and _hop_tw.is_valid():
    _hop_tw.kill()
  _hop_tw = create_tween()
  _hop_tw.tween_property(_content, "position:y", (-HOP if focused else 0.0), 0.10) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_glow(focused: bool) -> void:
  if not _glow:
    return
  if _glow_tw and _glow_tw.is_valid():
    _glow_tw.kill()
  _glow_tw = create_tween()
  _glow_tw.tween_property(_glow, "modulate:a", (1.0 if focused else 0.0), 0.12)


# ── 헬퍼 ─────────────────────────────────────────────────

## 경로 → 텍스처(없으면 null — TextureRect 는 빈 채, 크래시 없음).
func _tex(path: String) -> Texture2D:
  if ResourceLoader.exists(path):
    return load(path) as Texture2D
  push_warning("[ChekiSlot] 텍스처 없음: %s (에디터에서 임포트 필요)" % path)
  return null


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
