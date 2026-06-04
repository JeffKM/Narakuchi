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
##   - 게이지 풀 → 오늘의 체키 자동 획득: T13/T18 (지금은 hop + 티커 플레이스홀더)
##   - 대화 2지선다 분기 · 선물 선호표: T11 (지금은 간이 +호감도)
##   - 반말 전환 컷인: T11 (지금은 단계 상승 티커만)

const LCD_W := 333
const LCD_H := 480
const BG_TEX := "res://assets/sprites/bg_naraka.png"
const OkjaScript := preload("res://scripts/okja.gd")

const OKJA_FEET := Vector2(LCD_W / 2.0, 400)  # 발밑 기준 배치 (HUD 아래 ~ 액션바 위)

var meters: Meters
var _okja: Okja
var _hud: Hud
var _bar: ActionBar
var _ticker: Ticker
var _revert: Tween  # 표정 자동 복귀 트윈 (중복 시 이전 것 취소)


func _ready() -> void:
  _build()


## Main 이 온보딩 후(또는 바로) 호출 — 세션 시작 + 맞이 보이스.
func start() -> void:
  meters.begin_session()
  _hud.refresh()
  var sit := "neglect" if meters.was_neglected else "enter"
  if meters.was_neglected:
    _okja.set_expression(&"sad")
  _ticker.show_line(Dialogue.okja_line(sit, meters.stage(), _nick()))


## 셸 3버튼 중계 (Main → Cafe).
func handle_shell_action(action: StringName) -> void:
  match action:
    &"select": _bar.move_cursor()
    &"ok": _bar.activate_focused()
    &"cancel": pass  # Phase 1: 뒤로/홈 동작 없음 (T15 시온이 모드 복귀에서 사용)


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

  # 3) 옥자 터치 영역 (T10) — 몸통 위 투명 버튼 (HUD/액션바와 겹치지 않게)
  _add_okja_touch()

  # 4) HUD (상단)
  _hud = Hud.new()
  add_child(_hud)

  # 5) 4버튼 액션 바 (T09)
  _bar = ActionBar.new()
  _bar.action_chosen.connect(_on_action)
  add_child(_bar)

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


# ── 4버튼 교감 (T09) ──────────────────────────────────────

func _on_action(id: String) -> void:
  # 스태미나 게이트 — 소진 시 오늘 종료 (벌 없음, 내일 회복)
  if not meters.can_act():
    _okja.set_expression(&"sad")
    _ticker.show_line(Dialogue.okja_line("no_stamina", meters.stage(), _nick()))
    return

  meters.spend_stamina()
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


## 음료 제조 연출 — brew 표정 잠깐 → idle 복귀.
func _brew() -> void:
  _okja.set_expression(&"brew")
  _schedule_idle(1.1)


# ── 옥자 터치 리액션 (T10) ────────────────────────────────

func _on_okja_touch() -> void:
  var gained := meters.add_touch_affinity()
  if gained <= 0:
    # 세션 터치 상한 — 더는 호감도 안 오르고 살짝 짜증 보이스
    _react(&"shy")
    _ticker.show_line(Dialogue.okja_line("touch_cap", meters.stage(), _nick()))
    return
  # 부끄/웃음 번갈아 — 살아있는 반응
  _react(&"shy" if (randi() % 2 == 0) else &"smile")
  _ticker.show_line(Dialogue.okja_line("touch", meters.stage(), _nick()))


# ── 미터 신호 처리 ────────────────────────────────────────

## 게이지 풀 — 오늘의 체키 (실제 획득/연출은 T13/T18). 지금은 폴짝 + 보이스.
func _on_gauge_full(_character: String) -> void:
  _okja.hop()
  _ticker.show_line(Dialogue.okja_line("cheki_get", meters.stage(), _nick()))


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


func _nick() -> String:
  return String(SaveManager.get_value("player.nickname", "손님"))
