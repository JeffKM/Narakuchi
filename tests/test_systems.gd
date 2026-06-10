extends TestBase
## 시스템 회귀 테스트 (T23 재설계) — Meters(출석·기분·스태미나)·SaveManager(영속)·Clock seam.
## Clock override 로 "날짜를 하루씩 넘기는" 진짜 멀티데이 체인을 검증한다(시스템 시계 비의존).
##
## 실행: godot --headless res://tests/test_systems.tscn  (전수는 tools/run_tests.sh)
##
## 구성: A 출석/날짜 체인 · B 기분/방치 · D 세이브 영속 · E 스태미나/세션 · 케이던스(밸런스)
##   + 구 test_phase2 의 미터 마일스톤/출석표시 절 이전.

func _init() -> void:
  _suite = "시스템 회귀"


func run_suite() -> void:
  # A 출석/날짜
  _test_attendance_chain()
  _test_attendance_break_reset()
  _test_same_day_idempotent()
  _test_meters_milestone()        # 이전(구 test_phase2)
  _test_attendance_status()       # 이전(구 test_phase2)
  # B 기분/방치
  _test_neglect_boundary()
  _test_sulky_penalty()
  _test_mood_recovery()
  # D 세이브 영속
  _test_wipe_reset()
  _test_save_load_roundtrip()
  _test_corrupt_save_fallback()
  # E 스태미나/세션
  _test_stamina_drain()
  _test_stamina_daily_refill()
  # 케이던스(밸런스 확인)
  _test_progression_cadence()
  # F 캐릭터 레지스트리 + 미호 라이브 (T30 / 이슈 #2)
  _test_character_registry()
  # G 로스터 선택 (#3) — active_pet 스키마 + 화면 결정 경로
  await _test_roster_selection()
  # H 규종이 펫 슬라이스 (이슈 #6) — 제네릭 펫 미터/체키 경로(시온이 미러)
  _test_gyujong_pet()


# 새 미터를 만들어 프레임 안에서 1회 begin_session 한다(테스트 후 free).
func _begin() -> void:
  var m := Meters.new()
  m.begin_session()
  m.free()


# ════════════════════════════════════════════════════════════
#  A. 출석 / 날짜 체인 (Clock 으로 며칠을 이어서 진행)
# ════════════════════════════════════════════════════════════

## 1→7일 연속 출석을 "이어서" 진행 — 매일 begin_session 이 streak 를 누적하고
## last_date 를 그날로 커밋(다음 날 어제 판정의 입력)하며, 3·7일에 마일스톤이 뜨는지.
func _test_attendance_chain() -> void:
  wipe()
  Cheki.grant(Events.OKJA, "mine")  # 마일스톤 보상 적립용 일반 칸
  Clock.set_day("2026-03-01")

  for day in range(1, 8):
    if day > 1:
      Clock.advance_days(1)  # 다음 달력일로
    var m := Meters.new()
    m.begin_session()
    var streak := int(SaveManager.get_value("attendance.streak", 0))
    check(streak == day, "%d일째: streak == %d (got %d)" % [day, day, streak])
    check(String(SaveManager.get_value("attendance.last_date", "")) == Clock.today(),
      "%d일째: last_date 가 오늘로 커밋" % day)
    var is_milestone := (day == 3 or day == 7)
    check(m.pending_milestone.is_empty() != is_milestone,
      "%d일째: 마일스톤 %s" % [day, "발생" if is_milestone else "없음"])
    m.free()


## 하루 건너뛰면(끊김) streak 가 1로 리셋된다(벌점 없는 설계 — 그냥 다시 1일째).
func _test_attendance_break_reset() -> void:
  wipe()
  Clock.set_day("2026-03-01")
  _begin()                          # 1일째
  Clock.advance_days(1); _begin()   # 2일째
  check(int(SaveManager.get_value("attendance.streak", 0)) == 2, "연속 2일 누적 확인")

  Clock.advance_days(2)             # 하루 건너뜀(이틀 뒤)
  _begin()
  check(int(SaveManager.get_value("attendance.streak", 0)) == 1,
    "하루 건너뛰면 streak=1 리셋 (got %d)" % int(SaveManager.get_value("attendance.streak", 0)))


## 같은 날 재진입은 멱등 — streak 안 늘고, 스태미나 재충전·세션 누적 리셋 안 일어남.
func _test_same_day_idempotent() -> void:
  wipe()
  Clock.set_day("2026-03-01")
  _begin()                          # 1일째: 스태미나 풀
  check(int(SaveManager.get_value("attendance.streak", 0)) == 1, "첫 진입 streak 1")

  # 같은 날 스태미나를 일부 소모 + 터치 누적을 만든 뒤 재진입
  SaveManager.set_value("stamina", 10)
  SaveManager.set_value("session.touch_affinity", 6)
  _begin()                          # 같은 날 재진입(멱등이어야)
  check(int(SaveManager.get_value("attendance.streak", 0)) == 1,
    "같은 날 재진입: streak 그대로 1")
  check(int(SaveManager.get_value("stamina", 0)) == 10,
    "같은 날 재진입: 스태미나 재충전 안 함 (got %d)" % int(SaveManager.get_value("stamina", 0)))
  check(int(SaveManager.get_value("session.touch_affinity", 0)) == 6,
    "같은 날 재진입: 세션 터치 누적 리셋 안 함")


## (이전) 3일째 도달 시 마일스톤, 2일째는 아님 — Clock 으로 결정적 재작성.
func _test_meters_milestone() -> void:
  wipe()
  Cheki.grant(Events.OKJA, "mine")
  Clock.set_day("2026-04-10")
  SaveManager.set_value("attendance.last_date", ymd(-1))  # 어제 방문
  SaveManager.set_value("attendance.streak", 2)
  var m := Meters.new()
  m.begin_session()
  check(not m.pending_milestone.is_empty(), "3일 연속 → 마일스톤 발생")
  if not m.pending_milestone.is_empty():
    check(int(m.pending_milestone["streak"]) == 3, "마일스톤 streak == 3")
    check(m.pending_milestone.has("reward"), "마일스톤 reward 동봉")
  m.free()

  wipe()
  Cheki.grant(Events.OKJA, "mine")
  Clock.set_day("2026-04-10")
  SaveManager.set_value("attendance.last_date", ymd(-1))
  SaveManager.set_value("attendance.streak", 1)
  var m2 := Meters.new()
  m2.begin_session()
  check(m2.pending_milestone.is_empty(), "2일째는 마일스톤 아님")
  m2.free()


## (이전) 출석 진행 표시(next/remaining) — 순수 계산, 날짜 무관.
func _test_attendance_status() -> void:
  wipe()
  SaveManager.set_value("attendance.streak", 1)
  var s1 := Meters.attendance_status()
  check(int(s1["next"]) == 3, "streak 1 → 다음 마일스톤 3 (got %d)" % int(s1["next"]))
  check(int(s1["remaining"]) == 2, "streak 1 → 2일 남음 (got %d)" % int(s1["remaining"]))

  SaveManager.set_value("attendance.streak", 3)
  var s3 := Meters.attendance_status()
  check(int(s3["next"]) == 7, "streak 3 → 다음 마일스톤 7")
  check(int(s3["remaining"]) == 4, "streak 3 → 7일까지 4일 남음 (got %d)" % int(s3["remaining"]))

  SaveManager.set_value("attendance.streak", 9)
  var s9 := Meters.attendance_status()
  check(int(s9["next"]) == 0, "streak 9 → 남은 마일스톤 없음(next 0)")
  check(int(s9["streak"]) == 9, "streak 값 그대로 노출")


# ════════════════════════════════════════════════════════════
#  B. 기분 / 방치 (시무룩)
# ════════════════════════════════════════════════════════════

## 방치 경계: 마지막 저장 후 24h+ 면 시무룩, 미만이면 아님.
func _test_neglect_boundary() -> void:
  # 24h 초과 → 시무룩
  wipe()
  Clock.set_day("2026-05-01")
  SaveManager.save_game()                         # last_saved = 5/1 정오
  Clock.freeze_at(Clock.now() + 25 * 3600)        # 25시간 뒤
  _begin()
  check(String(SaveManager.get_value("okja.mood", "happy")) == Meters.MOOD_SULKY,
    "25h 방치 → 시무룩")

  # 24h 미만 → 시무룩 아님(기분 유지)
  wipe()
  Clock.set_day("2026-05-01")
  SaveManager.save_game()
  Clock.freeze_at(Clock.now() + 23 * 3600)        # 23시간 뒤(다음날·방치 아님)
  _begin()
  check(String(SaveManager.get_value("okja.mood", "happy")) != Meters.MOOD_SULKY,
    "23h 재방문 → 시무룩 아님")


## 시무룩이면 호감도 획득이 −20%(MOOD_PENALTY_RATE) 적용된다.
func _test_sulky_penalty() -> void:
  wipe()
  SaveManager.set_value("okja.mood", Meters.MOOD_SULKY)
  var m := Meters.new()
  var base := 20
  var gained := m.add_affinity_okja(base)
  var expected := int(round(float(base) * (1.0 - Balance.MOOD_PENALTY_RATE)))
  check(gained == expected, "시무룩 −20%%: base %d → %d (got %d)" % [base, expected, gained])
  m.free()


## 교감 1회마다 기분이 한 단계 회복(sulky → normal → happy).
func _test_mood_recovery() -> void:
  wipe()
  SaveManager.set_value("okja.mood", Meters.MOOD_SULKY)
  var m := Meters.new()
  m.add_affinity_okja(10)
  check(String(SaveManager.get_value("okja.mood", "")) == Meters.MOOD_NORMAL,
    "교감 1회: sulky → normal")
  m.add_affinity_okja(10)
  check(String(SaveManager.get_value("okja.mood", "")) == Meters.MOOD_HAPPY,
    "교감 2회: normal → happy")
  m.free()


# ════════════════════════════════════════════════════════════
#  D. 세이브 영속 (초기화 · 라운드트립 · 손상 폴백)
# ════════════════════════════════════════════════════════════

## wipe = 파일 삭제 + 메모리 기본값 / reset = 기본값 + 파일 저장.
func _test_wipe_reset() -> void:
  SaveManager.set_value("player.nickname", "지은")
  SaveManager.save_game()
  check(FileAccess.file_exists(SAVE_PATH), "save_game 후 파일 존재")

  SaveManager.wipe()
  check(not FileAccess.file_exists(SAVE_PATH), "wipe 후 파일 삭제됨")
  check(String(SaveManager.get_value("player.nickname", "?")) == "",
    "wipe 후 메모리 기본값(닉 빈값)")

  SaveManager.reset()
  check(FileAccess.file_exists(SAVE_PATH), "reset 후 파일 저장됨")
  check(int(SaveManager.get_value("okja.affinity_total", -1)) == 0, "reset 후 기본 호감도 0")


## build_state 로 만든 상태를 저장→로드하면 그대로 복원된다(직렬화 정합 — ② 영속 1차 방어선).
func _test_save_load_roundtrip() -> void:
  SaveManager.data = SaveManager.build_state({
    "nickname": "지은",
    "coins": 7,
    "onboarded": true,
    "announced_stage": "comfy",
    "okja_affinity": 640,
    "okja_gauge": 120,
    "okja_mood": Meters.MOOD_NORMAL,
    "sion_affinity": 90,
    "attendance_streak": 5,
    "attendance_last_date": "2026-03-05",
  })
  SaveManager.save_game()
  SaveManager.data = {}              # 메모리 비우고
  SaveManager.load_game()           # 디스크에서 복원

  check(String(SaveManager.get_value("player.nickname", "")) == "지은", "라운드트립: 닉")
  check(int(SaveManager.get_value("player.coins", 0)) == 7, "라운드트립: 코인")
  check(bool(SaveManager.get_value("flags.onboarded", false)), "라운드트립: onboarded")
  check(String(SaveManager.get_value("flags.announced_stage", "")) == "comfy", "라운드트립: announced")
  check(int(SaveManager.get_value("okja.affinity_total", 0)) == 640, "라운드트립: 옥자 호감도")
  check(int(SaveManager.get_value("okja.gauge", 0)) == 120, "라운드트립: 옥자 게이지")
  check(String(SaveManager.get_value("okja.mood", "")) == Meters.MOOD_NORMAL, "라운드트립: 기분")
  check(int(SaveManager.get_value("sion.affinity_total", 0)) == 90, "라운드트립: 시온 호감도")
  check(int(SaveManager.get_value("attendance.streak", 0)) == 5, "라운드트립: 연속출석")
  check(String(SaveManager.get_value("attendance.last_date", "")) == "2026-03-05", "라운드트립: 출석일")


## 손상된 JSON 세이브를 만나도 크래시 없이 기본 세이브로 폴백한다.
func _test_corrupt_save_fallback() -> void:
  var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  f.store_string("{ 이건 망가진 JSON 입니다 ")
  f.close()
  SaveManager.load_game()           # 파싱 실패 → 기본값 폴백(push_warning, 크래시 X)
  # default_save 는 flags.onboarded 키를 안 두므로(온보딩 완료 시에만 set), 프로덕션과 같이 false 기본으로 읽는다.
  check(not bool(SaveManager.get_value("flags.onboarded", false)),
    "손상 세이브 → 기본값 폴백(미온보딩)")
  check(String(SaveManager.get_value("player.nickname", "?")) == "",
    "손상 세이브 → 닉 빈값(기본 스키마)")
  check(int(SaveManager.get_value("okja.affinity_total", -1)) == 0,
    "손상 세이브 → 기본 호감도 0")


# ════════════════════════════════════════════════════════════
#  E. 스태미나 / 세션 길이
# ════════════════════════════════════════════════════════════

## 하루 액션 예산 = STAMINA_MAX / STAMINA_PER_ACTION 회. 소진되면 stamina_empty + can_act 거짓.
func _test_stamina_drain() -> void:
  wipe()
  var budget := Balance.STAMINA_MAX / Balance.STAMINA_PER_ACTION  # 설계상 하루 액션 수
  SaveManager.set_value("stamina", Balance.STAMINA_MAX)
  var m := Meters.new()
  var empty_fired := [false]
  m.stamina_empty.connect(func() -> void: empty_fired[0] = true)

  for i in range(budget):
    check(m.can_act(), "액션 %d/%d: 아직 가능" % [i + 1, budget])
    m.spend_stamina()
  check(not m.can_act(), "%d액션 후 소진 → can_act 거짓" % budget)
  check(empty_fired[0], "소진 시 stamina_empty 발화")
  check(budget == 6, "설계 불변식: 하루 6액션(=세션 1~3분 근거) (got %d)" % budget)
  m.free()


## 날짜가 바뀌면 begin_session 이 스태미나를 풀 충전한다.
func _test_stamina_daily_refill() -> void:
  wipe()
  Clock.set_day("2026-03-01")
  _begin()
  SaveManager.set_value("stamina", 0)               # 그날 다 씀
  Clock.advance_days(1)
  _begin()                                          # 새 날 진입
  check(int(SaveManager.get_value("stamina", 0)) == Balance.STAMINA_MAX,
    "새 날 → 스태미나 풀 충전 (got %d)" % int(SaveManager.get_value("stamina", 0)))


# ════════════════════════════════════════════════════════════
#  진행 케이던스 (밸런스 확인) — 며칠에 단골/반말에 도달하나
# ════════════════════════════════════════════════════════════
# "꾸준히 들르는" 플레이어 가정(방치 페널티 분리: 매일 23h 간격 = 다음날·시무룩 아님).
# 상한(매일 알찬 교감) / 하한(매일 무난한 대화)으로 도달 일수가 넓은 설계 밴드 안인지 단언.
# 설계 의도(PRD §4.5): 단골 ~3일, 반말 전환 ~1주. 밴드는 콘텐츠 튜닝은 통과·망가진 설계만 잡게 넓게.

const _CADENCE_REGULAR_MAX_DAYS := 7   # 단골(200) 도달 상한(가장 느린 플레이)
const _CADENCE_COMFY_MAX_DAYS := 16    # 반말(600) 도달 상한(가장 느린 플레이)

func _test_progression_cadence() -> void:
  var fast_reg := _days_to_stage("regular", true)
  var slow_reg := _days_to_stage("regular", false)
  var fast_com := _days_to_stage("comfy", true)
  var slow_com := _days_to_stage("comfy", false)
  print("    · 케이던스 단골(200): 알찬 %d일 / 무난 %d일" % [fast_reg, slow_reg])
  print("    · 케이던스 반말(600): 알찬 %d일 / 무난 %d일" % [fast_com, slow_com])

  # 단조성: 알찬 플레이가 무난 플레이보다 빠르거나 같다.
  check(fast_reg <= slow_reg, "단골: 알찬 ≤ 무난 (페이스 단조)")
  check(fast_com <= slow_com, "반말: 알찬 ≤ 무난 (페이스 단조)")
  # 빠르게 깨지지 않음: 단골이 하루만에/반말이 며칠만에 = 설계 붕괴 방지(반말은 장기 보상).
  check(fast_reg >= 2, "단골은 최소 2일+ (즉시 도달 아님)")
  check(fast_com >= 5, "반말은 최소 5일+ (장기 보상 — 첫날 전환 금지)")
  # 너무 느리지 않음: 넓은 설계 밴드 상한.
  check(slow_reg <= _CADENCE_REGULAR_MAX_DAYS,
    "단골 도달 ≤ %d일 (got %d)" % [_CADENCE_REGULAR_MAX_DAYS, slow_reg])
  check(slow_com <= _CADENCE_COMFY_MAX_DAYS,
    "반말 도달 ≤ %d일 (got %d)" % [_CADENCE_COMFY_MAX_DAYS, slow_com])


## 목표 단계에 도달하기까지 걸린 '일수'. high=알찬 교감(상한)/false=무난(하한).
## 매일: 23h 간격으로 새 날 진입(시무룩 회피) → 스태미나 예산만큼 교감 → 호감도 누적.
# ════════════════════════════════════════════════════════════
#  F. 캐릭터 레지스트리 + 미호 라이브 (T30 / 이슈 #2 트레이서)
# ════════════════════════════════════════════════════════════

## 레지스트리 구성 + 미호가 제네릭 미터/체키 경로를 그대로 타는지(옥자와 격리).
func _test_character_registry() -> void:
  # 레지스트리: 메인 4(옥자·미호·바나·멜) + 펫 5(시온이·규종이·코코·선아·수아). 게이지 풀은 Balance 단일 출처.
  # 멜은 라이브(로스터·교감) 선행 배선(idle 확인) — 표정·체키 아트(#13)·전용 대사(#14)는 후속.
  # 선아(갈색 푸들)·수아(베이지 닥스훈트)는 멜 펫 슬라이스에서 idle 확정 + 전용 버튼/티커 배선(수아=선아 미러).
  check(Characters.mains() == ["okja", "miho", "bana", "mel"], "메인 = 옥자·미호·바나·멜")
  check(Characters.pets() == ["sion", "gyujong", "coco", "suna", "sua"], "펫 = 시온이·규종이·코코·선아·수아")
  check(Characters.gauge_full("suna") == Balance.GAUGE_SUNA, "선아 게이지 풀 = Balance.GAUGE_SUNA")
  check(Characters.gauge_full("sua") == Balance.GAUGE_SUA, "수아 게이지 풀 = Balance.GAUGE_SUA")
  check(Characters.has_mood("miho") and not Characters.has_mood("sion"),
    "메인만 기분 보유(미호 O, 시온이 X)")
  check(Characters.gauge_full("miho") == Balance.GAUGE_MIHO, "미호 게이지 풀 = Balance.GAUGE_MIHO")
  check(Characters.gauge_full("mel") == Balance.GAUGE_MEL, "멜 게이지 풀 = Balance.GAUGE_MEL")

  # 세이브 스키마: 미호 블록(기분 포함) + 기본 active_main = 옥자.
  wipe()
  var d := SaveManager.default_save()
  check(d.has("miho") and d["miho"].has("mood"), "default_save 에 미호 블록(기분 포함)")
  check(String(d["flags"]["active_main"]) == "okja", "기본 active_main = 옥자")

  # 제네릭 미터: 미호 호감도 누적 → 게이지 풀에서 gauge_full(\"miho\") 발화. 옥자와 격리.
  var m := Meters.new()
  var emitted := {"id": ""}
  m.gauge_full.connect(func(c: String) -> void: emitted["id"] = c)
  m.add_affinity_main("miho", Balance.GAUGE_MIHO)
  check(emitted["id"] == "miho", "미호 게이지 풀 → gauge_full(\"miho\")")
  check(int(SaveManager.get_value("miho.gauge", -1)) == Balance.GAUGE_MIHO, "미호 게이지 = 풀값")
  check(int(SaveManager.get_value("okja.gauge", -1)) == 0, "옥자 게이지는 불변(캐릭터 격리)")
  m.free()

  # active_main=미호 면 인자 없는 stage() 가 미호 단계를 가리킨다(stage_of 는 캐릭터별 독립).
  SaveManager.set_value("flags.active_main", "miho")
  SaveManager.set_value("miho.affinity_total", Balance.REL_REGULAR)
  var m2 := Meters.new()
  check(m2.stage() == "regular", "active_main=미호: stage() = 미호 단계")
  check(m2.stage_of("okja") == "guest", "stage_of(okja) 는 독립")
  m2.free()

  # 체키: 미호의 오늘 체키 = 지뢰계, grant 가 미호 슬롯에 적립.
  wipe()
  check(Cheki.pick_today("miho") == "mine", "미호 오늘의 체키 = 지뢰계(mine)")
  var res := Cheki.grant("miho", "mine")
  check(String(res.get("character", "")) == "miho" and Cheki.owned("miho", "mine"),
    "미호 지뢰계 체키 grant → 보유")


# ════════════════════════════════════════════════════════════
#  G. 로스터 선택 (#3) — active_pet 스키마 + RosterScreen 결정 경로
# ════════════════════════════════════════════════════════════

## 세이브 스키마(active_pet) + 레지스트리 파생 헬퍼 + 화면 결정이 고른 쌍을 방출하는지.
func _test_roster_selection() -> void:
  wipe()
  # 스키마: 기본 active_pet = 시온이 + build_state 지원.
  var d := SaveManager.default_save()
  check(String(d["flags"]["active_pet"]) == "sion", "기본 active_pet = 시온이")
  check(Characters.default_pet() == "sion", "Characters.default_pet() = 시온이")
  var bs := SaveManager.build_state({"active_main": "miho", "active_pet": "sion"})
  check(String(bs["flags"]["active_main"]) == "miho", "build_state active_main = 미호")
  # 레지스트리 파생 헬퍼(카드 부제·포트레이트 경로).
  check(Characters.tag("sion") != "", "펫 부제(tag) 존재")
  check(Characters.portrait("miho") == "res://assets/sprites/portrait_miho.png",
    "포트레이트 경로 파생")

  # 화면 스모크: 미호 미리선택을 옥자로 바꿔 결정하면 confirmed(okja, sion) 1회.
  var roster := RosterScreen.new()
  roster.setup(RosterScreen.MODE_SWAP, "miho", "sion")
  var got := {"main": "", "pet": "", "n": 0}
  roster.confirmed.connect(func(m: String, p: String) -> void:
    got["main"] = m
    got["pet"] = p
    got["n"] += 1)
  add_child(roster)
  await get_tree().process_frame
  roster._select(Characters.MAIN, "okja")  # 그룹 단일 선택 변경
  # 셸 커서를 결정 버튼까지 돌려 OK.
  for _i in range(roster._focus_nodes.size()):
    if String(roster._focus_nodes[roster._cursor]["kind"]) == "confirm":
      break
    roster.handle_shell_action(&"select")
  roster.handle_shell_action(&"ok")
  check(got["n"] == 1 and got["main"] == "okja" and got["pet"] == "sion",
    "로스터: 옥자 재선택 → confirmed(okja, sion) 1회")
  roster.queue_free()


# ════════════════════════════════════════════════════════════
#  H. 규종이 펫 슬라이스 (이슈 #6) — 제네릭 펫 경로(시온이 미러)
# ════════════════════════════════════════════════════════════

## 규종이가 시온이와 같은 제네릭 펫 미터/체키 경로를 그대로 타는지(시온이와 격리·회귀 없음).
func _test_gyujong_pet() -> void:
  # 레지스트리: 펫(게이지만, 기분 없음) + 게이지 풀 Balance 단일 출처.
  check("gyujong" in Characters.pets(), "규종이 = 펫 로스터 포함")
  check(not Characters.is_main("gyujong") and not Characters.has_mood("gyujong"),
    "규종이는 펫(기분·관계 단계 없음)")
  check(Characters.gauge_full("gyujong") == Balance.GAUGE_GYUJONG,
    "규종이 게이지 풀 = Balance.GAUGE_GYUJONG")
  check(Characters.dialogue_key("gyujong") == "gyujong", "규종이 전용 티커 키")

  # 세이브 스키마: 규종이 블록(기분 없음) — 레지스트리 주도로 자동 생성.
  wipe()
  var d := SaveManager.default_save()
  check(d.has("gyujong") and not d["gyujong"].has("mood"),
    "default_save 에 규종이 블록(펫 — 기분 없음)")

  # 제네릭 펫 미터: 규종이 게이지 풀 → gauge_full("gyujong"). 시온이와 격리.
  wipe()
  var m := Meters.new()
  var emitted := {"id": ""}
  m.gauge_full.connect(func(c: String) -> void: emitted["id"] = c)
  m.add_affinity_pet("gyujong", Balance.GAUGE_GYUJONG)
  check(emitted["id"] == "gyujong", "규종이 게이지 풀 → gauge_full(\"gyujong\")")
  check(int(SaveManager.get_value("gyujong.gauge", -1)) == Balance.GAUGE_GYUJONG,
    "규종이 게이지 = 풀값")
  check(int(SaveManager.get_value("sion.gauge", -1)) == 0, "시온이 게이지 불변(펫 격리)")
  m.consume_gauge_pet("gyujong")
  check(int(SaveManager.get_value("gyujong.gauge", -1)) == 0, "규종이 게이지 소진 → 0")
  m.free()

  # 시온이 백호환 래퍼는 여전히 sion 으로 적립(회귀 없음).
  wipe()
  var m2 := Meters.new()
  m2.add_affinity_sion(10)
  check(int(SaveManager.get_value("sion.gauge", -1)) == 10, "add_affinity_sion 회귀: sion 적립")
  check(int(SaveManager.get_value("gyujong.gauge", -1)) == 0, "시온이 적립이 규종이로 새지 않음")
  m2.free()

  # 체키: 규종이 오늘 체키 = 지뢰계(아트 준비됨), grant 가 규종이 슬롯에 적립.
  wipe()
  check(Events.events_for("gyujong") == ["mine", "xmas"], "규종이 보유 이벤트 = 지뢰계·크리스마스")
  check(Cheki.pick_today("gyujong") == "mine", "규종이 오늘의 체키 = 지뢰계(mine)")
  var res := Cheki.grant("gyujong", "mine")
  check(String(res.get("character", "")) == "gyujong" and Cheki.owned("gyujong", "mine"),
    "규종이 지뢰계 체키 grant → 보유")


func _days_to_stage(target: String, high: bool) -> int:
  wipe()
  Clock.set_day("2026-01-01")
  Clock.freeze_at(Clock.now() + 20 * 3600)  # 20:00 시작(23h 스텝이 자정 안 넘게)
  var threshold := Balance.stage_threshold(target)
  var budget := Balance.STAMINA_MAX / Balance.STAMINA_PER_ACTION
  var per_action := _action_values(high)
  var day := 0
  while day < 60:
    if day > 0:
      Clock.freeze_at(Clock.now() + 23 * 3600)  # 다음날(방치 아님)
    day += 1
    var m := Meters.new()
    m.begin_session()                            # 새 날: 스태미나 풀
    for i in range(budget):
      if not m.can_act():
        break
      m.spend_stamina()
      m.add_affinity_okja(per_action[i % per_action.size()])
    var reached := int(SaveManager.get_value("okja.affinity_total", 0)) >= threshold
    m.free()
    if reached:
      return day
  return 999  # 도달 실패(밴드 단언이 잡음)


## 하루치 교감 액션 호감도 배열. high=선호 음료/좋은 대화/매칭 선물 위주, low=무난 대화 위주.
## 수치는 전부 Balance 게이트웨이에서(단일 출처) — 콘텐츠 튜닝이 케이던스에 그대로 반영된다.
func _action_values(high: bool) -> Array:
  if high:
    return [
      Balance.aff_gift("match"),       # 선물(취향 적중)
      Balance.aff("drink_favorite"),   # 최애 음료
      Balance.aff_talk("good"),        # 좋은 대화
      Balance.aff("cheki"),            # 체키 주문
      Balance.aff("drink_favorite"),
      Balance.aff_talk("good"),
    ]
  return [Balance.aff_talk("plain")]   # 무난한 대화만 반복
