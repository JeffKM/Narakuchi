class_name Cafe
extends Node2D
## 메인 교감 화면 (T06a/T09/T10) — 배경 + 라이브 옥자 + HUD + 4버튼 + 한 줄 티커.
##
## 셸 LCD(333×480) 안에 올라간다. 셸 3버튼은 Main 이 handle_shell_action() 으로 중계:
##   SELECT → 커서 순환 · OK → 확인 · CANCEL → (현재는 미사용/뒤로)
## 4버튼 교감(T09) · 옥자 터치(T10) → Meters(T08) 로 호감도/스태미나/기분 처리.
## 보이스는 data/dialogue.gd 풀에서 골라 티커(T06a)에 띄운다.
##
## 미연시 핵심 연출은 후속:
##   - 게이지 풀 → 오늘의 체키 자동 획득(T13): 그랜트 + 리빌 오버레이(ChekiReveal) + 게이지 소진. ✅
##   - 대화 2지선다 분기 · 선물 선호표: T11 (지금은 간이 +호감도)
##   - 반말 전환 컷인: T11 (지금은 단계 상승 티커만)

const LCD_W := 333
const LCD_H := 480
const BG_TEX := "res://assets/sprites/bg_naraka.png"
const OkjaScript := preload("res://scripts/okja.gd")
const SioniScript := preload("res://scripts/sioni.gd")

const OKJA_FEET := Vector2(LCD_W / 2.0, 400)  # 발밑 기준 배치 (HUD 아래 ~ 액션바 위)
const SIONI_FEET := Vector2(266, 402)         # 옥자 오른쪽 발치(액션바 위·옥자와 안 겹침)

# 교감 대상 모드 — 옥자(기본) ↔ 시온이. 시온이 탭으로 진입, 옥자 탭/CANCEL 로 복귀. (T15)
const MODE_OKJA := "okja"
const MODE_SION := "sion"

var meters: Meters
var _okja: Okja
var _sioni: Sioni
var _hud: Hud
var _bar: ActionBar       # 옥자 4버튼
var _bar_sion: ActionBar  # 시온이 4버튼(평소 숨김)
var _ticker: Ticker
var _mode: String = MODE_OKJA
var _revert: Tween  # 옥자 표정 자동 복귀 트윈 (중복 시 이전 것 취소)
var _revert_sion: Tween  # 시온이 반응 자동 복귀 트윈
var _reveal: ChekiReveal  # 체키 획득 리빌 오버레이 (열려 있으면 셸 입력을 여기로)
var _book: CollectionBook  # 컬렉션북 오버레이 (T16, 열려 있으면 셸 입력을 여기로)


func _ready() -> void:
  add_to_group(&"cafe")  # DebugTools 가 찾아 debug_grant_cheki() 호출(디버그 빌드 전용)
  _build()


## Main 이 온보딩 후(또는 바로) 호출 — 세션 시작 + 맞이 보이스.
func start() -> void:
  meters.begin_session()
  _hud.refresh()
  var sit := "neglect" if meters.was_neglected else "enter"
  if meters.was_neglected:
    _okja.set_expression(&"sad")
  _ticker.show_line(Dialogue.okja_line(sit, meters.stage(), _nick()))


## 셸 3버튼 중계 (Main → Cafe). 오버레이(리빌 → 컬렉션북)가 떠 있으면 그쪽이 먼저 먹는다.
## SELECT/OK 는 현재 모드의 액션 바로, CANCEL 은 "뒤로"(시온이 모드 → 옥자 복귀 / 옥자 모드 → 책).
func handle_shell_action(action: StringName) -> void:
  if _reveal != null:
    _reveal.handle_shell_action(action)
    return
  if _book != null:
    _book.handle_shell_action(action)
    return
  var bar := _active_bar()
  match action:
    &"select": bar.move_cursor()
    &"ok": bar.activate_focused()
    &"cancel":
      if _mode == MODE_SION:
        _exit_sion_mode()  # 시온이 모드에선 CANCEL = 옥자에게 복귀
      else:
        _open_book()       # 옥자 모드에선 CANCEL = 컬렉션북 토글


## 현재 모드의 액션 바.
func _active_bar() -> ActionBar:
  return _bar_sion if _mode == MODE_SION else _bar


# ── 화면 구성 ─────────────────────────────────────────────

func _build() -> void:
  # 1) 나라카 지옥 배경 (LCD 꽉)
  var bg := Sprite2D.new()
  bg.texture = load(BG_TEX)
  bg.centered = false
  bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(bg)

  # 2) 라이브 옥자
  _okja = OkjaScript.new()
  _okja.position = OKJA_FEET
  add_child(_okja)

  # 2b) 라이브 시온이 (T15) — 옥자 발치 오른쪽. 탭하면 시온이 교감 모드.
  _sioni = SioniScript.new()
  _sioni.position = SIONI_FEET
  add_child(_sioni)

  # 3) 옥자 터치 영역 (T10) — 몸통 위 투명 버튼 (HUD/액션바와 겹치지 않게)
  _add_okja_touch()

  # 3a) 시온이 터치 영역 (T15) — 고양이 위 투명 버튼
  _add_sioni_touch()

  # 3b) 컬렉션북 진입 아이콘 (T16) — 우상단 배경 위(HUD·옥자와 안 겹침)
  _add_book_button()

  # 4) HUD (상단)
  _hud = Hud.new()
  add_child(_hud)

  # 5) 4버튼 액션 바 (T09 옥자 + T15 시온이) — 같은 자리, 모드에 따라 토글.
  _bar = ActionBar.new()
  _bar.action_chosen.connect(_on_action)
  add_child(_bar)

  _bar_sion = ActionBar.new()
  _bar_sion.configure(ActionBar.SION_ACTIONS)
  _bar_sion.action_chosen.connect(_on_action)
  _bar_sion.visible = false
  add_child(_bar_sion)

  # 6) 한 줄 티커 (맨 아래)
  _ticker = Ticker.new()
  _ticker.position = Vector2(0, LCD_H - Ticker.STRIP_H)
  add_child(_ticker)

  # 7) 미터 로직 (T08) — 신호 연결
  meters = Meters.new()
  meters.changed.connect(_hud.refresh)
  meters.gauge_full.connect(_on_gauge_full)
  meters.stage_changed.connect(_on_stage_changed)
  add_child(meters)

  _hud.refresh()


## 컬렉션북 진입 아이콘 — 우상단 배경(x250~333 / y30~112 빈 구간) 위 28×28.
## ⚠️ 임시 텍스트 아이콘("체키"). A3에서 도트 아이콘으로 교체.
func _add_book_button() -> void:
  var btn := Button.new()
  btn.text = "체키"
  UiTheme.style_button(btn)
  btn.add_theme_font_size_override("font_size", Fonts.SIZE_SMALL)
  btn.position = Vector2(295, 34)
  btn.size = Vector2(32, 24)
  btn.pressed.connect(_open_book)
  add_child(btn)


## 옥자 몸통 위 투명 터치 버튼.
func _add_okja_touch() -> void:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = Vector2(OKJA_FEET.x - 70, OKJA_FEET.y - 280)
  btn.size = Vector2(140, 280)
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(_on_okja_touch)
  add_child(btn)


## 시온이 위 투명 터치 버튼 (T15) — 발치 기준 48×48 + 약간 여유.
func _add_sioni_touch() -> void:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = Vector2(SIONI_FEET.x - 28, SIONI_FEET.y - 52)
  btn.size = Vector2(56, 52)
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  btn.pressed.connect(_on_sioni_touch)
  add_child(btn)


# ── 4버튼 교감 (T09 옥자 / T15 시온이) ─────────────────────

func _on_action(id: String) -> void:
  # 스태미나(옥자/시온이 공유) 게이트 — 소진 시 오늘 종료 (벌 없음, 내일 회복)
  if not meters.can_act():
    if _mode == MODE_SION:
      _react_sion(&"idle")
      _ticker.show_line(Dialogue.sion_line())
    else:
      _react(&"sad")  # 잠깐 시무룩 → 무표정 복귀
      _ticker.show_line(Dialogue.okja_line("no_stamina", meters.stage(), _nick()))
    return

  meters.spend_stamina()
  if _mode == MODE_SION:
    _on_sion_action(id)
    return

  match id:
    "cheki":
      meters.add_affinity_okja(Balance.AFF_CHEKI)
      _react(&"talk")
    "drink":
      meters.add_affinity_okja(Balance.AFF_DRINK)  # 선호 음료 보너스는 T11
      _brew()
    "talk":
      meters.add_affinity_okja(Balance.AFF_TALK_PLAIN)  # 분기 팝업은 T11
      _react(&"talk")
    "gift":
      meters.add_affinity_okja(Balance.AFF_GIFT_PLAIN)  # 선호표는 T11
      _react(&"shy")
  _ticker.show_line(Dialogue.okja_line(id, meters.stage(), _nick()))


## 시온이 4버튼(체키 주문/간식/놀기/쓰담) — 호감도 + 반응 스왑. (T15)
## 시온이는 펫이라 기분·관계 단계 없이 게이지만 쌓는다. 선호 간식 보너스·옥자 교차 보너스는 후속.
func _on_sion_action(id: String) -> void:
  match id:
    "cheki":
      meters.add_affinity_sion(Balance.AFF_CHEKI)
      _react_sion(&"play")
    "snack":
      meters.add_affinity_sion(Balance.AFF_SION)
      _react_sion(&"snack")
    "play":
      meters.add_affinity_sion(Balance.AFF_SION)
      _react_sion(&"play")
    "pet":
      meters.add_affinity_sion(Balance.AFF_SION)
      _react_sion(&"pet")
  _ticker.show_line(Dialogue.sion_line())


## 음료 제조 연출 — brew 표정 잠깐 → idle 복귀.
func _brew() -> void:
  _okja.set_expression(&"brew")
  _schedule_idle(1.1)


# ── 터치 리액션 / 모드 전환 (T10 / T15) ───────────────────

func _on_okja_touch() -> void:
  # 시온이 모드에서 옥자를 누르면 옥자에게 복귀.
  if _mode == MODE_SION:
    _exit_sion_mode()
    return
  var gained := meters.add_touch_affinity()
  if gained <= 0:
    # 세션 터치 상한 — 더는 호감도 안 오르고 살짝 짜증 보이스
    _react(&"shy")
    _ticker.show_line(Dialogue.okja_line("touch_cap", meters.stage(), _nick()))
    return
  # 부끄/웃음 번갈아 — 살아있는 반응
  _react(&"shy" if (randi() % 2 == 0) else &"smile")
  _ticker.show_line(Dialogue.okja_line("touch", meters.stage(), _nick()))


## 시온이 탭 — 옥자 모드면 시온이 교감 모드 진입, 이미 시온이 모드면 가벼운 반응.
func _on_sioni_touch() -> void:
  if _mode == MODE_OKJA:
    _enter_sion_mode()
    return
  _react_sion(&"pet" if (randi() % 2 == 0) else &"play")
  _ticker.show_line(Dialogue.sion_line())


## 시온이 교감 모드 진입 — 액션 바 교체 + HUD 게이지를 시온이로.
func _enter_sion_mode() -> void:
  if _mode == MODE_SION:
    return
  _mode = MODE_SION
  _bar.visible = false
  _bar_sion.visible = true
  _hud.set_focus(MODE_SION)
  _react_sion(&"play")
  _ticker.show_line("시온이가 다가왔다. (옥자를 누르면 돌아가요)")


## 옥자 교감 모드 복귀 — 액션 바·HUD 원복.
func _exit_sion_mode() -> void:
  if _mode == MODE_OKJA:
    return
  _mode = MODE_OKJA
  _bar_sion.visible = false
  _bar.visible = true
  _hud.set_focus(MODE_OKJA)
  _to_idle()
  _ticker.show_line(Dialogue.okja_line("idle", meters.stage(), _nick()))


# ── 미터 신호 처리 ────────────────────────────────────────

## 게이지 풀 → "오늘의 체키" 자동 획득 (T13/T15). 미보유 우선 일반 / 중복 → 나비 승급.
## 그랜트 → 게이지 소진(재발화 방지) → 캐릭터 폴짝 + 보이스 → 리빌 오버레이.
func _on_gauge_full(character: String) -> void:
  if _reveal != null:
    return
  var event := Cheki.pick_today(character)
  var result := Cheki.grant(character, event)

  if character == Events.SION:
    meters.consume_gauge_sion()
    _sioni.hop()
    _ticker.show_line(Dialogue.sion_line())
  else:
    meters.consume_gauge_okja()
    _okja.hop()  # smile 재사용 폴짝 (리워드 순간 → ADR 0001/T07)
    _ticker.show_line(Dialogue.okja_line("cheki_get", meters.stage(), _nick()))

  _reveal = ChekiReveal.new()
  _reveal.setup(result)
  _reveal.closed.connect(_on_reveal_closed)
  add_child(_reveal)  # 맨 위(마지막 자식) → HUD·액션바 덮음


func _on_reveal_closed() -> void:
  _reveal = null
  _hud.refresh()
  _to_idle()
  _sion_to_idle()


# ── 컬렉션북 (T16) ────────────────────────────────────────

## 컬렉션북 오버레이 열기 — 리빌·중복 진입 가드. 열린 동안 셸 입력은 책으로 위임.
func _open_book() -> void:
  if _reveal != null or _book != null:
    return
  _book = CollectionBook.new()
  _book.closed.connect(_on_book_closed)
  add_child(_book)  # 맨 위(HUD·액션바 덮음)


func _on_book_closed() -> void:
  _book = null


## 디버그 — 게이지를 즉시 채워 "오늘의 체키" 획득 리빌을 띄운다(DebugTools 키 4 / 컬렉션북 전 확인용).
func debug_grant_cheki() -> void:
  if _reveal != null:
    return
  SaveManager.set_value("okja.gauge", Balance.GAUGE_OKJA)  # 게이지 풀(연출·HUD 일관성)
  _hud.refresh()
  _on_gauge_full(Events.OKJA)  # 정규 획득 경로 그대로 — 그랜트 + 소진 + 리빌


## 관계 단계 상승 — 반말 전환 컷인은 T11. 지금은 티커 한 줄로 암시.
func _on_stage_changed(stage: String) -> void:
  _ticker.show_line(Dialogue.okja_line("stage_up", stage, _nick()))


# ── 헬퍼 ─────────────────────────────────────────────────

## 표정을 잠깐 바꿨다가 idle 로 복귀.
func _react(expr: StringName) -> void:
  _okja.set_expression(expr)
  _schedule_idle(1.2)


## delay 초 뒤 idle 로 복귀 (이전 예약은 취소).
func _schedule_idle(delay: float) -> void:
  if _revert and _revert.is_valid():
    _revert.kill()
  _revert = create_tween()
  _revert.tween_interval(delay)
  _revert.tween_callback(_to_idle)


func _to_idle() -> void:
  _okja.set_expression(&"idle")


## 시온이 반응을 잠깐 보였다가 idle 로 복귀. (T15)
func _react_sion(expr: StringName) -> void:
  _sioni.set_expression(expr)
  if _revert_sion and _revert_sion.is_valid():
    _revert_sion.kill()
  _revert_sion = create_tween()
  _revert_sion.tween_interval(1.2)
  _revert_sion.tween_callback(_sion_to_idle)


func _sion_to_idle() -> void:
  _sioni.set_expression(&"idle")


func _nick() -> String:
  return String(SaveManager.get_value("player.nickname", "손님"))
