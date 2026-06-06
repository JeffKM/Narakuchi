extends Node
## Phase 2(T11 대화·선물·반말 컷인 / T14 마일스톤) 헤드리스 회귀 테스트.
##
## 실행: godot --headless res://tests/test_phase2.tscn
## (autoload SaveManager 를 쓰므로 --script 가 아니라 씬으로 띄운다.)
## 순수 로직(Cheki·Dialogue·Meters·Balance)을 SaveManager(autoload) 위에서 검증한다.
## UI(ChoicePopup/StageCutin/ChekiReveal)는 디스플레이가 필요해 여기선 데이터 계약만 본다.

var _pass := 0
var _fail := 0


func _ready() -> void:
  print("── Phase 2 테스트 시작 ──")
  _test_cheki_shards()
  _test_milestone_pick()
  _test_dialogue_talk()
  _test_dialogue_gift()
  _test_tier_affinity()
  _test_meters_milestone()
  _test_attendance_status()
  _test_book_smoke()
  _test_hud_attendance()
  print("── 결과: %d 통과 / %d 실패 ──" % [_pass, _fail])
  SaveManager.wipe()  # 테스트가 user:// 세이브를 오염시키지 않게 정리(실제 플레이 보호)
  get_tree().quit(1 if _fail > 0 else 0)


# ── 체키 조각/승급 (T14 기반) ─────────────────────────────

func _test_cheki_shards() -> void:
  _wipe()
  # 첫 획득 = 신규 일반
  var r1 := Cheki.grant(Events.OKJA, "mine")
  _check(bool(r1["was_new"]), "grant 첫 획득 = was_new")
  _check(r1["grade"] == Cheki.GRADE_COMMON, "grant 첫 획득 = 일반")
  _check(Cheki.owned(Events.OKJA, "mine"), "획득 후 owned")

  # 중복 1회 = 조각 +1
  var r2 := Cheki.grant(Events.OKJA, "mine")
  _check(not bool(r2["was_new"]), "중복은 was_new 아님")
  _check(int(r2["shards"]) == 1, "중복 1회 → 조각 1 (got %d)" % int(r2["shards"]))

  # add_shards 로 2개 더 → 3 도달 → 나비 승급
  var r3 := Cheki.add_shards(Events.OKJA, "mine", 2)
  _check(bool(r3["upgraded"]), "조각 3 도달 → 승급")
  _check(r3["grade"] == Cheki.GRADE_BUTTERFLY, "승급 후 등급 = 나비")
  _check(int(r3["shards"]) == 0, "승급 시 조각 리셋 0 (got %d)" % int(r3["shards"]))
  _check(Cheki.grade(Events.OKJA, "mine") == Cheki.GRADE_BUTTERFLY, "저장된 등급 = 나비")

  # 이미 나비면 add_shards 무효
  var r4 := Cheki.add_shards(Events.OKJA, "mine", 5)
  _check(r4.is_empty(), "나비 칸 add_shards → 빈 결과(무효)")

  # 미보유 칸 add_shards 무효
  var r5 := Cheki.add_shards(Events.OKJA, "kinder", 1)
  _check(r5.is_empty(), "미보유 칸 add_shards → 빈 결과(무효)")


# ── 마일스톤 후보 선택 (T14) ──────────────────────────────

func _test_milestone_pick() -> void:
  _wipe()
  # 후보 없음(아무것도 미보유) → 빈 결과
  var none := Cheki.grant_milestone_shards(1)
  _check(none.is_empty(), "보유 일반 칸 없으면 마일스톤 보상 스킵")

  # 두 일반 칸: okja:mine(조각2), sion:mine(조각0). 승급에 가까운 mine(조각2) 우선.
  Cheki.grant(Events.OKJA, "mine")
  Cheki.add_shards(Events.OKJA, "mine", 2)        # okja:mine 조각 2
  Cheki.grant(Events.SION, "mine")                # sion:mine 조각 0
  var got := Cheki.grant_milestone_shards(1)
  _check(not got.is_empty(), "보상 칸 선택됨")
  _check(String(got["character"]) == Events.OKJA, "조각 최다 칸(okja) 우선 선택")
  _check(bool(got["upgraded"]), "조각 2+1 → 3 → 승급")


# ── 대화 토막 (T11) ───────────────────────────────────────

func _test_dialogue_talk() -> void:
  var g := Dialogue.pick_talk("guest", "지은")
  _check(g.has("prompt") and g.has("choices"), "pick_talk 구조 {prompt,choices}")
  _check((g["choices"] as Array).size() >= 2, "대화 선택지 2개 이상")
  var c0: Dictionary = g["choices"][0]
  _check(c0.has("label") and c0.has("reply") and c0.has("tier") and c0.has("expr"),
    "선택지 필드 {label,reply,tier,expr}")

  # 단골(regular)은 아직 존댓말 풀, 편해진 사이(comfy)부터 반말 풀(guest 풀과 교집합 없어야 함)
  var guest_prompts := _talk_prompts("guest")
  var reg := Dialogue.pick_talk("regular", "지은")
  _check(guest_prompts.has(String(reg["prompt"])), "단골(regular) = 아직 존댓말 풀에서 선택")
  var comfy := Dialogue.pick_talk("comfy", "지은")
  _check(not guest_prompts.has(String(comfy["prompt"])), "편해진 사이(comfy) = 반말 풀에서 선택")

  # {nick} 치환 확인 — 토큰이 남아있으면 안 됨
  for _i in range(10):
    var t := Dialogue.pick_talk("guest", "지은")
    _check(not String(t["prompt"]).contains("{nick}"), "{nick} 치환됨(prompt)")


func _talk_prompts(stage: String) -> Array:
  var out: Array = []
  for topic in GameData.talk().get(stage, []):
    out.append(String((topic as Dictionary)["prompt"]))
  return out


# ── 선물 선호표 (T11) ─────────────────────────────────────

func _test_dialogue_gift() -> void:
  var choices := Dialogue.gift_choices("guest", "지은")
  _check(choices.size() == 4, "선물 4종 (got %d)" % choices.size())
  var tiers := {}
  for c in choices:
    _check((c as Dictionary).has("tier") and (c as Dictionary).has("reply"), "선물 필드 {tier,reply}")
    tiers[String((c as Dictionary)["tier"])] = true
  _check(tiers.has("match") and tiers.has("sion") and tiers.has("plain"),
    "선호 tier 3종(match/sion/plain) 존재")

  # icon 키가 팝업까지 전달돼야 함(없으면 텍스트만 fallback이지만, 현재 4종은 모두 슬롯 지정).
  for c in choices:
    _check((c as Dictionary).has("icon"), "선물 선택지에 icon 키 전달")
  _check(String((choices[0] as Dictionary)["icon"]) == "icon_gift_1", "첫 선물 아이콘 슬롯 = icon_gift_1")

  # 존댓말(손님·단골) vs 반말(편해진 사이~) 프롬프트가 달라야 함. 단골은 존댓말이라 손님과 동일.
  var pg := Dialogue.gift_prompt("guest")
  var p_regular := Dialogue.gift_prompt("regular")
  var p_comfy := Dialogue.gift_prompt("comfy")
  _check(pg == p_regular, "선물 프롬프트: 단골(regular)은 존댓말이라 손님과 동일")
  _check(pg != p_comfy, "선물 프롬프트 차등: 존댓말(손님) ≠ 반말(편해진 사이)")

  # reply 도 단계별 분기 — 존댓말(guest) ≠ 반말(comfy). 첫 선물 기준.
  var r_guest := String((Dialogue.gift_choices("guest", "지은")[0] as Dictionary)["reply"])
  var r_regular := String((Dialogue.gift_choices("regular", "지은")[0] as Dictionary)["reply"])
  var r_comfy := String((Dialogue.gift_choices("comfy", "지은")[0] as Dictionary)["reply"])
  _check(r_guest == r_regular, "선물 반응: 단골(regular)은 존댓말이라 손님과 동일")
  _check(r_guest != r_comfy, "선물 반응 차등: 존댓말(손님) ≠ 반말(편해진 사이)")


# ── tier → 호감도 매핑 (Balance 게이트웨이 검증) ─────────────
# tier→수치는 Balance.aff_talk/aff_gift (data/balance.json 단일 출처) — 서열 일관성을 본다.

func _test_tier_affinity() -> void:
  _check(Balance.aff_talk("good") > Balance.aff_talk("plain"), "대화 good > plain 호감")
  _check(Balance.aff_gift("sion") > Balance.aff_gift("match"), "선물 sion > match 호감")
  _check(Balance.aff_gift("match") > Balance.aff_gift("plain"), "선물 match > plain 호감")
  # 데모 시드가 '반말 전환(편해진 사이, 600)' 직전인지 — 첫 교감 한 번으로 넘어가야 함
  var gap := Balance.REL_COMFY - Balance.DEMO_SEED_AFFINITY
  _check(gap > 0 and gap <= Balance.aff_talk("plain"),
    "데모 시드가 가장 작은 액션으로도 반말 전환(편해진 사이) 도달(gap=%d ≤ %d)" % [gap, Balance.aff_talk("plain")])
  # 단골(200)은 시드(595)가 이미 넘긴 상태여야 함
  _check(Balance.DEMO_SEED_AFFINITY >= Balance.REL_REGULAR, "데모 시드는 단골(200) 이상에서 시작")


# ── 미터 출석 마일스톤 (T14) ──────────────────────────────

func _test_meters_milestone() -> void:
  # 3일째 도달: 어제 방문 + 누적 streak 2 → 오늘 begin_session 으로 3 → 마일스톤
  _wipe()
  Cheki.grant(Events.OKJA, "mine")  # 보상 적립할 일반 칸 확보
  var yesterday := _yesterday_str()
  SaveManager.set_value("attendance.last_date", yesterday)
  SaveManager.set_value("attendance.streak", 2)

  var m := Meters.new()
  m.begin_session()
  _check(not m.pending_milestone.is_empty(), "3일 연속 → 마일스톤 발생")
  if not m.pending_milestone.is_empty():
    _check(int(m.pending_milestone["streak"]) == 3, "마일스톤 streak == 3")
    _check(m.pending_milestone.has("reward"), "마일스톤 reward 동봉")
  m.free()

  # 비마일스톤 날(2일째): 어제 방문 + streak 1 → 오늘 2 → 마일스톤 아님
  _wipe()
  Cheki.grant(Events.OKJA, "mine")
  SaveManager.set_value("attendance.last_date", _yesterday_str())
  SaveManager.set_value("attendance.streak", 1)
  var m2 := Meters.new()
  m2.begin_session()
  _check(m2.pending_milestone.is_empty(), "2일째는 마일스톤 아님")
  m2.free()


# ── 출석 진행 표시 (T14 컬렉션북/HUD) ─────────────────────

func _test_attendance_status() -> void:
  _wipe()
  # streak 1 → 다음 마일스톤 3, 2일 남음
  SaveManager.set_value("attendance.streak", 1)
  var s1 := Meters.attendance_status()
  _check(int(s1["next"]) == 3, "streak 1 → 다음 마일스톤 3 (got %d)" % int(s1["next"]))
  _check(int(s1["remaining"]) == 2, "streak 1 → 2일 남음 (got %d)" % int(s1["remaining"]))

  # streak 3(3일 받은 직후) → 다음은 7, 4일 남음
  SaveManager.set_value("attendance.streak", 3)
  var s3 := Meters.attendance_status()
  _check(int(s3["next"]) == 7, "streak 3 → 다음 마일스톤 7")
  _check(int(s3["remaining"]) == 4, "streak 3 → 7일까지 4일 남음 (got %d)" % int(s3["remaining"]))

  # streak 7+ → 더 이상 마일스톤 없음(next 0)
  SaveManager.set_value("attendance.streak", 9)
  var s9 := Meters.attendance_status()
  _check(int(s9["next"]) == 0, "streak 9 → 남은 마일스톤 없음(next 0)")
  _check(int(s9["streak"]) == 9, "streak 값 그대로 노출")


func _yesterday_str() -> String:
  var now := int(Time.get_unix_time_from_system())
  return Time.get_datetime_string_from_unix_time(now - 86400).split("T")[0]


# ── 컬렉션북 인스턴스화 스모크 (출석 스트립 빌드 포함) ──────────
## CollectionBook._ready 가 출석 스트립까지 크래시 없이 빌드되는지 확인(런타임 위로 에러 시 콘솔에 SCRIPT ERROR).
## streak 별로 next>0(핍+남은일) / next==0(다 모음) 두 분기를 모두 태운다.

func _test_book_smoke() -> void:
  _wipe()
  Cheki.grant(Events.OKJA, "mine")

  for streak in [1, 9]:
    SaveManager.set_value("attendance.streak", streak)
    var book := CollectionBook.new()
    add_child(book)            # _ready() 동기 실행 → 빌드 크래시 시 콘솔 에러
    var built := is_instance_valid(book) and book.get_child_count() > 0
    _check(built, "컬렉션북 빌드 OK (streak=%d)" % streak)
    book.free()

  # 책이 열린 채 체키가 지급되면(디버그 키 4 — 리빌이 책 위에 뜸) refresh() 로 즉시 반영돼야 함.
  _wipe()
  var ev := Cheki.pick_today(Events.OKJA)
  var b2 := CollectionBook.new()
  add_child(b2)                # 미보유 상태로 슬롯 빌드
  Cheki.grant(Events.OKJA, ev) # 책 열린 채 지급(stale 발생 지점)
  b2.refresh()                 # cafe._on_reveal_closed 가 호출하는 경로
  var owned_after := false
  for s in b2._slots:
    if s.character == Events.OKJA and s.event == ev and s.is_owned():
      owned_after = true
  _check(owned_after, "책 열린 채 지급 → refresh() 로 '%s' 칸 반영" % ev)
  b2.free()


## HUD 출석 라인이 빌드되고 streak 별로 올바른 문구를 만드는지(빌드 크래시 0 + 텍스트 분기).
func _test_hud_attendance() -> void:
  _wipe()
  var hud := Hud.new()
  add_child(hud)              # _ready() 동기 실행

  SaveManager.set_value("attendance.streak", 1)
  hud.refresh()
  # streak 1 → 3일 마일스톤까지 2일 남음
  _check(hud._attend.text.contains("출석 1일") and hud._attend.text.contains("2일"),
    "HUD 출석 라인: streak 1 → 다음 보상까지 2일 (got '%s')" % hud._attend.text)

  SaveManager.set_value("attendance.streak", 9)
  hud.refresh()
  _check(hud._attend.text.contains("다 모음"),
    "HUD 출석 라인: streak 9 → 보상 다 모음 (got '%s')" % hud._attend.text)
  hud.free()


# ── 헬퍼 ─────────────────────────────────────────────────

## 세이브를 기본값으로 비운다(테스트 격리).
func _wipe() -> void:
  SaveManager.data = SaveManager.default_save()


func _check(cond: bool, name: String) -> void:
  if cond:
    _pass += 1
    print("  ✓ ", name)
  else:
    _fail += 1
    print("  ✗ 실패: ", name)
