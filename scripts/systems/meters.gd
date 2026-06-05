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
# 연속출석 마일스톤(3일/7일) 보상이 이번 세션에 발생했나 (T14). Cafe.start() 가 보상 리빌로 소비.
#   {} = 없음 / { streak:int, reward:Dictionary(Cheki.add_shards 결과) }
var pending_milestone: Dictionary = {}


## 세션 진입 판정 (읽기전용) — 스플래시/카페가 입장·복귀·출석 연출을 고를 때 쓴다.
## ⚠️ 저장을 건드리지 않는다(쓰기는 begin_session). 스플래시는 카페보다 먼저 떠서
##    streak/방치 여부를 미리 보여줘야 하므로, 판정만 떼어 두 곳에서 공유한다.
## 반환: { "was_neglected": bool, "is_new_day": bool, "streak": int }
##   streak = 오늘 출석을 반영한 "예정" 연속일(아직 커밋 전이라도 화면엔 이 값을 노출).
static func evaluate_session() -> Dictionary:
  var now := int(Time.get_unix_time_from_system())
  var last_saved := int(SaveManager.get_value("last_saved_unix", 0))

  # 방치: 마지막 저장 이후 경과시간 (첫 세션 last_saved==0 은 방치 아님)
  var neglected := false
  if last_saved > 0:
    var elapsed_h := float(now - last_saved) / 3600.0
    neglected = elapsed_h >= float(Balance.MOOD_PENALTY_HOURS)

  # 출석: 날짜가 바뀌었나 + 오늘을 반영한 예정 streak
  var today := Time.get_date_string_from_system()  # 로컬 "YYYY-MM-DD"
  var last_date := String(SaveManager.get_value("attendance.last_date", ""))
  var is_new_day := last_date != today
  var streak := int(SaveManager.get_value("attendance.streak", 0))
  if is_new_day:
    var yesterday := Time.get_datetime_string_from_unix_time(now - 86400).split("T")[0]
    streak = (streak + 1) if (last_date != "" and last_date == yesterday) else 1

  return {"was_neglected": neglected, "is_new_day": is_new_day, "streak": streak}


## 세션 시작 처리 — 판정(evaluate_session)을 적용·저장한다(스태미나 회복·기분·출석).
## 화면(Cafe) 진입 시 1회 호출한다(단일 진실원). 스플래시는 evaluate_session 만 읽는다.
func begin_session() -> void:
  var eval := evaluate_session()
  was_neglected = bool(eval["was_neglected"])
  pending_milestone = {}

  # 1) 기분: 방치였으면 시무룩
  if was_neglected:
    SaveManager.set_value("okja.mood", MOOD_SULKY)

  # 2) 일일 회복: 날짜가 바뀌었으면 스태미나 풀 충전 + 세션 누적값 리셋 + 출석 갱신
  if bool(eval["is_new_day"]):
    var now := int(Time.get_unix_time_from_system())
    var today := Time.get_date_string_from_system()
    var last_date := String(SaveManager.get_value("attendance.last_date", ""))
    SaveManager.set_value("stamina", Balance.STAMINA_MAX)
    SaveManager.set_value("session.touch_affinity", 0)
    var streak := _update_attendance(today, last_date, now)
    pending_milestone = _check_milestone(streak)  # 3일/7일 → 나비 조각 보상 (T14)

  SaveManager.save_game()
  changed.emit()


## 관계 단계 문자열 ("guest"|"regular"|"close").
func stage() -> String:
  return Balance.relationship_stage(int(SaveManager.get_value("okja.affinity_total", 0)))


## 출석 진행 상태(표시용, 읽기전용) — 컬렉션북/HUD 의 "출석 N일 · 다음 보상까지 D일" 표기에 쓴다. (T14)
## next = 아직 안 받은 다음 마일스톤 일수(3→7→없으면 0=다 받음). remaining = 거기까지 남은 일.
## streak 은 begin_session 이 그날 커밋한 값이라, 세션 중에는 '오늘 포함' 연속일을 반영한다.
static func attendance_status() -> Dictionary:
  var streak := int(SaveManager.get_value("attendance.streak", 0))
  var next := 0
  if streak < Balance.ATTENDANCE_MILESTONE_3:
    next = Balance.ATTENDANCE_MILESTONE_3
  elif streak < Balance.ATTENDANCE_MILESTONE_7:
    next = Balance.ATTENDANCE_MILESTONE_7
  var remaining := (next - streak) if next > 0 else 0
  return {"streak": streak, "next": next, "remaining": remaining}


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


## 게이지를 비운다(0). "오늘의 체키" 획득 후 호출 — 안 비우면 매 액션마다 gauge_full 재발화.
func consume_gauge_okja() -> void:
  SaveManager.set_value("okja.gauge", 0)
  SaveManager.save_game()
  changed.emit()


## 시온이 호감도 획득(간식/놀기/쓰담/체키). 시온이는 펫이라 기분·관계 단계 없음(게이지만).
## 반환값: 실제로 더해진 호감도(연출용).
func add_affinity_sion(base: int) -> int:
  var total := int(SaveManager.get_value("sion.affinity_total", 0)) + base
  var gauge := int(SaveManager.get_value("sion.gauge", 0)) + base
  SaveManager.set_value("sion.affinity_total", total)
  SaveManager.set_value("sion.gauge", mini(gauge, Balance.GAUGE_SION))
  if gauge >= Balance.GAUGE_SION:
    gauge_full.emit(Events.SION)
  SaveManager.save_game()
  changed.emit()
  return base


## 시온이 게이지를 비운다(0). "오늘의 체키"(시온이) 획득 후 호출.
func consume_gauge_sion() -> void:
  SaveManager.set_value("sion.gauge", 0)
  SaveManager.save_game()
  changed.emit()


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


## 출석/연속출석 갱신. 어제 방문이면 streak+1, 아니면 1로 리셋(벌점 없음). 그날 코인 +1.
## 갱신된 연속출석 일수(streak)를 반환한다 — 마일스톤 판정(T14)에 쓴다.
func _update_attendance(today: String, last_date: String, now: int) -> int:
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
  return streak


## 연속출석 마일스톤(3일/7일) 보상 판정 (T14) — 정확히 그 일수에 도달한 날에만 나비 조각 적립.
## 보유한 일반 칸 중 승급에 가까운 칸에 조각을 넣는다(Cheki.grant_milestone_shards).
## 반환: { streak, reward } / 마일스톤 아님·적립 불가면 {}.
func _check_milestone(streak: int) -> Dictionary:
  var amount := 0
  if streak == Balance.ATTENDANCE_MILESTONE_7:
    amount = Balance.ATTENDANCE_REWARD_SHARDS_7
  elif streak == Balance.ATTENDANCE_MILESTONE_3:
    amount = Balance.ATTENDANCE_REWARD_SHARDS_3
  if amount == 0:
    return {}
  var reward := Cheki.grant_milestone_shards(amount)
  if reward.is_empty():
    return {}
  return {"streak": streak, "reward": reward}
