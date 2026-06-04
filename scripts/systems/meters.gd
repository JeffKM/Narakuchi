class_name Meters
extends Node
## 미터 로직 (T08) — 호감도 게이지 · 스태미나 · 기분.
##
## SaveManager.data 를 단일 출처(SSOT)로 직접 읽고 쓴다. 모든 수치는 Balance(data/balance.gd)에서만.
## 옥자/시온이는 같은 시스템을 공유하지만, Phase 1 은 옥자 교감만 다룬다(시온이는 T15).
##
## 미터가 바뀌면 신호로 HUD·연출에 통지한다:
##   - changed        : 아무 미터나 변경 → HUD 갱신
##   - gauge_full(char): 게이지 가득 (실제 체키 획득은 T13)
##   - stage_changed(stage): 관계 단계 상승 (반말 전환 컷인은 T11)
##   - stamina_empty  : 스태미나 소진

signal changed
signal gauge_full(character: String)
signal stage_changed(stage: String)
signal stamina_empty

# 기분 단계 (벌 없는 설계: 시무룩까지만, 아프거나 떠나지 않음 → PRD §4.4)
const MOOD_HAPPY := "happy"
const MOOD_NORMAL := "normal"
const MOOD_SULKY := "sulky"
const _MOOD_ORDER := [MOOD_SULKY, MOOD_NORMAL, MOOD_HAPPY]  # 교감 1회마다 한 단계 회복

# begin_session() 결과 플래그 — 화면이 입장/복귀 연출을 고르는 데 쓴다.
var was_neglected := false  # 방치(24h+) 후 복귀로 시무룩해져 있었나


## 세션 시작 처리 — 일일 스태미나 회복 + 방치 기분 판정 + 출석 갱신.
## 화면(Cafe) 진입 시 1회 호출한다.
func begin_session() -> void:
  was_neglected = false
  var now := int(Time.get_unix_time_from_system())
  var last_saved := int(SaveManager.get_value("last_saved_unix", 0))

  # 1) 기분: 마지막 저장 이후 경과시간 (단, 첫 세션 last_saved==0 은 방치로 보지 않음)
  if last_saved > 0:
    var elapsed_h := float(now - last_saved) / 3600.0
    if elapsed_h >= float(Balance.MOOD_PENALTY_HOURS):
      SaveManager.set_value("okja.mood", MOOD_SULKY)
      was_neglected = true

  # 2) 일일 회복: 날짜가 바뀌었으면 스태미나 풀 충전 + 세션 누적값 리셋 + 출석 갱신
  var today := Time.get_date_string_from_system()  # 로컬 "YYYY-MM-DD"
  var last_date := String(SaveManager.get_value("attendance.last_date", ""))
  if last_date != today:
    SaveManager.set_value("stamina", Balance.STAMINA_MAX)
    SaveManager.set_value("session.touch_affinity", 0)
    _update_attendance(today, last_date, now)

  SaveManager.save_game()
  changed.emit()


## 관계 단계 문자열 ("guest"|"regular"|"close").
func stage() -> String:
  return Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0)))


# ── 스태미나 (세션 길이 게이트) ─────────────────────────────

## 액션 1회를 수행할 스태미나가 남았나. (터치는 무료라 검사 불필요)
func can_act() -> bool:
  return int(SaveManager.get_value("stamina", 0)) >= Balance.STAMINA_PER_ACTION


## 액션 1회분 스태미나를 소모한다. 소진되면 stamina_empty 통지.
func spend_stamina() -> void:
  var s := int(SaveManager.get_value("stamina", 0)) - Balance.STAMINA_PER_ACTION
  s = maxi(s, 0)
  SaveManager.set_value("stamina", s)
  changed.emit()
  if s < Balance.STAMINA_PER_ACTION:
    stamina_empty.emit()


# ── 호감도 (4버튼 교감) ────────────────────────────────────

## 옥자 호감도 획득(4버튼 액션). 시무룩이면 −20% 보정, 게이지 클램프, 단계/풀 판정.
## 반환값: 실제로 더해진 호감도(연출용).
func add_affinity_okja(base: int) -> int:
  var amount := base
  if String(SaveManager.get_value("okja.mood", MOOD_HAPPY)) == MOOD_SULKY:
    amount = int(round(float(base) * (1.0 - Balance.MOOD_PENALTY_RATE)))

  var before_stage := stage()
  _add_okja(amount)
  _recover_mood()  # 교감하면 기분이 한 단계 회복
  _post_affinity(before_stage)
  return amount


## 옥자 터치 호감도(무료, 세션 상한). 상한 도달 시 0 반환.
func add_touch_affinity() -> int:
  var used := int(SaveManager.get_value("session.touch_affinity", 0))
  var cap := Balance.AFF_TOUCH_SESSION_CAP
  if used >= cap:
    return 0
  var amount := mini(Balance.AFF_TOUCH, cap - used)
  SaveManager.set_value("session.touch_affinity", used + amount)

  var before_stage := stage()
  _add_okja(amount)
  _post_affinity(before_stage)
  return amount


# ── 내부 헬퍼 ─────────────────────────────────────────────

## 누적 호감도 + 게이지에 amount 를 더한다(게이지는 풀에서 클램프).
func _add_okja(amount: int) -> void:
  var total := int(SaveManager.get_value("okja.affinity_total", 0)) + amount
  var gauge := int(SaveManager.get_value("okja.gauge", 0)) + amount
  SaveManager.set_value("okja.affinity_total", total)
  SaveManager.set_value("okja.gauge", mini(gauge, Balance.GAUGE_OKJA))


## 호감도 가산 후 공통 처리: 단계 상승 통지 · 게이지 풀 통지 · 저장 · 갱신.
func _post_affinity(before_stage: String) -> void:
  var after_stage := stage()
  if after_stage != before_stage:
    stage_changed.emit(after_stage)
  if int(SaveManager.get_value("okja.gauge", 0)) >= Balance.GAUGE_OKJA:
    gauge_full.emit(Events.OKJA)
  SaveManager.save_game()
  changed.emit()


## 기분을 한 단계 끌어올린다(sulky → normal → happy).
func _recover_mood() -> void:
  var cur := String(SaveManager.get_value("okja.mood", MOOD_HAPPY))
  var idx := _MOOD_ORDER.find(cur)
  if idx >= 0 and idx < _MOOD_ORDER.size() - 1:
    SaveManager.set_value("okja.mood", _MOOD_ORDER[idx + 1])


## 출석/연속출석 갱신 (데모용 간략판 — 마일스톤 보상은 T14).
## 어제 방문이면 streak+1, 아니면 1로 리셋(벌점 없음). 그날 코인 +1.
func _update_attendance(today: String, last_date: String, now: int) -> void:
  var streak := 1
  if last_date != "":
    var yesterday := Time.get_datetime_string_from_unix_time(now - 86400).split("T")[0]
    if last_date == yesterday:
      streak = int(SaveManager.get_value("attendance.streak", 0)) + 1
  SaveManager.set_value("attendance.last_date", today)
  SaveManager.set_value("attendance.streak", streak)
  # 출석 코인 (PRD §4.5 — 매일 +코인)
  var coins := int(SaveManager.get_value("player.coins", 0)) + 1
  SaveManager.set_value("player.coins", coins)
