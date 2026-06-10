class_name ChekiReveal
extends Control
## 체키 획득 리빌 (T13 + T18 라이트) — 게이지 풀 → "오늘의 체키" 언박싱. (→ ADR 0003)
##
## 시퀀스: 딤 + 표지 등장(닉네임·날짜 적힌) → OK/탭(또는 ~2.2s 후 자동)으로 뒤집어 의상 공개 → OK/탭 닫기.
## 나비 승급이면 지옥풍 나비 파티클. 셸 3버튼 하이브리드: OK=진행 · CANCEL=닫기 · 탭=진행.
## LCD(333×480) 전체를 덮는 오버레이. 닫히면 closed 신호.

signal closed

const LCD := Vector2(333, 480)
const DISPLAY := 2.0  # 카드 확대 배율 (120×180 → 240×360)

var _result: Dictionary
var _headline := ""     # 비면 일반 체키 획득, 채워지면 상단 배너(출석 마일스톤 보상 등 T14)
var _card: ChekiCard
var _rays: BurstRays    # 카드 뒤 골든 햇살 (T18)
var _caption: Label
var _hint: Label
var _share_btn: Button  # 사진 면 공개 후 노출되는 공유 버튼 (T19)
var _share: ShareCard   # 공유 이미지 오버레이 (열려 있으면 셸 입력을 여기로)
var _phase := "intro"   # intro → cover → photo → done
var _auto_tw: Tween


## result = Cheki.grant/add_shards 결과. headline 을 주면 상단에 보상 배너를 단다(T14 마일스톤).
func setup(result: Dictionary, headline: String = "") -> void:
  _result = result
  _headline = headline


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤(카페) 입력 차단

  # 딤 배경
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_gui_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.78, 0.25)

  # 카드 뒤 골든 햇살(딤 위, 홀더 아래) — 카드 중심에서 방사. (T18)
  _rays = BurstRays.new()
  _rays.position = Vector2(LCD.x / 2.0, LCD.y / 2.0 - 12)
  add_child(_rays)

  # 카드(2배 확대 홀더 안) — 화면 중앙
  var holder := Control.new()
  var card_size := ChekiCard.CARD * DISPLAY
  holder.position = (LCD - card_size) / 2.0 + Vector2(0, -12)  # 캡션 자리 살짝 위로
  holder.scale = Vector2(DISPLAY, DISPLAY)
  holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(holder)

  _card = ChekiCard.new()
  holder.add_child(_card)
  _card.setup(
    String(_result["character"]), String(_result["event"]),
    bool(_result["grade"] == Cheki.GRADE_BUTTERFLY),
    String(_result.get("nickname", "")), int(_result.get("acquired_at", 0)))
  _card.show_face(false)  # 표지부터

  # 캡션 + 입력 힌트 (카드 아래 — 카드는 화면 y≈48~408)
  _caption = _make_label(Fonts.SIZE_BODY, Palette.CANDLE, 414)
  _caption.text = _caption_text()
  add_child(_caption)

  _hint = _make_label(Fonts.SIZE_SMALL, Palette.GREY_300, 450)
  add_child(_hint)

  # 상단 보상 배너 (출석 마일스톤 등) — 카드 위쪽 골드 한 줄
  if _headline != "":
    var head := _make_label(Fonts.SIZE_TITLE, Palette.GOLD, 24)
    head.add_theme_constant_override("outline_size", 3)
    head.text = _headline
    add_child(head)

  # 획득 사운드 + 카드 뒤 햇살 버스트 (→ ADR 0004)
  Sfx.event(&"cheki_get")
  _rays.burst()

  # 표지 입장(페이드 + 상승 + 중앙 스케일 팝) → 끝나면 cover 단계 + 자동 플립 예약
  holder.modulate.a = 0.0
  holder.position.y += 16
  _card.scale = Vector2(0.7, 0.7)  # 중앙 피벗(ChekiCard pivot=중심)에서 팡 커짐
  var t := create_tween().set_parallel(true)
  t.tween_property(holder, "modulate:a", 1.0, 0.3)
  t.tween_property(holder, "position:y", holder.position.y - 16, 0.3) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  t.tween_property(_card, "scale", Vector2.ONE, 0.34) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  t.chain().tween_callback(_enter_cover)


# ── 단계 전이 ─────────────────────────────────────────────

func _enter_cover() -> void:
  _phase = "cover"
  _hint.text = "OK ▶ 뒤집기"
  # 미입력 시 ~2.2s 후 자동 플립(루프 안 막힘 — ADR 0003)
  _auto_tw = create_tween()
  _auto_tw.tween_interval(2.2)
  _auto_tw.tween_callback(func() -> void:
    if _phase == "cover":
      _do_flip())


func _do_flip() -> void:
  if _phase != "cover":
    return
  if _auto_tw and _auto_tw.is_valid():
    _auto_tw.kill()
  _phase = "photo"
  Sfx.event(&"card_flip")
  _card.flip()
  _hint.text = "OK ▶ 닫기"
  if bool(_result.get("upgraded", false)):
    Sfx.event(&"butterfly_upgrade")
    _spawn_butterflies()
  _show_share_button()  # 사진 공개 = 자랑하고 싶은 순간 → 공유 진입 (T19)


func _close() -> void:
  if _phase == "done":
    return
  _phase = "done"
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.18)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (Cafe → 여기). OK/SELECT=진행 · CANCEL=닫기. 공유 오버레이 떠 있으면 그쪽 우선.
func handle_shell_action(action: StringName) -> void:
  if _share != null:
    _share.handle_shell_action(action)
    return
  match action:
    &"ok": _advance()
    &"select":
      if _phase == "photo": _open_share()  # 사진 공개 후 SELECT = 공유(셸 전용 경로)
      else: _advance()
    &"cancel": _advance_or_close()


func _on_gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _advance()
    accept_event()


## 탭/OK: cover → 뒤집기, photo → 닫기. (intro/done 은 무시)
func _advance() -> void:
  match _phase:
    "cover": _do_flip()
    "photo": _close()


func _advance_or_close() -> void:
  # CANCEL: cover 면 곧장 닫기 거부감 줄이려 일단 뒤집고, photo 면 닫기.
  if _phase == "photo":
    _close()
  elif _phase == "cover":
    _do_flip()


# ── 공유 (T19) ────────────────────────────────────────────

## 사진 공개 후 "공유" 버튼을 띄운다(획득 직후 = 자랑하고 싶은 감정 피크). 한 번만 생성.
func _show_share_button() -> void:
  if _share_btn != null:
    return
  _hint.position.y = 466  # 버튼 자리 확보(힌트 한 줄 내림)
  _hint.text = "OK ▶ 닫기 · SELECT ▶ 공유"
  _share_btn = Button.new()
  _share_btn.text = "공유 ▶"
  UiTheme.style_button(_share_btn)
  _share_btn.size = Vector2(100, 24)
  _share_btn.position = Vector2((LCD.x - 100) / 2.0, 438)
  _share_btn.pressed.connect(_open_share)
  _share_btn.modulate.a = 0.0
  add_child(_share_btn)
  create_tween().tween_property(_share_btn, "modulate:a", 1.0, 0.2)


## 공유 이미지 오버레이 열기 — 현재 체키를 워터마크·QR 자리와 합성. (T19)
func _open_share() -> void:
  if _share != null:
    return
  Sfx.event(&"popup_open")  # 공유 오버레이 열기 → ADR 0004
  _share = ShareCard.new()
  _share.setup(
    String(_result["character"]), String(_result["event"]),
    bool(_result["grade"] == Cheki.GRADE_BUTTERFLY),
    String(_result.get("nickname", "")), int(_result.get("acquired_at", 0)))
  _share.closed.connect(func() -> void: _share = null)
  add_child(_share)  # 맨 위


# ── 연출 헬퍼 ─────────────────────────────────────────────

## 나비 승급 — 지옥풍 나비 파티클(셰이더 없이 라벨 트윈). 카드 위로 흩날림.
func _spawn_butterflies() -> void:
  var center := Vector2(LCD.x / 2.0, LCD.y / 2.0 - 12)
  for i in range(7):
    var p := Label.new()
    p.text = "★" if (i % 2 == 0) else "♡"  # 갈무리 지원 글자(✦·❀ 는 글리프 없어 두부)
    p.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
    p.add_theme_color_override("font_color", Palette.GOLD)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.position = center
    add_child(p)
    var ang := -PI / 2.0 + (float(i) - 3.0) * 0.4
    var dist := 70.0 + float(i % 3) * 18.0
    var dest := center + Vector2(cos(ang), sin(ang)) * dist
    var tw := create_tween().set_parallel(true)
    tw.tween_property(p, "position", dest, 0.7 + float(i) * 0.05) \
      .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(p, "modulate:a", 0.0, 0.8 + float(i) * 0.05)
    tw.chain().tween_callback(p.queue_free)


func _caption_text() -> String:
  var ev := Events.event_name(String(_result["event"]))
  if bool(_result.get("upgraded", false)):
    return "★ %s 체키, 나비로 승급! ★" % ev
  if bool(_result.get("was_new", false)):
    return "첫 %s 체키를 받았어요!" % ev
  var s := int(_result.get("shards", 0))
  var need := int(_result.get("shards_needed", Balance.BUTTERFLY_SHARDS_NEEDED))
  return "%s 체키 · 나비까지 %d/%d" % [ev, s, need]


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
