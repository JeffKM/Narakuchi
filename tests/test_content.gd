extends TestBase
## 콘텐츠/데이터 계약 회귀 테스트 (T23 재설계 — 구 test_phase2 의 콘텐츠 절).
## Cheki(조각·승급·헌사) · Dialogue(대화·선물·tier) · build_state · 컬렉션북/HUD 빌드 스모크.
## UI(ChoicePopup/StageCutin)는 디스플레이 의존이라 데이터 계약만 본다(컷인 통합은 test_cutin).
##
## 실행: godot --headless res://tests/test_content.tscn  (전수는 tools/run_tests.sh)

func _init() -> void:
  _suite = "콘텐츠 계약"


func run_suite() -> void:
  _test_cheki_shards()
  _test_milestone_pick()
  _test_milestone_miho()
  _test_dialogue_talk()
  _test_dialogue_gift()
  _test_dialogue_miho()
  _test_tier_affinity()
  _test_build_state()
  _test_first_cheki_nickname()
  _test_book_smoke()
  _test_miho_book_tab()
  _test_t21_expansion()
  _test_hud_attendance()
  _test_sound_binding()
  await _test_share_smoke()


# ── 체키 조각/승급 (T14 기반) ─────────────────────────────

func _test_cheki_shards() -> void:
  wipe()
  # 첫 획득 = 신규 일반
  var r1 := Cheki.grant(Events.OKJA, "mine")
  check(bool(r1["was_new"]), "grant 첫 획득 = was_new")
  check(r1["grade"] == Cheki.GRADE_COMMON, "grant 첫 획득 = 일반")
  check(Cheki.owned(Events.OKJA, "mine"), "획득 후 owned")

  # 중복 1회 = 조각 +1
  var r2 := Cheki.grant(Events.OKJA, "mine")
  check(not bool(r2["was_new"]), "중복은 was_new 아님")
  check(int(r2["shards"]) == 1, "중복 1회 → 조각 1 (got %d)" % int(r2["shards"]))

  # add_shards 로 2개 더 → 3 도달 → 나비 승급
  var r3 := Cheki.add_shards(Events.OKJA, "mine", 2)
  check(bool(r3["upgraded"]), "조각 3 도달 → 승급")
  check(r3["grade"] == Cheki.GRADE_BUTTERFLY, "승급 후 등급 = 나비")
  check(int(r3["shards"]) == 0, "승급 시 조각 리셋 0 (got %d)" % int(r3["shards"]))
  check(Cheki.grade(Events.OKJA, "mine") == Cheki.GRADE_BUTTERFLY, "저장된 등급 = 나비")

  # 이미 나비면 add_shards 무효
  var r4 := Cheki.add_shards(Events.OKJA, "mine", 5)
  check(r4.is_empty(), "나비 칸 add_shards → 빈 결과(무효)")

  # 미보유 칸 add_shards 무효
  var r5 := Cheki.add_shards(Events.OKJA, "kinder", 1)
  check(r5.is_empty(), "미보유 칸 add_shards → 빈 결과(무효)")


# ── 마일스톤 후보 선택 (T14) ──────────────────────────────

func _test_milestone_pick() -> void:
  wipe()
  # 후보 없음(아무것도 미보유) → 빈 결과
  var none := Cheki.grant_milestone_shards(1)
  check(none.is_empty(), "보유 일반 칸 없으면 마일스톤 보상 스킵")

  # 두 일반 칸: okja:mine(조각2), sion:mine(조각0). 승급에 가까운 mine(조각2) 우선.
  Cheki.grant(Events.OKJA, "mine")
  Cheki.add_shards(Events.OKJA, "mine", 2)        # okja:mine 조각 2
  Cheki.grant(Events.SION, "mine")                # sion:mine 조각 0
  var got := Cheki.grant_milestone_shards(1)
  check(not got.is_empty(), "보상 칸 선택됨")
  check(String(got["character"]) == Events.OKJA, "조각 최다 칸(okja) 우선 선택")
  check(bool(got["upgraded"]), "조각 2+1 → 3 → 승급")


# ── 마일스톤 보상 미호 파리티 (이슈 #5) ────────────────────
# 출석 마일스톤 나비 조각이 옥자·시온이뿐 아니라 미호 보유 일반 칸도 후보로 삼는지(전 캐릭터 전수).
# 미호를 메인으로 키워 미호 칸만 보유한 플레이어도 마일스톤 보상이 닿아야 한다(누락 방지).
func _test_milestone_miho() -> void:
  wipe()
  Cheki.grant("miho", "mine")           # miho:mine 일반(조각 0)
  Cheki.add_shards("miho", "mine", 2)   # 조각 2 → 승급 직전
  var got := Cheki.grant_milestone_shards(1)
  check(not got.is_empty(), "미호만 보유해도 마일스톤 보상 후보 있음")
  check(String(got["character"]) == "miho", "미호 보유 일반 칸이 마일스톤 후보(파리티)")
  check(bool(got["upgraded"]), "미호 조각 2+1 → 3 → 승급")


# ── 대화 토막 (T11) ───────────────────────────────────────

func _test_dialogue_talk() -> void:
  var g := Dialogue.pick_talk("okja", "guest", "지은")
  check(g.has("prompt") and g.has("choices"), "pick_talk 구조 {prompt,choices}")
  check((g["choices"] as Array).size() >= 2, "대화 선택지 2개 이상")
  var c0: Dictionary = g["choices"][0]
  check(c0.has("label") and c0.has("reply") and c0.has("tier") and c0.has("expr"),
    "선택지 필드 {label,reply,tier,expr}")

  # 단골(regular)은 아직 존댓말 풀, 편해진 사이(comfy)부터 반말 풀(guest 풀과 교집합 없어야 함)
  var guest_prompts := _talk_prompts("guest")
  var reg := Dialogue.pick_talk("okja", "regular", "지은")
  check(guest_prompts.has(String(reg["prompt"])), "단골(regular) = 아직 존댓말 풀에서 선택")
  var comfy := Dialogue.pick_talk("okja", "comfy", "지은")
  check(not guest_prompts.has(String(comfy["prompt"])), "편해진 사이(comfy) = 반말 풀에서 선택")

  # {nick} 치환 확인 — 토큰이 남아있으면 안 됨
  for _i in range(10):
    var t := Dialogue.pick_talk("okja", "guest", "지은")
    check(not String(t["prompt"]).contains("{nick}"), "{nick} 치환됨(prompt)")


func _talk_prompts(stage: String) -> Array:
  var out: Array = []
  for topic in GameData.talk().get(stage, []):
    out.append(String((topic as Dictionary)["prompt"]))
  return out


# ── 선물 선호표 (T11) ─────────────────────────────────────

func _test_dialogue_gift() -> void:
  var choices := Dialogue.gift_choices("okja", "guest", "지은")
  check(choices.size() == 4, "선물 4종 (got %d)" % choices.size())
  var tiers := {}
  for c in choices:
    check((c as Dictionary).has("tier") and (c as Dictionary).has("reply"), "선물 필드 {tier,reply}")
    tiers[String((c as Dictionary)["tier"])] = true
  check(tiers.has("match") and tiers.has("sion") and tiers.has("plain"),
    "선호 tier 3종(match/sion/plain) 존재")

  # icon 키가 팝업까지 전달돼야 함(없으면 텍스트만 fallback이지만, 현재 4종은 모두 슬롯 지정).
  for c in choices:
    check((c as Dictionary).has("icon"), "선물 선택지에 icon 키 전달")
  check(String((choices[0] as Dictionary)["icon"]) == "icon_gift_1", "첫 선물 아이콘 슬롯 = icon_gift_1")

  # 존댓말(손님·단골) vs 반말(편해진 사이~) 프롬프트가 달라야 함. 단골은 존댓말이라 손님과 동일.
  var pg := Dialogue.gift_prompt("okja", "guest")
  var p_regular := Dialogue.gift_prompt("okja", "regular")
  var p_comfy := Dialogue.gift_prompt("okja", "comfy")
  check(pg == p_regular, "선물 프롬프트: 단골(regular)은 존댓말이라 손님과 동일")
  check(pg != p_comfy, "선물 프롬프트 차등: 존댓말(손님) ≠ 반말(편해진 사이)")

  # reply 도 단계별 분기 — 존댓말(guest) ≠ 반말(comfy). 첫 선물 기준.
  var r_guest := String((Dialogue.gift_choices("okja", "guest", "지은")[0] as Dictionary)["reply"])
  var r_regular := String((Dialogue.gift_choices("okja", "regular", "지은")[0] as Dictionary)["reply"])
  var r_comfy := String((Dialogue.gift_choices("okja", "comfy", "지은")[0] as Dictionary)["reply"])
  check(r_guest == r_regular, "선물 반응: 단골(regular)은 존댓말이라 손님과 동일")
  check(r_guest != r_comfy, "선물 반응 차등: 존댓말(손님) ≠ 반말(편해진 사이)")


# ── 미호 대사 캐릭터별 일반화 (이슈 #4) ────────────────────
# 미호가 옥자 템플릿이 아닌 전용 대사를 쓰고, 말투 분기(존댓말/반말)가 캐릭터 독립인지 본다.

func _test_dialogue_miho() -> void:
  # 미호 drink = 시그니처 '미호 스파클링' 보이스(옥자 '나락트루바'와 다름)
  var miho_drink := Dialogue.line("miho", "drink", "guest", "지은")
  check(miho_drink.contains("스파클링"), "미호 drink = 미호 스파클링 보이스 (got: %s)" % miho_drink)

  # 미호 enter = 옥자 풀과 분리된 전용 대사
  var okja_enter := _ticker_pool("okja", "enter", "guest")
  var miho_enter := Dialogue.line("miho", "enter", "guest", "지은")
  check(not okja_enter.has(miho_enter), "미호 enter = 옥자 풀과 분리된 전용 대사")

  # 말투 분기: 미호 guest(존댓말) vs comfy(반말) 풀이 분리 — stage 로만 분기(옥자 상태 누설 없음)
  var miho_guest_enter := _ticker_pool("miho", "enter", "guest")
  var miho_casual := Dialogue.line("miho", "enter", "comfy", "지은")
  check(not miho_guest_enter.has(miho_casual), "미호 comfy(반말) = 미호 존댓말 풀과 분리(말투 단일 출처)")

  # 미호 대화 토막 = 미호 전용(옥자 guest 풀과 교집합 없음)
  var miho_talk := Dialogue.pick_talk("miho", "guest", "지은")
  check((miho_talk["choices"] as Array).size() >= 2, "미호 대화 선택지 2+")
  check(not _talk_prompts("guest").has(String(miho_talk["prompt"])), "미호 대화 = 옥자 풀과 분리")

  # 미호 선물 = 4종, reply 는 미호 톤(옥자와 다름)
  var miho_gifts := Dialogue.gift_choices("miho", "guest", "지은")
  check(miho_gifts.size() == 4, "미호 선물 4종 (got %d)" % miho_gifts.size())
  var okja_g0 := String((Dialogue.gift_choices("okja", "guest", "지은")[0] as Dictionary)["reply"])
  var miho_g0 := String((miho_gifts[0] as Dictionary)["reply"])
  check(okja_g0 != miho_g0, "미호 선물 반응 = 옥자와 다른 전용 톤")

  # 미호 단계 컷인 = 전용(반말 해금), {nick} 치환
  var cut := Dialogue.cutin("miho", "comfy", "지은")
  check(not (cut.get("lines", []) as Array).is_empty(), "미호 comfy 컷인 lines 존재")
  check(String(cut.get("badge", "")).contains("반말"), "미호 반말 해금 배지")
  check(String(cut.get("reveal", "")).contains("반말"), "미호 반말 reveal")
  for ln in cut.get("lines", []):
    check(not String((ln as Dictionary)["text"]).contains("{nick}"), "미호 컷인 {nick} 치환")

  # 폴백: 미정의 dialogue_key → 옥자 풀로 폴백(빈 문자열 아님 = 안전)
  check(Dialogue.line("zzz_none", "enter", "guest", "지은") != "", "미정의 키 → 옥자 폴백(무손상)")


## ticker 풀 한 묶음을 {nick} 치환해 배열로(미호/옥자 풀 비교용).
func _ticker_pool(key: String, situation: String, stage_key: String) -> Array:
  var c: Dictionary = GameData.ticker().get(key, {})
  var pools: Dictionary = c.get(situation, {})
  var out: Array = []
  for ln in pools.get(stage_key, []):
    out.append(String(ln).replace("{nick}", "지은"))
  return out


# ── tier → 호감도 매핑 (Balance 게이트웨이 검증) ─────────────
# tier→수치는 Balance.aff_talk/aff_gift (data/balance.json 단일 출처) — 서열 일관성을 본다.

func _test_tier_affinity() -> void:
  check(Balance.aff_talk("good") > Balance.aff_talk("plain"), "대화 good > plain 호감")
  check(Balance.aff_gift("sion") > Balance.aff_gift("match"), "선물 sion > match 호감")
  check(Balance.aff_gift("match") > Balance.aff_gift("plain"), "선물 match > plain 호감")
  # 반말 전환(편해진 사이, REL_COMFY) 경계 로직 — 시드 매직넘버가 아니라 임계값에서 파생.
  # comfy 직전(−가장 작은 대화)은 아직 단골, 거기에 가장 작은 대화 한 번이면 comfy 도달.
  var edge := Balance.REL_COMFY - Balance.aff_talk("plain")
  check(Balance.relationship_stage(edge) == "regular", "comfy 직전(−plain)은 아직 단골(regular)")
  check(Balance.relationship_stage(edge + Balance.aff_talk("plain")) == "comfy",
    "가장 작은 대화 한 번으로 반말 전환(comfy) 도달")


# ── 상태 빌더 (T23 — 테스트/개발 프리셋 단일 출처) ──────────
# build_state 가 default_save 위에 의도한 키만 덮는지, 단계 지정이 임계값으로 매핑되는지 확인.

func _test_build_state() -> void:
  # 빈 opts → 기본 세이브와 동치
  var base := SaveManager.build_state({})
  check(base["okja"]["affinity_total"] == 0 and base["flags"]["announced_stage"] == "guest",
    "build_state({}) = 기본 세이브")

  # 단계 지정 → 해당 임계값으로 매핑(매직넘버 없이 의미 단위)
  var reg := SaveManager.build_state({"okja_stage": "regular"})
  check(int(reg["okja"]["affinity_total"]) == Balance.REL_REGULAR,
    "okja_stage=regular → REL_REGULAR")
  check(Balance.relationship_stage(int(reg["okja"]["affinity_total"])) == "regular",
    "okja_stage=regular 상태가 실제 regular 로 판정")

  # 정확값(okja_affinity) 이 단계보다 우선
  var exact := SaveManager.build_state({"okja_stage": "regular", "okja_affinity": Balance.REL_COMFY - 1})
  check(int(exact["okja"]["affinity_total"]) == Balance.REL_COMFY - 1,
    "okja_affinity 가 okja_stage 보다 우선")

  # 지정 안 한 키는 기본값 보존
  var named := SaveManager.build_state({"nickname": "지은", "onboarded": true})
  check(String(named["player"]["nickname"]) == "지은" and bool(named["flags"]["onboarded"]),
    "nickname/onboarded 반영")
  check(int(named["okja"]["affinity_total"]) == 0, "미지정 키(호감도)는 기본값 보존")


# ── 첫 체키 닉 스냅샷 (T06b 온보딩→첫 체키 무결성) ──────────
# 온보딩이 닉을 저장한 "직후" 첫 체키를 grant 하므로, grant 는 그 닉을 표지 헌사로
# 박아야 한다(cheki.gd:91). 순서가 뒤집히면 헌사가 "손님"으로 비어 무결성이 깨진다.
func _test_first_cheki_nickname() -> void:
  wipe()
  SaveManager.set_value("player.nickname", "지은")
  Cheki.grant(Events.OKJA, Events.FIRST_GIFT_EVENT)  # 첫 지뢰계 체키
  var rec := Cheki.record(Events.OKJA, Events.FIRST_GIFT_EVENT)
  check(String(rec["nickname"]) == "지은", "첫 체키 헌사 = 획득 시점 닉 스냅샷")

  # 헌사는 첫 획득 시점 고정 — 이후 닉이 바뀌고 중복 획득(나비 조각)해도 안 변한다.
  SaveManager.set_value("player.nickname", "다른닉")
  Cheki.grant(Events.OKJA, Events.FIRST_GIFT_EVENT)  # 중복 → 조각, 헌사 불변
  var rec2 := Cheki.record(Events.OKJA, Events.FIRST_GIFT_EVENT)
  check(String(rec2["nickname"]) == "지은", "헌사는 첫 획득 닉으로 고정(이후 닉 변경 무관)")


# ── 컬렉션북 인스턴스화 스모크 (출석 스트립 빌드 포함) ──────────
## CollectionBook._ready 가 출석 스트립까지 크래시 없이 빌드되는지 확인(런타임 위로 에러 시 콘솔에 SCRIPT ERROR).
## streak 별로 next>0(핍+남은일) / next==0(다 모음) 두 분기를 모두 태운다.

func _test_book_smoke() -> void:
  wipe()
  Cheki.grant(Events.OKJA, "mine")

  for streak in [1, 9]:
    SaveManager.set_value("attendance.streak", streak)
    var book := CollectionBook.new()
    add_child(book)            # _ready() 동기 실행 → 빌드 크래시 시 콘솔 에러
    var built := is_instance_valid(book) and book.get_child_count() > 0
    check(built, "컬렉션북 빌드 OK (streak=%d)" % streak)
    book.free()

  # 책이 열린 채 체키가 지급되면(디버그 키 4 — 리빌이 책 위에 뜸) refresh() 로 즉시 반영돼야 함.
  wipe()
  var ev := Cheki.pick_today(Events.OKJA)
  var b2 := CollectionBook.new()
  add_child(b2)                # 미보유 상태로 슬롯 빌드
  Cheki.grant(Events.OKJA, ev) # 책 열린 채 지급(stale 발생 지점)
  b2.refresh()                 # cafe._on_reveal_closed 가 호출하는 경로
  var owned_after := false
  for s in b2._slots:
    if s.character == Events.OKJA and s.event == ev and s.is_owned():
      owned_after = true
  check(owned_after, "책 열린 채 지급 → refresh() 로 '%s' 칸 반영" % ev)
  b2.free()


# ── 미호 컬렉션북 탭 잠금 해제 (이슈 #5) ───────────────────
## 미호 탭이 실루엣 → 잠금 해제되어 실제 그리드(지뢰계)를 보여주고, 미보유 칸은 예고형 빈칸,
## 보유 시 owned 칸으로 렌더되는지. 바나·멜은 여전히 잠겨 예고로 남는다(옥자·시온이 회귀는 _test_book_smoke).
func _test_miho_book_tab() -> void:
  wipe()
  # TABS 계약: 미호 잠금 해제 + 바나·멜은 잠금 유지.
  var locks := {}
  for t in CollectionBook.TABS:
    locks[String(t["id"])] = bool(t["locked"])
  check(locks.get("miho", true) == false, "미호 탭 잠금 해제(locked=false)")
  check(bool(locks.get("bana", false)) and bool(locks.get("mel", false)),
    "바나·멜은 여전히 잠금(예고로 유지)")

  var miho_i := -1
  for i in CollectionBook.TABS.size():
    if String(CollectionBook.TABS[i]["id"]) == "miho":
      miho_i = i
  check(miho_i >= 0, "미호 탭 존재")

  # 미보유 상태로 탭 전환 → 미호 참여 이벤트만(비대칭 그리드 정상), 한정 슬롯 없음.
  var book := CollectionBook.new()
  add_child(book)  # 기본 active=옥자
  book._on_tab(miho_i)
  check(book._active_char == "miho", "미호 탭 전환 → active_char=miho")
  var miho_evs := Events.events_for("miho")
  check(book._slots.size() == miho_evs.size(),
    "미호 그리드 = 참여 이벤트 %d칸(한정 슬롯 없음, got %d)" % [miho_evs.size(), book._slots.size()])
  var mine_slot: ChekiSlot = null
  for s in book._slots:
    if s.event == "mine":
      mine_slot = s
  check(mine_slot != null and not mine_slot.is_owned(), "미보유 미호 지뢰계 = 빈칸")
  check(mine_slot != null and mine_slot.state == ChekiSlot.STATE_EMPTY,
    "미호 지뢰계 미보유 = empty(아트 준비됨 = 예고형 빈칸)")
  book.free()

  # 보유 시 owned 칸으로 렌더(미호 체키 grant → 새 책에서 확인).
  Cheki.grant("miho", "mine")
  var b2 := CollectionBook.new()
  add_child(b2)
  b2._on_tab(miho_i)
  var owned := false
  for s in b2._slots:
    if s.event == "mine" and s.is_owned():
      owned = true
  check(owned, "미호 지뢰계 체키 보유 → owned 칸")
  b2.free()


# ── 잠긴 멤버 + 한정 슬롯 + 확장 슬라이드 (T21) ────────────
## 잠긴 탭 활성화 → 확장 슬라이드 발화, 옥자 그리드 끝 "한정" 슬롯 존재·탭 비모달.

func _test_t21_expansion() -> void:
  wipe()
  var book := CollectionBook.new()
  add_child(book)  # _ready 동기 빌드(okja 그리드 = 이벤트 + 한정 슬롯)

  # 옥자 그리드 끝에 한정 슬롯이 1칸 들어갔는지(이벤트 수 + 1).
  var limited_count := 0
  for s in book._slots:
    if s.is_limited():
      limited_count += 1
  check(limited_count == 1, "옥자 그리드에 한정 슬롯 1칸 (got %d)" % limited_count)
  var expected := Events.events_for(Events.OKJA).size() + 1
  check(book._slots.size() == expected,
    "옥자 슬롯 = 이벤트 %d + 한정 1 = %d (got %d)" % [expected - 1, expected, book._slots.size()])

  # 첫 잠긴 탭(바나/멜) 활성화 → 확장 슬라이드 발화. 탭 순서 변경에 견디게 동적 탐색. (→ 이슈 #5 재배치)
  var locked_i := -1
  for i in CollectionBook.TABS.size():
    if bool(CollectionBook.TABS[i]["locked"]):
      locked_i = i
      break
  check(locked_i >= 0, "잠긴 탭이 최소 1개 존재(바나/멜)")
  check(book._slide == null, "초기엔 슬라이드 없음")
  book._on_tab(locked_i)
  check(book._slide != null, "잠긴 탭 활성화 → 확장 슬라이드 발화")
  check(book._slide is ExpansionSlide, "슬라이드 타입 = ExpansionSlide")
  # 슬라이드 떠 있으면 셸 입력이 슬라이드로 위임됨(CANCEL 닫기 경로) — 크래시 없이 호출되는지.
  book.handle_shell_action(&"cancel")
  check(true, "슬라이드 열린 채 CANCEL 위임 크래시 0")
  book.free()

  # 한정 슬롯 단독 빌드 — STATE_LIMITED 렌더 + 비보유.
  var slot := ChekiSlot.new()
  slot.setup_limited()
  add_child(slot)
  check(slot.is_limited() and not slot.is_owned(), "한정 슬롯: is_limited & 비보유")
  check(slot.state == ChekiSlot.STATE_LIMITED, "한정 슬롯 상태 = limited")
  slot.free()


# ── 공유 합성/저장 스모크 (② 부분 방어선) ──────────────────
## 공유 이미지 합성(SubViewport)→네이티브 저장(user://shares PNG) 경로가 크래시 없이 도는지.
## 웹 분기(JavaScriptBridge Web Share/다운로드)는 헤드리스 검증 불가 → 실기기 디바이스 세션 몫.
## 헤드리스에서 렌더가 비는 경우(더미 렌더러)엔 파일 단언을 건너뛰고 무크래시만 본다(거짓 실패 방지).
func _test_share_smoke() -> void:
  wipe()
  SaveManager.set_value("player.nickname", "지은")
  var dir := "user://shares"
  var card := ShareCard.new()
  card.setup(Events.OKJA, Events.FIRST_GIFT_EVENT, false, "지은", Clock.now())
  add_child(card)                       # _ready → _compose_async(코루틴) 시작
  # 합성 코루틴(프레임 렌더 대기)이 끝나도록 몇 프레임 흘린다.
  for _i in range(6):
    await get_tree().process_frame
  check(is_instance_valid(card), "ShareCard 합성까지 크래시 0")

  if card._image != null:
    card._save()                        # 비웹 경로: user://shares/*.png 저장
    var found := false
    var d := DirAccess.open(dir)
    if d:
      for f in d.get_files():
        if f.ends_with(".png"):
          found = true
          d.remove(f)                   # 테스트 산출물 정리
      DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
    check(found, "공유 합성 이미지 → user://shares PNG 저장")
  else:
    print("    · (헤드리스 렌더 없음 — 공유 PNG 저장은 실기기/로컬 GUI 에서 확인)")
  card.free()


## HUD 출석 라인이 빌드되고 streak 별로 올바른 문구를 만드는지(빌드 크래시 0 + 텍스트 분기).
func _test_hud_attendance() -> void:
  wipe()
  var hud := Hud.new()
  add_child(hud)              # _ready() 동기 실행

  SaveManager.set_value("attendance.streak", 1)
  hud.refresh()
  # streak 1 → 3일 마일스톤까지 2일 남음
  check(hud._attend.text.contains("출석 1일") and hud._attend.text.contains("2일"),
    "HUD 출석 라인: streak 1 → 다음 보상까지 2일 (got '%s')" % hud._attend.text)

  SaveManager.set_value("attendance.streak", 9)
  hud.refresh()
  check(hud._attend.text.contains("다 모음"),
    "HUD 출석 라인: streak 9 → 보상 다 모음 (got '%s')" % hud._attend.text)
  hud.free()


# ── 효과음 바인딩 단일 출처 가드 (→ ADR 0004) ─────────────
## 코드의 Sfx.event(&"id") 집합 == data/sound.json events 키 집합(양방향) + 바인딩 파일 존재.
## 고아(코드 없는 이벤트)·누락(json 없는 호출)·죽은 파일을 막아 "스튜디오에서 지웠더니 무음" 류 표류를 잡는다.
func _test_sound_binding() -> void:
  var snd := GameData.sound()
  var events: Dictionary = snd.get("events", {})
  var defaults: Dictionary = snd.get("defaults", {})
  check(not events.is_empty(), "사운드: sound.json events 로드됨")

  # 1) 코드에서 쓰는 이벤트 id 수집 (scripts/ 전 .gd, Sfx.event 라인의 &"…" 리터럴 — 삼항 포함 복수 추출)
  var used := {}
  var re := RegEx.new()
  re.compile('&"([a-z_]+)"')
  for path in _gd_files("res://scripts"):
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
      continue
    while not f.eof_reached():
      var line := f.get_line()
      if line.find("Sfx.event") == -1:
        continue
      for m in re.search_all(line):
        used[m.get_string(1)] = true
    f.close()
  check(not used.is_empty(), "사운드: 코드에서 Sfx.event 호출 수집됨")

  # 2) 양방향 일치
  for id in used:
    check(events.has(id), "사운드: 코드 이벤트 '%s' 가 sound.json 에 있음(누락 아님)" % id)
  for id in events:
    check(used.has(id), "사운드: json 이벤트 '%s' 가 코드에서 쓰임(고아 아님)" % id)

  # 3) 바인딩 파일 존재 (events[id].file → 없으면 defaults[cat])
  for id in events:
    var e: Dictionary = events[id]
    var file := String(e.get("file", ""))
    if file.is_empty():
      file = String(defaults.get(String(e.get("cat", "")), ""))
    check(not file.is_empty(), "사운드: '%s' 해소 파일 있음(직접 또는 cat 기본)" % id)
    if not file.is_empty():
      check(ResourceLoader.exists("res://assets/audio/" + file),
        "사운드: '%s' 바인딩 파일 존재(%s)" % [id, file])


## res://scripts 하위 .gd 전부(재귀) — 사운드 바인딩 가드용 소스 스캔.
func _gd_files(dir_path: String) -> Array:
  var out: Array = []
  var d := DirAccess.open(dir_path)
  if d == null:
    return out
  d.list_dir_begin()
  var name := d.get_next()
  while name != "":
    var full := dir_path + "/" + name
    if d.current_is_dir():
      if not name.begins_with("."):
        out.append_array(_gd_files(full))
    elif name.ends_with(".gd"):
      out.append(full)
    name = d.get_next()
  d.list_dir_end()
  return out
