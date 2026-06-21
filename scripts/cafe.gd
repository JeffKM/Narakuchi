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
var _active_main: String = "okja"  # 현재 교감 중인 메인 id (flags.active_main — 로스터 선택 #3 전까지 기본). T30
var _active_pet: String = "sion"   # 곁의 펫 id (flags.active_pet — 시온이/규종이…). 라이브 스왑·게이지·체키 대상. 이슈 #6
var _stage: Node2D        # 줌 대상 디오라마 컨테이너(배경+메인+시온이+가구/터치). HUD·바·티커는 바깥 고정. (T26/T27)
var _zoom_tw: Tween       # 시온이 줌 푸시/복귀 트윈(중복 시 이전 것 취소)
var _okja: Okja           # 라이브 메인 스탠딩(active_main 을 렌더 — 옥자/미호…). 변수명은 역사적.
var _sioni: Sioni
var _dbg_pet_stage: int = 0  # 디버그 키 9 — 펫 생애단계 순환 인덱스(캐논→아기→유년→마름→통통, D0 아트 확인용)
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
var _roster: RosterScreen # 로스터 선택 오버레이 (#3, 열려 있으면 셸 입력을 여기로 — active_main·active_pet 교체)
var _roster_por: TextureRect  # 좌상단 진입 버튼의 활성 메인 포트레이트 (스왑 시 갱신)
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
  # 온보딩에서 고른 메인·펫을 반영한다. Cafe 는 생성 시점(_ready→_build)에 flags 를 읽지만,
  # 첫 접속이면 그땐 온보딩 전이라 기본값(옥자/시온이)으로 build 된다. flags 는 온보딩이 확정하므로
  # 세션 시작 시 저장값으로 한 번 더 맞춘다(announce=false — 입장 인사는 아래 start 로직이 담당).
  swap_active(
    String(SaveManager.get_value("flags.active_main", _active_main)),
    String(SaveManager.get_value("flags.active_pet", _active_pet)),
    false)

  # 입장 효과음 — 새 하루면 day_advance, 아니면 scene_enter (begin_session 전에 새날 판정). (→ ADR 0004)
  var is_new_day := bool(Meters.evaluate_session().get("is_new_day", false))
  Sfx.event(&"day_advance" if is_new_day else &"scene_enter")
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
    _ticker.show_line(Dialogue.line(_dialogue_key(),sit, meters.stage(), _nick()))
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
  _reveal.setup(reward, "★ %d일 연속 출석! ★" % streak)
  _reveal.closed.connect(_on_reveal_closed)
  add_child(_reveal)  # 맨 위(HUD·액션바 덮음)


## 셸 3버튼 중계 (Main → Cafe). 오버레이(리빌 → 컬렉션북)가 떠 있으면 그쪽이 먼저 먹는다.
## SELECT/OK 는 현재 모드의 액션 바로, CANCEL 은 "뒤로"(시온이 모드 → 옥자 복귀 / 옥자 모드 → 책).
func handle_shell_action(action: StringName) -> void:
  # 오버레이 우선순위: 로스터 > 리빌 > 컷인 > 팝업 > 컬렉션북 > 액션 바.
  if _roster != null:
    _roster.handle_shell_action(action)
    return
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
    &"select":
      Sfx.event(&"cursor_move")  # OK 의 확정음은 ActionBar._choose 가 의미별로 발화
      bar.move_cursor()
    &"ok": bar.activate_focused()
    &"cancel":
      # 뒤로 효과음은 행선지가 낸다: 시온이 복귀=_exit_sion_mode(cancel) / 책 열기=_open_book(book_open).
      if _mode == MODE_SION:
        _exit_sion_mode()  # 시온이 모드에선 CANCEL = 옥자에게 복귀
      else:
        _open_book()       # 옥자 모드에선 CANCEL = 컬렉션북 토글


## 현재 모드의 액션 바.
func _active_bar() -> ActionBar:
  return _bar_sion if _mode == MODE_SION else _bar


# ── 화면 구성 ─────────────────────────────────────────────

func _build() -> void:
  # 현재 교감 중인 메인 (로스터 선택 #3 전까지 기본 메인). 라이브 스탠딩·HUD·호감도의 대상.
  _active_main = String(SaveManager.get_value("flags.active_main", Characters.default_main()))
  # 곁의 펫 (로스터에서 메인과 자유 조합). 라이브 시온이 노드가 이 펫의 스프라이트로 렌더된다. 이슈 #6
  _active_pet = String(SaveManager.get_value("flags.active_pet", Characters.default_pet()))

  # 0) 줌 대상 디오라마 컨테이너 (배경+메인+시온이+가구/터치). HUD·바·티커는 self 직속(줌 제외). (T26)
  _stage = Node2D.new()
  add_child(_stage)

  # 1) 나라카 디오라마 배경 (LCD 꽉) — 좌 캐비닛/책장, 우 포션선반+카운터 (v2)
  var bg := Sprite2D.new()
  bg.texture = load(BG_TEX)
  bg.centered = false
  bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _stage.add_child(bg)

  # 2) 라이브 메인 (중앙 전신) — active_main 을 렌더(표정 경로는 레지스트리에서 파생).
  _okja = OkjaScript.new()
  _okja.character = _active_main  # _ready(add_child) 전에 지정
  _okja.position = OKJA_FEET
  _stage.add_child(_okja)

  # 2b) 라이브 시온이 (T15) — 옥자 좌하단 바닥. 탭하면 시온이 교감 모드 + 2배 줌.
  #     접지 그림자(바닥 고정) → 시온이 → 옥자보다 앞. bob 떠도 그림자가 바닥에 잡아준다.
  _add_shadow(Vector2(SIONI_FEET.x, SIONI_FEET.y - SIONI_PAD_BOTTOM), 58, 12)  # 96px 발바닥폭 ~58
  _sioni = SioniScript.new()
  # 곁의 펫 표정 접두어 — 저장된 성장 단계를 반영(아기/유년/성체). 재방문 시 자란 모습 그대로(D1).
  _sioni.sprite_prefix = Characters.pet_stage_prefix(_active_pet, _pet_stage())  # 트리 진입 전 지정(이슈 #6 / D1)
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

  # 4) HUD (상단, 줌 제외) — 게이지/기분 표시 대상을 active_main 으로.
  _hud = Hud.new()
  add_child(_hud)
  _hud.set_focus(_active_main)

  # 4b) 로스터 진입 버튼 (좌상단 모서리) — 활성 메인 포트레이트를 탭하면 캐릭터 교체 화면.
  _add_roster_button()

  # 5) 4버튼 액션 바 (T09 옥자 + T15 시온이) — 같은 자리, 모드에 따라 토글.
  _bar = ActionBar.new()
  _bar.action_chosen.connect(_on_action)
  add_child(_bar)

  _bar_sion = ActionBar.new()
  _bar_sion.configure(ActionBar.pet_actions(Characters.buttons_key(_active_pet)))
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
  meters.pet_grew.connect(_on_pet_grew)  # 펫 육성 단계 상승 → 라이브 스프라이트 스왑 (D1 데모 진화)
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

## 스태미나 1회 소모 — 데모(Balance.DEMO)에선 무제한이라 소모하지 않는다. (호출부 단일화)
func _spend_stamina() -> void:
  if Balance.DEMO:
    return
  meters.spend_stamina()


func _on_action(id: String) -> void:
  # 스태미나(옥자/시온이 공유) 게이트 — 소진 시 호감도는 안 오름(오늘 종료, 벌 없음).
  # 데모(Balance.DEMO)에선 스태미나 무제한 — 항상 행동 가능.
  var can := Balance.DEMO or meters.can_act()

  # 시온이(펫): 감정 반응은 기력과 무관하게 항상 보여준다(벌 없는 설계). 호감도만 게이트.
  if _mode == MODE_SION:
    if can:
      _spend_stamina()
    _on_sion_action(id, can)
    return

  # 옥자: 기력 소진 시 시무룩 + 안내 한 줄.
  if not can:
    _react(&"sad")  # 잠깐 시무룩 → 무표정 복귀
    _ticker.show_line(Dialogue.line(_dialogue_key(),"no_stamina", meters.stage(), _nick()))
    return

  # 대화·선물은 2지선다 팝업으로 분기(T11) — 선택 시점에 스태미나 소모/호감도 적용(취소 시 무변경).
  match id:
    "talk":
      _open_talk()
      return
    "gift":
      _open_gift()
      return

  _spend_stamina()  # 주문음은 ActionBar._choose 가 id 기준으로 발화 (T18)
  match id:
    "cheki":
      meters.add_affinity_main(_active_main, Balance.aff("cheki"))
      _react(_main_emotion("cheki", &"talk"))  # 버튼→감정 (buttons.json — 메인별 전용)
      if Balance.DEMO:
        # 데모: 체키 버튼이 메인 체키를 직접 지급(게이지 무관). 리빌/완료 안내가 메시지 담당.
        _grant_cheki_now(_active_main)
        return
    "drink":
      meters.add_affinity_main(_active_main, Balance.aff("drink"))  # 선호 음료 보너스는 후속
      _brew(_main_emotion("drink", &"brew"))
  _ticker.show_line(Dialogue.line(_dialogue_key(),id, meters.stage(), _nick()))


## 시온이 4버튼(체키 주문/간식/놀기/쓰담) — 호감도(기력 있을 때만) + 반응 스왑(항상). (T15)
## 시온이는 펫이라 기분·관계 단계 없이 게이지만 쌓는다. 선호 간식 보너스·옥자 교차 보너스는 후속.
## can=false(기력 0)면 호감도는 안 오르지만 감정 반응은 보여준다(펫 — 벌 없는 설계).
## 호감도종류·감정·티커풀은 모두 buttons.json / ticker.json (content_studio 편집).
func _on_sion_action(id: String, can: bool) -> void:
  var def := _sion_action_def(id)
  if can:
    # affinity: "cheki" → aff("cheki"), 그 외("sion") → aff("sion") (호감도 종류는 데이터에서)
    var gain := Balance.aff("cheki") if String(def.get("affinity", "sion")) == "cheki" else Balance.aff("sion")
    meters.add_affinity_pet(_active_pet, gain)
  # 버튼별 감정 반응(항상) + 버튼별 티커 풀(활성 펫 전용 풀)
  _react_sion(StringName(def.get("emotion", "play")))
  _ticker.show_line(Dialogue.pet_line(_pet_dialogue_key(), String(def.get("ticker", id))))
  # 데모 진화(D1): 돌봄(간식/놀기/쓰담)은 성장 카운트를 올린다(체키 제외 — 수집이지 육성 아님).
  # 단계가 오르면 meters.pet_grew → _on_pet_grew 가 스프라이트 스왑 + 안내(위 티커를 덮어 메시지 담당).
  if Balance.DEMO and id != "cheki":
    meters.grow_pet(_active_pet)
  # 데모: '체키' 버튼이면 펫 체키를 직접 지급(게이지 무관) — 리빌/완료 안내가 위 티커를 덮어 메시지 담당.
  if Balance.DEMO and id == "cheki":
    _grant_cheki_now(_active_pet)


## 현재 펫의 버튼 정의 한 건을 id 로 찾는다(없으면 빈 사전). (buttons.json[buttons_key].actions — 펫별 전용)
func _sion_action_def(id: String) -> Dictionary:
  for a in ActionBar.pet_actions(Characters.buttons_key(_active_pet)):
    if String((a as Dictionary).get("id", "")) == id:
      return a
  return {}


## 현재 메인의 대사 데이터 키(Characters.dialogue_key) — 티커·대화·선물·컷인 풀 선택. (T31/이슈 #4)
func _dialogue_key() -> String:
  return Characters.dialogue_key(_active_main)


## 현재 펫의 티커 데이터 키(Characters.dialogue_key) — 펫 버튼/획득/터치 티커 풀 선택. (이슈 #6)
func _pet_dialogue_key() -> String:
  return Characters.dialogue_key(_active_pet)


## 현재 메인의 버튼/터치 감정값 — buttons.json[buttons_key].emotion[key], 없으면 fallback. (StringName 정규화)
## 메인별 전용(옥자=okja, 미호=miho) — Characters.buttons_key(_active_main) 로 풀 선택. (이슈 #6 버튼 감정 전용)
func _main_emotion(key: String, fallback: StringName) -> StringName:
  var em := _main_emotion_map()
  return StringName(em.get(key, fallback))


## 현재 메인의 터치 무작위 반응 표정 — buttons.json[buttons_key].emotion.touch 풀에서 하나. (없으면 shy/smile)
func _main_touch_emotion() -> StringName:
  var pool: Array = _main_emotion_map().get("touch", ["shy", "smile"])
  if pool.is_empty():
    return &"shy"
  return StringName(pool[randi() % pool.size()])


## 현재 메인의 버튼 감정맵 — buttons.json[Characters.buttons_key(_active_main)].emotion.
func _main_emotion_map() -> Dictionary:
  return GameData.buttons().get(Characters.buttons_key(_active_main), {}).get("emotion", {})


## 음료 제조 연출 — 제조 표정 잠깐(기본 brew) → idle 복귀. 표정은 buttons.json okja.emotion.drink.
func _brew(expr: StringName = &"brew") -> void:
  _okja.set_expression(expr)
  _schedule_idle(1.1)


# ── 대화 / 선물 팝업 (T11) ─────────────────────────────────

## `대화` → 단계별 잡담 토막 2지선다 팝업. 고르면 _on_talk_chosen 에서 소모·적용.
func _open_talk() -> void:
  if _popup != null:
    return
  var topic := Dialogue.pick_talk(_dialogue_key(), meters.stage(), _nick())
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
  _popup.setup(Dialogue.gift_prompt(_dialogue_key(), meters.stage()), Dialogue.gift_choices(_dialogue_key(), meters.stage(), _nick()))
  _popup.chosen.connect(_on_gift_chosen)
  _popup.closed.connect(_on_popup_closed)
  add_child(_popup)


## 대화 선택 확정 — 스태미나 1회 소모 + tier 별 호감도 + 옥자 표정 반응.
func _on_talk_chosen(choice: Dictionary) -> void:
  # tier 별 선택음 (good=살짝 밝게 / plain=평범) → ADR 0004
  Sfx.event(&"talk_pick_good" if String(choice.get("tier", "plain")) == "good" else &"talk_pick_plain")
  _spend_stamina()
  meters.add_affinity_main(_active_main, Balance.aff_talk(String(choice.get("tier", "plain"))))
  _react(choice.get("expr", &"talk"))
  _ticker.show_line(String(choice.get("reply", "")))  # 옥자 대답은 하단 티커(보이스 단일 채널)


## 선물 선택 확정 — 스태미나 1회 소모 + 선호도(tier) 별 호감도 + 옥자 표정 반응.
func _on_gift_chosen(choice: Dictionary) -> void:
  # 선물 tier 별 선택음 (match/sion=좋아함 / plain=보통) → ADR 0004
  match String(choice.get("tier", "plain")):
    "match": Sfx.event(&"gift_match")
    "sion": Sfx.event(&"gift_sion")
    _: Sfx.event(&"gift_plain")
  _spend_stamina()
  meters.add_affinity_main(_active_main, Balance.aff_gift(String(choice.get("tier", "plain"))))
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
  _cutin.setup(_nick(), stage, _active_main)  # 현재 메인의 컷인 대사·렌더 (T31/이슈 #4)
  _cutin.closed.connect(_on_cutin_closed)
  add_child(_cutin)  # 맨 위(HUD·액션바 덮음)


func _on_cutin_closed() -> void:
  _cutin = null
  _to_idle()
  _ticker.show_line(Dialogue.line(_dialogue_key(),"idle", meters.stage(), _nick()))


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
    Sfx.event(&"okja_touch_cap")  # → ADR 0004
    _react(_main_emotion("touch_cap", &"shy"))
    _ticker.show_line(Dialogue.line(_dialogue_key(),"touch_cap", meters.stage(), _nick()))
    return
  # 터치 반응 — buttons.json okja.emotion.touch 풀에서 무작위(기본 부끄/웃음 번갈아)
  Sfx.event(&"okja_touch")  # → ADR 0004
  _react(_main_touch_emotion())
  _ticker.show_line(Dialogue.line(_dialogue_key(),"touch", meters.stage(), _nick()))


## 시온이 탭 — 옥자 모드면 시온이 교감 모드 진입, 이미 시온이 모드면 가벼운 반응.
func _on_sioni_touch() -> void:
  Sfx.event(&"sioni_touch")  # → ADR 0004 (모드 진입이든 가벼운 반응이든 시온이 쓰담음)
  if _mode == MODE_OKJA:
    _enter_sion_mode()
    return
  _react_sion(&"pet" if (randi() % 2 == 0) else &"play")
  _ticker.show_line(Dialogue.pet_line(_pet_dialogue_key()))


## 시온이 교감 모드 진입 — 액션 바 교체 + HUD 게이지를 시온이로.
func _enter_sion_mode() -> void:
  if _mode == MODE_SION:
    return
  _mode = MODE_SION
  _bar.visible = false
  _bar_sion.visible = true
  _hud.set_focus(_active_pet)  # 게이지를 활성 펫으로 (이슈 #6)
  _focus_stage(SION_FOCUS_LOCAL, ZOOM_SION, SION_FOCUS_SCREEN)  # 펫으로 2배 푸시 줌 (T27)
  _react_sion(&"play")
  _ticker.show_line("%s가 왔어요. 옥자를 누르면 돌아가요." % Characters.display_name(_active_pet))


## 옥자 교감 모드 복귀 — 액션 바·HUD 원복.
func _exit_sion_mode() -> void:
  if _mode == MODE_OKJA:
    return
  Sfx.event(&"cancel")  # 옥자에게 복귀(뒤로) → ADR 0004
  _mode = MODE_OKJA
  _bar_sion.visible = false
  _bar.visible = true
  _hud.set_focus(_active_main)
  _reset_stage()  # 1x 풀 디오라마 복귀 (T27)
  _to_idle()
  _ticker.show_line(Dialogue.line(_dialogue_key(),"idle", meters.stage(), _nick()))


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
  # 데모: 체키는 버튼 직결 — 게이지는 가득 차면 비워 순환만(살아있는 바 피드백), 자동 지급 없음.
  if Balance.DEMO:
    if Characters.is_main(character):
      meters.consume_gauge_main(character)
      _okja.hop()
    else:
      meters.consume_gauge_pet(character)
      _sioni.hop()
    return
  Sfx.event(&"gauge_full")  # 게이지 가득 차오름 완료음 (→ ADR 0004)
  var event := Cheki.pick_today(character)
  var result := Cheki.grant(character, event)

  if not Characters.is_main(character):
    # 펫(시온이·규종이…): 게이지만 — 폴짝 + 펫 전용 티커
    meters.consume_gauge_pet(character)
    _sioni.hop()
    _ticker.show_line(Dialogue.pet_line(Characters.dialogue_key(character)))
  else:
    meters.consume_gauge_main(character)
    _okja.hop()  # smile 재사용 폴짝 (리워드 순간 → ADR 0001/T07)
    _ticker.show_line(Dialogue.line(_dialogue_key(),"cheki_get", meters.stage(), _nick()))

  _reveal = ChekiReveal.new()
  _reveal.setup(result)
  _reveal.closed.connect(_on_reveal_closed)
  add_child(_reveal)  # 맨 위(마지막 자식) → HUD·액션바 덮음


## 데모 — 체키 버튼 직결 지급(게이지 무관). 메인/펫 공용.
## 이미 그 캐릭터를 나비까지 다 모았으면 지급 없이 안내 티커만(공용 문구).
## 새로 지급해 9명 전원이 완성되는 순간이면, 그 리빌에 1회 축하 배너(headline)를 얹는다.
func _grant_cheki_now(character: String) -> void:
  if _reveal != null:
    return
  if Cheki.is_complete(character):
    # 줄 체키 없음 — 호감도는 위에서 이미 가산됨. 캐릭터 완료 안내만.
    _ticker.show_line(Balance.DEMO_CHARACTER_DONE_LINE)
    return

  var event := Cheki.pick_today(character)
  var result := Cheki.grant(character, event)

  # 이번 지급으로 9명 전원이 완성됐고 아직 축하 안 했으면 → 1회 축하 배너.
  var headline := ""
  if Cheki.is_all_complete() and not bool(SaveManager.get_value("flags.demo_all_complete", false)):
    SaveManager.set_value("flags.demo_all_complete", true)
    SaveManager.save_game()
    headline = Balance.DEMO_ALL_COMPLETE_LINE

  if Characters.is_main(character):
    _okja.hop()
  else:
    _sioni.hop()

  _reveal = ChekiReveal.new()
  _reveal.setup(result, headline)
  _reveal.closed.connect(_on_reveal_closed)
  add_child(_reveal)  # 맨 위(마지막 자식) → HUD·액션바 덮음


## 펫 육성 단계 상승 (D1 데모 진화) — 라이브 스프라이트를 새 단계로 하드 스왑 + 폴짝 + 한 줄 안내.
## D0의 set_prefix 경로(아기/유년/성체 텍스처 교체)를 그대로 탄다. 발밑 피벗 고정이라 아기는 작게·성체는 캐논 크기로.
## 화이트 플래시·반짝임(D3)·HUD 성장 미터(D4)는 후속 슬라이스. 곁의 펫이 아닐 땐 무시(스왑 중 등).
func _on_pet_grew(character: String, stage: String) -> void:
  if character != _active_pet:
    return
  _sioni.set_prefix(Characters.pet_stage_prefix(character, stage))
  _sioni.hop()
  _dbg_pet_stage = 0  # 디버그 키 9 순환 인덱스와 실제 성장 상태가 어긋나지 않게 리셋
  var label: String = {"baby": "아기", "child": "유년", "adult": "성체"}.get(stage, stage)
  _ticker.show_line("%s가 자랐어요! (%s)" % [Characters.display_name(character), label])


## 곁의 펫의 현재 성장 단계("baby"|"child"|"adult") — 저장된 누적 돌봄에서 파생. (Balance 단일 출처, D1)
func _pet_stage() -> String:
  return Balance.pet_growth_stage(int(SaveManager.get_value("%s.growth" % _active_pet, 0)))


func _on_reveal_closed() -> void:
  _reveal = null
  _hud.refresh()
  # 책이 열린 채 체키가 지급된 경우(디버그 키 4 등 — 리빌이 책 위에 뜸) 닫힌 뒤 책을 최신으로.
  if _book != null and is_instance_valid(_book):
    _book.refresh()
  _to_idle()
  _sion_to_idle()
  _maybe_cutin()  # 리빌과 단계 상승이 겹쳤으면 닫힌 뒤 컷인


# ── 컬렉션북 (T16) ────────────────────────────────────────

## 컬렉션북 오버레이 열기 — 리빌·중복 진입 가드. 열린 동안 셸 입력은 책으로 위임.
func _open_book() -> void:
  if _reveal != null or _book != null or _popup != null or _cutin != null:
    return
  Sfx.event(&"book_open")  # 체키북 열기음 (→ ADR 0004)
  _book = CollectionBook.new()
  _book.closed.connect(_on_book_closed)
  add_child(_book)  # 맨 위(HUD·액션바 덮음)


func _on_book_closed() -> void:
  _book = null


# ── 로스터 (캐릭터 교체, #3) ────────────────────────────────

const ROSTER_BTN := Vector2(28, 28)  # 좌상단 진입 버튼(게이지 좌측 여백, HUD 와 안 겹침)

## 좌상단 모서리에 활성 메인 포트레이트 미니 버튼 — 탭하면 로스터(캐릭터 교체).
## 디오라마(_stage)가 아니라 self 직속(줌·시온이 모드 영향 안 받게) + HUD 보다 위.
func _add_roster_button() -> void:
  var frame := Panel.new()
  frame.position = Vector2(3, 3)
  frame.size = ROSTER_BTN
  frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(Palette.CHARCOAL.r, Palette.CHARCOAL.g, Palette.CHARCOAL.b, 0.9)
  sb.set_corner_radius_all(6)
  sb.set_border_width_all(1)
  sb.border_color = Palette.GOLD
  frame.add_theme_stylebox_override("panel", sb)
  add_child(frame)

  _roster_por = TextureRect.new()
  _roster_por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _roster_por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  _roster_por.position = Vector2(5, 5)
  _roster_por.size = Vector2(24, 24)
  _roster_por.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _update_roster_portrait()
  add_child(_roster_por)

  var btn := _make_touch(Vector2(3, 3), ROSTER_BTN)
  btn.pressed.connect(_open_roster)
  add_child(btn)


## 진입 버튼 포트레이트를 현재 활성 메인으로 갱신.
func _update_roster_portrait() -> void:
  if _roster_por == null:
    return
  var path := Characters.portrait(_active_main)
  if ResourceLoader.exists(path):
    _roster_por.texture = load(path)


## 로스터 열기 — 다른 오버레이가 없을 때만(스왑 모드: 취소 가능). 열린 동안 셸 입력은 로스터로.
func _open_roster() -> void:
  if _reveal != null or _book != null or _popup != null or _cutin != null or _roster != null:
    return
  _roster = RosterScreen.new()
  _roster.setup(RosterScreen.MODE_SWAP, _active_main,
    String(SaveManager.get_value("flags.active_pet", Characters.default_pet())))
  _roster.confirmed.connect(_on_roster_confirmed)
  _roster.closed.connect(_on_roster_closed)
  add_child(_roster)  # 맨 위(HUD·액션바 덮음)


func _on_roster_closed() -> void:
  _roster = null


## 로스터 결정 → 활성 메인·펫 교체. (closed 도 뒤이어 와 _roster 를 정리)
func _on_roster_confirmed(main_id: String, pet_id: String) -> void:
  swap_active(main_id, pet_id)


## 활성 메인·펫을 교체하고 화면을 새 메인으로 갈아끼운다. (저장 + 라이브 스탠딩 텍스처 스왑)
## 시온이 교감 모드였으면 먼저 옥자 모드로 복귀해 줌·바·HUD 를 정돈한 뒤 교체한다.
## announce=false 면 입장 인사/효과음을 생략한다 — start() 가 자기 입장 연출을 따로 내므로,
## 온보딩 직후 세션 시작 시 저장된 active 메인·펫을 반영할 때(중복 인사 방지) 쓴다.
func swap_active(main_id: String, pet_id: String, announce := true) -> void:
  if _mode == MODE_SION:
    _exit_sion_mode()
  var changed := main_id != _active_main
  var pet_changed := pet_id != _active_pet
  _active_main = main_id
  _active_pet = pet_id
  SaveManager.set_value("flags.active_main", main_id)
  SaveManager.set_value("flags.active_pet", pet_id)
  SaveManager.save_game()

  _okja.set_character(main_id)  # 라이브 스탠딩 텍스처만 교체(트리/트윈 보존)
  if pet_changed:
    # 새 펫의 저장된 성장 단계를 반영해 라이브 스프라이트 교체(트리/트윈 보존) — 이슈 #6 / D1
    _sioni.set_prefix(Characters.pet_stage_prefix(pet_id, _pet_stage()))
  _update_roster_portrait()
  _hud.set_focus(main_id)       # 게이지·기분 표시를 새 메인으로
  _hud.refresh()
  if changed and announce:
    # 새 메인이 그 관계 단계에 맞춰 맞이한다(메인 바뀌면 인사도 바뀐 결).
    Sfx.event(&"scene_enter")
    _to_idle()
    _ticker.show_line(Dialogue.line(_dialogue_key(),"enter", meters.stage(), _nick()))


## 디버그 — 게이지를 즉시 채워 "오늘의 체키" 획득 리빌을 띄운다(컬렉션북 전 확인용).
## character: 옥자(DebugTools 키 4) / 시온이(키 6). 시온이 미보유 일반 → 중복 시 나비 승급 확인.
func debug_grant_cheki(character := Events.OKJA) -> void:
  if _reveal != null:
    return
  # 키 6(펫) = 현재 곁의 펫 / 키 4(메인) = 현재 교감 중인 메인. 게이지 풀로 채워 정규 경로를 탄다.
  character = _active_pet if not Characters.is_main(character) else _active_main
  SaveManager.set_value("%s.gauge" % character, Characters.gauge_full(character))
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


## 디버그 — 곁의 펫 생애단계 스프라이트를 순환(캐논→아기→유년→마름→통통, DebugTools 키 9).
## D0 아트 선행분(sioni_baby/child/thin/fat)을 D1 진화 엔진 전에 게임 안에서 눈으로 확인하는 용도.
## set_prefix 로 텍스처만 갈아끼우고 발밑 피벗은 그대로 — 아기는 작게·성체는 캐논 크기로 솟는다.
func debug_cycle_pet_stage() -> void:
  if _sioni == null:
    return
  var base := Characters.sprite_prefix(_active_pet)
  var labels := {"": "캐논(성체)", "_baby": "아기", "_child": "유년", "_thin": "마름", "_fat": "통통"}
  # 생애단계 아트가 실제로 있는 단계만 순환에 포함(시온이만 16컷 보유 — 다른 펫은 캐논만).
  var avail: Array[String] = [base]
  var names: Array[String] = [String(labels[""])]
  for suf in ["_baby", "_child", "_thin", "_fat"]:
    if ResourceLoader.exists("res://assets/sprites/%s%s_idle.png" % [base, suf]):
      avail.append(base + String(suf))
      names.append(String(labels[suf]))
  _dbg_pet_stage = (_dbg_pet_stage + 1) % avail.size()
  _sioni.set_prefix(avail[_dbg_pet_stage])
  _ticker.show_line("[디버그] 펫 단계: %s (%d/%d)" % [names[_dbg_pet_stage], _dbg_pet_stage + 1, avail.size()])


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
