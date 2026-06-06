class_name Cafe
extends Node2D
## 메인 교감 화면 (T06a/T09/T10) — 배경 + 라이브 옥자 + HUD + 4버튼 + 한 줄 티커.
##
## 셸 LCD(333×480) 안에 올라간다. 셸 3버튼은 Main 이 handle_shell_action() 으로 중계:
##   SELECT → 커서 순환 · OK → 확인 · CANCEL → (현재는 미사용/뒤로)
## 4버튼 교감(T09) · 옥자 터치(T10) → Meters(T08) 로 호감도/스태미나/기분 처리.
## 보이스는 data/dialogue.gd 풀에서 골라 티커(T06a)에 띄운다.
##
## 핵심 연출:
##   - 게이지 풀 → 오늘의 체키 자동 획득(T13): 그랜트 + 리빌 오버레이(ChekiReveal) + 게이지 소진. ✅
##   - 대화 2지선다 분기 · 선물 선호표(T11): `대화`/`선물` → ChoicePopup(선택 시점에 소모/적용). ✅
##   - 단계 상승 컷인(T11): 단골(regular,200)·반말 전환(comfy,600) 도달 시 StageCutin(오버레이 닫힌 뒤 예약 발화). ✅

const LCD_W := 333
const LCD_H := 480
const BG_TEX := "res://assets/sprites/bg_naraka.png"
const BINDER_TEX := "res://assets/sprites/cheki_binder.png"
const BINDER_SIZE := Vector2(48, 56)
const OkjaScript := preload("res://scripts/okja.gd")
const SioniScript := preload("res://scripts/sioni.gd")
const ContactShadowScript := preload("res://scripts/ui/contact_shadow.gd")

const OKJA_FEET := Vector2(LCD_W / 2.0, 400)  # 발밑 기준 배치 (HUD 아래 ~ 액션바 위)
# 디오라마 리프레임(Phase 3.5): 시온이는 우측 바 카운터 위, 바인더는 좌측 캐비닛 상판.
# (배경 bg_naraka.png v2 받침에 맞춘 좌표 — 우측 벽 선반은 포션으로 차 카운터 위에 앉힘)
# 발밑 = 스프라이트 불투명 영역의 바닥(아트 여백 보정 후 받침에 안착). bob 떠도 그림자는 고정.
const SIONI_FEET := Vector2(76, 394)          # 좌측 바닥마루(표면 y≈383). 발바닥=노드-11(96캔버스 발 y85)
const SIONI_PAD_BOTTOM := 11                  # 노드 원점→발바닥 간격(96px 도트) — 그림자를 발밑에 안착
const BINDER_FEET := Vector2(54, 305)         # 좌측 캐비닛 상판(바인더 아트 하단여백 17px 보정) — 선반에 안착하도록 올림
const BINDER_PAD_BOTTOM := 17                 # cheki_binder 56px 캔버스 하단 투명 여백

# 시온이 교감 모드 줌(Phase 3.5 T27) — 디오라마 컨테이너를 정수 2배로 푸시(픽셀 또렷).
const ZOOM_SION := 2.0
const SION_FOCUS_LOCAL := Vector2(73, 340)    # 줌 중심(시온이 몸통 중앙 — 발 391·키 96 기준)
const SION_FOCUS_SCREEN := Vector2(LCD_W / 2.0, LCD_H / 2.0)  # 그 점을 화면 중앙으로(좌측 경계 clamp로 실제 ~146,244)

# 교감 대상 모드 — 옥자(기본) ↔ 시온이. 시온이 탭으로 진입, 옥자 탭/CANCEL 로 복귀. (T15)
const MODE_OKJA := "okja"
const MODE_SION := "sion"

var meters: Meters
var _stage: Node2D        # 줌 대상 디오라마 컨테이너(배경+옥자+시온이+가구/터치). HUD·바·티커는 바깥 고정. (T26/T27)
var _zoom_tw: Tween       # 시온이 줌 푸시/복귀 트윈(중복 시 이전 것 취소)
var _okja: Okja
var _sioni: Sioni
var _binder: Sprite2D     # 좌측 캐비닛 위 체키북 바인더(탭 → 컬렉션북, T29)
var _hud: Hud
var _bar: ActionBar       # 옥자 4버튼
var _bar_sion: ActionBar  # 시온이 4버튼(평소 숨김)
var _ticker: Ticker
var _mode: String = MODE_OKJA
var _revert: Tween  # 옥자 표정 자동 복귀 트윈 (중복 시 이전 것 취소)
var _revert_sion: Tween  # 시온이 반응 자동 복귀 트윈
var _reveal: ChekiReveal  # 체키 획득 리빌 오버레이 (열려 있으면 셸 입력을 여기로)
var _book: CollectionBook  # 컬렉션북 오버레이 (T16, 열려 있으면 셸 입력을 여기로)
var _popup: ChoicePopup   # 대화/선물 2지선다 팝업 (T11, 열려 있으면 셸 입력을 여기로)
var _cutin: StageCutin    # 단계 상승 컷인 (T11, 열려 있으면 셸 입력을 여기로)
var _pending_cutin_stage := ""  # 도달 단계("regular"|"comfy") — 떠 있는 오버레이가 다 닫히면 컷인 발화(""=없음)


func _ready() -> void:
  add_to_group(&"cafe")  # DebugTools 가 찾아 debug_grant_cheki() 호출(디버그 빌드 전용)
  _build()


## Main 이 온보딩 후(또는 바로) 호출 — 세션 시작 + 맞이 보이스.
## 단계 상승 연출은 '넘긴 그 자리'가 아니라 이 입장에서 1회 발화한다(다음에 들를 때 인사가 바뀌어 있는 결).
##   - regular(200) 도달: 단골 등극 컷인이 입장 인사를 대신함
##   - comfy(600) 도달: 반말 전환 컷인이 입장 인사를 대신함
##   - close(2000) 도달: 전용 연출 없음 — 평소 입장 인사(후속에 컷인 추가 가능)
func start() -> void:
  meters.begin_session()
  _hud.refresh()
  if meters.was_neglected:
    _okja.set_expression(&"sad")

  # 지난 세션에 넘긴 단계가 아직 안 알려졌으면, 이 입장에서 그 연출을 한다.
  var announce := _pending_stage_announcement()
  if announce == "regular" or announce == "comfy":
    _pending_cutin_stage = announce  # 단계 상승 컷인 예약 — 아래 _maybe_cutin (마일스톤 리빌보다 뒤)
  else:
    # close(2000) 도달 포함 — 평소 입장 인사로 둔다(close 전용 연출은 후속). guest 는 시작 단계라 announce 안 됨.
    var sit := "neglect" if meters.was_neglected else "enter"
    _ticker.show_line(Dialogue.okja_line(sit, meters.stage(), _nick()))
  if announce != "":
    _mark_stage_announced()  # 컷인이든 평소 인사든 이번 입장에 알렸으니 커밋(재발화 방지)

  # 연속출석 마일스톤(3일/7일) 보상 — 있으면 나비 조각 리빌(T14). 셸 입력은 리빌로 위임.
  if not meters.pending_milestone.is_empty():
    _show_milestone_reward(meters.pending_milestone)
  _maybe_cutin()  # 예약 컷인(단골/반말): 마일스톤 리빌 없으면 바로, 있으면 리빌 닫힌 뒤(_on_reveal_closed)


## 출석 마일스톤 나비 조각 보상 리빌 (T14) — 보상 카드(승급이면 나비)를 상단 배너와 함께 보여준다.
func _show_milestone_reward(ms: Dictionary) -> void:
  if _reveal != null:
    return
  var streak := int(ms.get("streak", 0))
  var reward: Dictionary = ms.get("reward", {})
  _reveal = ChekiReveal.new()
  _reveal.setup(reward, "✦ %d일 연속 출석! ✦" % streak)
  _reveal.closed.connect(_on_reveal_closed)
  add_child(_reveal)  # 맨 위(HUD·액션바 덮음)


## 셸 3버튼 중계 (Main → Cafe). 오버레이(리빌 → 컬렉션북)가 떠 있으면 그쪽이 먼저 먹는다.
## SELECT/OK 는 현재 모드의 액션 바로, CANCEL 은 "뒤로"(시온이 모드 → 옥자 복귀 / 옥자 모드 → 책).
func handle_shell_action(action: StringName) -> void:
  # 오버레이 우선순위: 리빌 > 컷인 > 팝업 > 컬렉션북 > 액션 바.
  if _reveal != null:
    _reveal.handle_shell_action(action)
    return
  if _cutin != null:
    _cutin.handle_shell_action(action)
    return
  if _popup != null:
    _popup.handle_shell_action(action)
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
  # 0) 줌 대상 디오라마 컨테이너 (배경+옥자+시온이+가구/터치). HUD·바·티커는 self 직속(줌 제외). (T26)
  _stage = Node2D.new()
  add_child(_stage)

  # 1) 나라카 디오라마 배경 (LCD 꽉) — 좌 캐비닛/책장, 우 포션선반+카운터 (v2)
  var bg := Sprite2D.new()
  bg.texture = load(BG_TEX)
  bg.centered = false
  bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _stage.add_child(bg)

  # 2) 라이브 옥자 (중앙 전신)
  _okja = OkjaScript.new()
  _okja.position = OKJA_FEET
  _stage.add_child(_okja)

  # 2b) 라이브 시온이 (T15) — 옥자 좌하단 바닥. 탭하면 시온이 교감 모드 + 2배 줌.
  #     접지 그림자(바닥 고정) → 시온이 → 옥자보다 앞. bob 떠도 그림자가 바닥에 잡아준다.
  _add_shadow(Vector2(SIONI_FEET.x, SIONI_FEET.y - SIONI_PAD_BOTTOM), 58, 12)  # 96px 발바닥폭 ~58
  _sioni = SioniScript.new()
  _sioni.position = SIONI_FEET
  _stage.add_child(_sioni)

  # 2c) 좌측 캐비닛 위 체키북 바인더 (T29) — 탭하면 컬렉션북.
  _add_binder()

  # 3) 옥자 터치 영역 (T10) — 몸통 위 투명 버튼 (HUD/액션바와 겹치지 않게)
  _add_okja_touch()

  # 3a) 시온이 터치 영역 (T15) — 고양이 위 투명 버튼
  _add_sioni_touch()

  # 3b) 바인더 터치 영역 (T29) — 바인더 위 투명 버튼
  _add_binder_touch()

  # 4) HUD (상단, 줌 제외)
  _hud = Hud.new()
  add_child(_hud)

  # 5) 4버튼 액션 바 (T09 옥자 + T15 시온이) — 같은 자리, 모드에 따라 토글.
  _bar = ActionBar.new()
  _bar.action_chosen.connect(_on_action)
  add_child(_bar)

  _bar_sion = ActionBar.new()
  _bar_sion.configure(ActionBar.sion_actions())
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


## 좌측 캐비닛 위 체키북 바인더 (T29) — 발밑 기준 배치(스프라이트는 디오라마 컨테이너에).
func _add_binder() -> void:
  _add_shadow(Vector2(BINDER_FEET.x, BINDER_FEET.y - BINDER_PAD_BOTTOM), 26, 7)
  _binder = Sprite2D.new()
  _binder.texture = load(BINDER_TEX)
  _binder.centered = false
  _binder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  # 발밑(하단 중앙)이 BINDER_FEET 에 오도록 좌상단을 끌어올린다(아트 하단여백 보정 포함).
  _binder.position = BINDER_FEET + Vector2(-BINDER_SIZE.x / 2.0, -BINDER_SIZE.y)
  _stage.add_child(_binder)


## 받침 표면에 접지 그림자 한 장. (스프라이트보다 먼저 add → 아래에 깔림)
func _add_shadow(surface_at: Vector2, width: float, height: float) -> void:
  var sh := ContactShadowScript.new()
  _stage.add_child(sh)
  sh.setup(surface_at, width, height)


## 옥자 몸통 위 투명 터치 버튼. (디오라마 컨테이너 — 줌에 함께 변환)
func _add_okja_touch() -> void:
  var btn := _make_touch(Vector2(OKJA_FEET.x - 70, OKJA_FEET.y - 280), Vector2(140, 280))
  btn.pressed.connect(_on_okja_touch)
  _stage.add_child(btn)


## 시온이 위 투명 터치 버튼 (T15) — 발치 기준 84×88 (1.4배 확대 반영).
func _add_sioni_touch() -> void:
  var btn := _make_touch(Vector2(SIONI_FEET.x - 42, SIONI_FEET.y - 96), Vector2(84, 96))
  btn.pressed.connect(_on_sioni_touch)
  _stage.add_child(btn)


## 바인더 위 투명 터치 버튼 (T29) — 발치 기준 + 여유.
func _add_binder_touch() -> void:
  var btn := _make_touch(BINDER_FEET + Vector2(-BINDER_SIZE.x / 2.0 - 4, -BINDER_SIZE.y - 4),
    BINDER_SIZE + Vector2(8, 8))
  btn.pressed.connect(_open_book)
  _stage.add_child(btn)


## 투명 터치 버튼 헬퍼 — 보이지 않는 클릭 영역.
func _make_touch(pos: Vector2, size: Vector2) -> Button:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = pos
  btn.size = size
  var empty := StyleBoxEmpty.new()
  btn.add_theme_stylebox_override("normal", empty)
  btn.add_theme_stylebox_override("hover", empty)
  btn.add_theme_stylebox_override("pressed", empty)
  return btn


# ── 4버튼 교감 (T09 옥자 / T15 시온이) ─────────────────────

func _on_action(id: String) -> void:
  # 스태미나(옥자/시온이 공유) 게이트 — 소진 시 호감도는 안 오름(오늘 종료, 벌 없음).
  var can := meters.can_act()

  # 시온이(펫): 감정 반응은 기력과 무관하게 항상 보여준다(벌 없는 설계). 호감도만 게이트.
  if _mode == MODE_SION:
    if can:
      meters.spend_stamina()
    _on_sion_action(id, can)
    return

  # 옥자: 기력 소진 시 시무룩 + 안내 한 줄.
  if not can:
    _react(&"sad")  # 잠깐 시무룩 → 무표정 복귀
    _ticker.show_line(Dialogue.okja_line("no_stamina", meters.stage(), _nick()))
    return

  # 대화·선물은 2지선다 팝업으로 분기(T11) — 선택 시점에 스태미나 소모/호감도 적용(취소 시 무변경).
  match id:
    "talk":
      _open_talk()
      return
    "gift":
      _open_gift()
      return

  meters.spend_stamina()  # 주문음은 ActionBar._choose 가 id 기준으로 발화 (T18)
  match id:
    "cheki":
      meters.add_affinity_okja(Balance.aff("cheki"))
      _react(_okja_emotion("cheki", &"talk"))  # 버튼→감정 (buttons.json)
    "drink":
      meters.add_affinity_okja(Balance.aff("drink"))  # 선호 음료 보너스는 후속
      _brew(_okja_emotion("drink", &"brew"))
  _ticker.show_line(Dialogue.okja_line(id, meters.stage(), _nick()))


## 시온이 4버튼(체키 주문/간식/놀기/쓰담) — 호감도(기력 있을 때만) + 반응 스왑(항상). (T15)
## 시온이는 펫이라 기분·관계 단계 없이 게이지만 쌓는다. 선호 간식 보너스·옥자 교차 보너스는 후속.
## can=false(기력 0)면 호감도는 안 오르지만 감정 반응은 보여준다(펫 — 벌 없는 설계).
## 호감도종류·감정·티커풀은 모두 buttons.json / ticker.json (content_studio 편집).
func _on_sion_action(id: String, can: bool) -> void:
  var def := _sion_action_def(id)
  if can:
    # affinity: "cheki" → aff("cheki"), 그 외("sion") → aff("sion") (호감도 종류는 데이터에서)
    var gain := Balance.aff("cheki") if String(def.get("affinity", "sion")) == "cheki" else Balance.aff("sion")
    meters.add_affinity_sion(gain)
  # 버튼별 감정 반응(항상) + 버튼별 티커 풀
  _react_sion(StringName(def.get("emotion", "play")))
  _ticker.show_line(Dialogue.sion_line(String(def.get("ticker", id))))


## 시온이 버튼 정의 한 건을 id 로 찾는다(없으면 빈 사전). (buttons.json sion.actions)
func _sion_action_def(id: String) -> Dictionary:
  for a in ActionBar.sion_actions():
    if String((a as Dictionary).get("id", "")) == id:
      return a
  return {}


## 옥자 버튼/터치 감정값 — buttons.json okja.emotion[key], 없으면 fallback. (StringName 정규화)
func _okja_emotion(key: String, fallback: StringName) -> StringName:
  var em: Dictionary = GameData.buttons().get("okja", {}).get("emotion", {})
  return StringName(em.get(key, fallback))


## 옥자 터치 무작위 반응 표정 — buttons.json okja.emotion.touch 풀에서 하나. (없으면 shy/smile)
func _okja_touch_emotion() -> StringName:
  var em: Dictionary = GameData.buttons().get("okja", {}).get("emotion", {})
  var pool: Array = em.get("touch", ["shy", "smile"])
  if pool.is_empty():
    return &"shy"
  return StringName(pool[randi() % pool.size()])


## 음료 제조 연출 — 제조 표정 잠깐(기본 brew) → idle 복귀. 표정은 buttons.json okja.emotion.drink.
func _brew(expr: StringName = &"brew") -> void:
  _okja.set_expression(expr)
  _schedule_idle(1.1)


# ── 대화 / 선물 팝업 (T11) ─────────────────────────────────

## `대화` → 단계별 잡담 토막 2지선다 팝업. 고르면 _on_talk_chosen 에서 소모·적용.
func _open_talk() -> void:
  if _popup != null:
    return
  var topic := Dialogue.pick_talk(meters.stage(), _nick())
  _popup = ChoicePopup.new()
  _popup.setup(String(topic["prompt"]), topic["choices"])
  _popup.chosen.connect(_on_talk_chosen)
  _popup.closed.connect(_on_popup_closed)
  add_child(_popup)  # 맨 위(HUD·액션바 덮음)


## `선물` → 선물 4종 선호표 팝업. 고르면 _on_gift_chosen 에서 소모·적용.
func _open_gift() -> void:
  if _popup != null:
    return
  _popup = ChoicePopup.new()
  _popup.setup(Dialogue.gift_prompt(meters.stage()), Dialogue.gift_choices(_nick()))
  _popup.chosen.connect(_on_gift_chosen)
  _popup.closed.connect(_on_popup_closed)
  add_child(_popup)


## 대화 선택 확정 — 스태미나 1회 소모 + tier 별 호감도 + 옥자 표정 반응.
func _on_talk_chosen(choice: Dictionary) -> void:
  meters.spend_stamina()
  meters.add_affinity_okja(Balance.aff_talk(String(choice.get("tier", "plain"))))
  _react(choice.get("expr", &"talk"))
  _ticker.show_line(String(choice.get("reply", "")))  # 옥자 대답은 하단 티커(보이스 단일 채널)


## 선물 선택 확정 — 스태미나 1회 소모 + 선호도(tier) 별 호감도 + 옥자 표정 반응.
func _on_gift_chosen(choice: Dictionary) -> void:
  meters.spend_stamina()
  meters.add_affinity_okja(Balance.aff_gift(String(choice.get("tier", "plain"))))
  _react(choice.get("expr", &"shy"))
  _ticker.show_line(String(choice.get("reply", "")))  # 옥자 대답은 하단 티커(보이스 단일 채널)


func _on_popup_closed() -> void:
  _popup = null
  # 단계 상승 컷인은 이 자리서 안 띄운다 — 다음 입장(start)으로 미뤄짐(announced_stage).
  # tier→호감도 매핑은 Balance.aff_talk()/aff_gift() (수치 단일 출처 — data/balance.json).


# ── 단계 상승 컷인 (T11) ───────────────────────────────────

## 예약된 컷인을 띄운다 — 단, 떠 있는 오버레이가 하나도 없을 때만(순차 보장).
## 리빌/팝업/책이 닫힐 때마다 호출돼, 모두 정리된 순간 한 번 발화한다.
func _maybe_cutin() -> void:
  if _pending_cutin_stage == "":
    return
  if _reveal != null or _popup != null or _book != null or _cutin != null:
    return
  var stage := _pending_cutin_stage
  _pending_cutin_stage = ""
  _cutin = StageCutin.new()
  _cutin.setup(_nick(), stage)
  _cutin.closed.connect(_on_cutin_closed)
  add_child(_cutin)  # 맨 위(HUD·액션바 덮음)


func _on_cutin_closed() -> void:
  _cutin = null
  _to_idle()
  _ticker.show_line(Dialogue.okja_line("idle", meters.stage(), _nick()))


# ── 단계 상승 입장 연출 판정 (announced_stage 추적) ─────────
## 단계 순위 — 입장 시 '아직 안 알린 상승'을 판정하는 데 쓴다.
const STAGE_ORDER := {"guest": 0, "regular": 1, "comfy": 2, "close": 3}

## 이 입장에서 연출할 '아직 안 알린' 단계가 있으면 그 단계 문자열, 없으면 "".
## 누적 호감도로 단계가 올랐어도 flags.announced_stage 보다 높을 때만(1회) 알린다.
func _pending_stage_announcement() -> String:
  var announced := String(SaveManager.get_value("flags.announced_stage", "guest"))
  var cur := meters.stage()
  return cur if _stage_rank(cur) > _stage_rank(announced) else ""


## 현재 단계를 '알림 완료'로 커밋(다음 상승 전까지 재발화 안 함).
func _mark_stage_announced() -> void:
  SaveManager.set_value("flags.announced_stage", meters.stage())
  SaveManager.save_game()


func _stage_rank(stage: String) -> int:
  return int(STAGE_ORDER.get(stage, 0))


# ── 터치 리액션 / 모드 전환 (T10 / T15) ───────────────────

func _on_okja_touch() -> void:
  # 시온이 모드에서 옥자를 누르면 옥자에게 복귀.
  if _mode == MODE_SION:
    _exit_sion_mode()
    return
  var gained := meters.add_touch_affinity()
  if gained <= 0:
    # 세션 터치 상한 — 더는 호감도 안 오르고 살짝 짜증 보이스
    _react(_okja_emotion("touch_cap", &"shy"))
    _ticker.show_line(Dialogue.okja_line("touch_cap", meters.stage(), _nick()))
    return
  # 터치 반응 — buttons.json okja.emotion.touch 풀에서 무작위(기본 부끄/웃음 번갈아)
  _react(_okja_touch_emotion())
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
  _focus_stage(SION_FOCUS_LOCAL, ZOOM_SION, SION_FOCUS_SCREEN)  # 시온이로 2배 푸시 줌 (T27)
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
  _reset_stage()  # 1x 풀 디오라마 복귀 (T27)
  _to_idle()
  _ticker.show_line(Dialogue.okja_line("idle", meters.stage(), _nick()))


# ── 디오라마 줌 (T27) ─────────────────────────────────────

## 디오라마 컨테이너를 local_target 기준 zoom 배로 푸시 — local_target 을 화면 screen_at 위치로.
## 컨테이너가 LCD(333×480)를 항상 덮도록 위치를 클램프하고, 정지 위치는 정수로 맞춰 픽셀을 또렷이.
func _focus_stage(local_target: Vector2, zoom: float, screen_at: Vector2) -> void:
  var pos := screen_at - local_target * zoom
  pos.x = clampf(pos.x, LCD_W - LCD_W * zoom, 0.0)
  pos.y = clampf(pos.y, LCD_H - LCD_H * zoom, 0.0)
  pos = pos.round()  # 정지 시 정수 위치(도트 정렬)
  _tween_stage(Vector2(zoom, zoom), pos)


## 1x 풀 디오라마로 복귀.
func _reset_stage() -> void:
  _tween_stage(Vector2.ONE, Vector2.ZERO)


## 스케일·위치를 0.3s 동안 함께 트윈(전환만 비정수, 정지 상태는 정수 → 픽셀 또렷).
func _tween_stage(scale_to: Vector2, pos_to: Vector2) -> void:
  if _zoom_tw and _zoom_tw.is_valid():
    _zoom_tw.kill()
  _zoom_tw = create_tween().set_parallel(true)
  _zoom_tw.tween_property(_stage, "scale", scale_to, 0.3) \
    .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  _zoom_tw.tween_property(_stage, "position", pos_to, 0.3) \
    .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ── 미터 신호 처리 ────────────────────────────────────────

## 게이지 풀 → "오늘의 체키" 자동 획득 (T13/T15). 미보유 우선 일반 / 중복 → 나비 승급.
## 그랜트 → 게이지 소진(재발화 방지) → 캐릭터 폴짝 + 보이스 → 리빌 오버레이.
func _on_gauge_full(character: String) -> void:
  if _reveal != null:
    return
  Sfx.play(&"gauge_full")  # 게이지 가득 차오름 완료음 (T18)
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
  _maybe_cutin()  # 리빌과 단계 상승이 겹쳤으면 닫힌 뒤 컷인


# ── 컬렉션북 (T16) ────────────────────────────────────────

## 컬렉션북 오버레이 열기 — 리빌·중복 진입 가드. 열린 동안 셸 입력은 책으로 위임.
func _open_book() -> void:
  if _reveal != null or _book != null or _popup != null or _cutin != null:
    return
  Sfx.play(&"book")  # 체키북 열기음 (T18)
  _book = CollectionBook.new()
  _book.closed.connect(_on_book_closed)
  add_child(_book)  # 맨 위(HUD·액션바 덮음)


func _on_book_closed() -> void:
  _book = null


## 디버그 — 게이지를 즉시 채워 "오늘의 체키" 획득 리빌을 띄운다(컬렉션북 전 확인용).
## character: 옥자(DebugTools 키 4) / 시온이(키 6). 시온이 미보유 일반 → 중복 시 나비 승급 확인.
func debug_grant_cheki(character := Events.OKJA) -> void:
  if _reveal != null:
    return
  if character == Events.SION:
    SaveManager.set_value("sion.gauge", Balance.GAUGE_SION)  # 게이지 풀(연출·HUD 일관성)
  else:
    SaveManager.set_value("okja.gauge", Balance.GAUGE_OKJA)
  _hud.refresh()
  _on_gauge_full(character)  # 정규 획득 경로 그대로 — 그랜트 + 소진 + 리빌


## 디버그 — 연속출석 마일스톤(3일) 나비 조각 보상 리빌을 강제로 띄운다(T14 확인용, DebugTools 키 5).
## 실제로는 3일 연속 접속해야 발화하므로, 시연/검수 편의로 보상 경로만 즉시 태운다.
func debug_milestone() -> void:
  if _reveal != null:
    return
  var reward := Cheki.grant_milestone_shards(Balance.ATTENDANCE_REWARD_SHARDS_3)
  if reward.is_empty():
    return
  _hud.refresh()
  _show_milestone_reward({"streak": Balance.ATTENDANCE_MILESTONE_3, "reward": reward})


## 관계 단계 상승 (T11). 연출은 '넘긴 그 자리'에서 하지 않는다 — 교감 흐름을 끊지 않게,
## 그리고 "다음에 들르니 옥자가 달라져 있더라"의 결을 살려 다음 입장(start)에서 1회 발화한다.
##   - 단골(regular, 200): 다음 입장 단골 등극 컷인(존댓말 유지)
##   - 편해진 사이(comfy, 600): 다음 입장 반말 전환 컷인(존댓말 해제)
##   - 마음 연 사이(close, 2000): 전용 연출 없음 — 평소 입장 인사(후속)
## 여기선 아무것도 띄우지 않는다(누적 호감도는 이미 저장됨 → start 가 announced_stage 와 비교해 처리).
func _on_stage_changed(_stage: String) -> void:
  pass


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
