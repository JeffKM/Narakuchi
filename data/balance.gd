class_name Balance
extends RefCounted
## 나라쿠치 밸런스 상수 — PRD §4.5 (v1 시작값, 플레이테스트로 조정)
## ⚠️ 게임 수치는 전부 여기 한 곳에서만 관리한다. 다른 스크립트에서 하드코딩 금지.
## 사용 예: Balance.STAMINA_MAX, Balance.GAUGE_OKJA
##
## 설계 의도: 세션 1~3분 · 체키는 희소(약 1주 1장) · 첫 체키 즉시 · 반말 전환은 장기 보상.

# ── 스태미나 (세션 길이) ───────────────────────
const STAMINA_MAX := 30          # 최대치 (매일 접속 시 풀 충전)
const STAMINA_PER_ACTION := 5    # 액션당 소모 → 하루 6액션 (옥자/시온이 공유, 터치 무료)

# ── 호감도 획득 (액션별) ───────────────────────
# ⚠️ 수치는 data/balance.json 의 "affinity" 에서 온다(content_studio '밸런스' 탭 편집). Balance 는 단일 게이트웨이.
#    talk/gift 는 tier→수치 매핑(aff_talk/aff_gift), 나머지는 액션별 고정 수치(aff). 폴백 기본값은 PRD §4.5 v1.
const _AFF_DEFAULT := {
  "drink": 12, "drink_favorite": 18, "cheki": 10,
  "touch": 2, "touch_session_cap": 10,
  "sion": 10, "sion_favorite": 15,
}
const _AFF_TALK_DEFAULT := {"good": 15, "plain": 8}
const _AFF_GIFT_DEFAULT := {"match": 20, "sion": 25, "plain": 10}

# ── 게이지 → 체키 ─────────────────────────────
const GAUGE_OKJA := 300          # 옥자 호감도 게이지 풀 = 체키 1장
const GAUGE_SION := 200          # 시온이 게이지 풀 = 체키 1장

# ── 관계 단계 (누적 옥자 호감도) ────────────────
const REL_GUEST := 0             # 손님: 존댓말 + "{닉}님"
const REL_REGULAR := 200         # 단골: 아직 존댓말, 살가운 인사("자주 오시네요") (1차 상승)
const REL_COMFY := 600           # 편해진 사이: 반말 전환(존댓말 해제 컷인) (2차 상승)
const REL_CLOSE := 2000          # 마음 연 사이: 속내·애칭·특별 대화 (3차 상승, ~6주)

# 데모 시연 세이브 시드값 — 첫 세션 한 번의 교감으로 '반말 전환 컷인'(600)이 터지도록 직전까지 채움
# (가장 작은 액션 AFF_TALK_PLAIN=8 만으로도 600 을 넘기게 595). 단골(200)은 시드가 이미 넘긴 상태.
const DEMO_SEED_AFFINITY := 595

# ── 나비 / 출석 / 코인 / 기분 ───────────────────
const BUTTERFLY_SHARDS_NEEDED := 3   # 나비 승급에 필요한 조각 (같은 의상 중복 1 = 조각 +1)
const ATTENDANCE_MILESTONE_3 := 3    # 연속출석 3일 마일스톤
const ATTENDANCE_MILESTONE_7 := 7    # 연속출석 7일 마일스톤 (+ 나비 조각)
const ATTENDANCE_REWARD_SHARDS_3 := 1  # 3일 마일스톤 보상 = 나비 조각 1
const ATTENDANCE_REWARD_SHARDS_7 := 2  # 7일 마일스톤 보상 = 나비 조각 2 (승급 가속)
const COIN_GIFT_MIN := 10            # 선물 구매 최소가
const COIN_GIFT_MAX := 20            # 선물 구매 최대가
const MOOD_PENALTY_HOURS := 24       # 미접속 N시간+ → 시무룩
const MOOD_PENALTY_RATE := 0.2       # 시무룩 시 호감도 획득 −20%


## 누적 옥자 호감도로 관계 단계 문자열을 반환한다. ("guest" | "regular" | "comfy" | "close")
## 존댓말 = 손님(guest)·단골(regular) / 반말 = 편해진 사이(comfy)·마음 연 사이(close).
static func relationship_stage(affinity_total: int) -> String:
  if affinity_total >= REL_CLOSE:
    return "close"
  if affinity_total >= REL_COMFY:
    return "comfy"
  if affinity_total >= REL_REGULAR:
    return "regular"
  return "guest"


## 단계가 '반말' 단계인지 — 편해진 사이(comfy) 이상에서 반말 해금.
## 대화/티커 풀의 존댓말("guest")·반말("regular") 분기 단일 출처. (반말 전환 컷인도 comfy 도달 시)
static func is_casual(stage: String) -> bool:
  return stage == "comfy" or stage == "close"


# ── 호감도 수치 게이트웨이 (data/balance.json "affinity") ──
## balance.json 의 affinity 사전. 데이터가 없거나 키가 빠지면 _AFF_DEFAULT 폴백.
static func _aff_table() -> Dictionary:
  return GameData.balance().get("affinity", {})


## 대화 tier("good"|"plain") → 호감도. 선택지는 tier 만 들고 수치는 여기서. (수치 단일 출처)
static func aff_talk(tier: String) -> int:
  var t: Dictionary = _aff_table().get("talk", {})
  return int(t.get(tier, _AFF_TALK_DEFAULT.get(tier, _AFF_TALK_DEFAULT["plain"])))


## 선물 tier("match"|"sion"|"plain") → 호감도. sion(시온이 간식) > match > plain.
static func aff_gift(tier: String) -> int:
  var t: Dictionary = _aff_table().get("gift", {})
  return int(t.get(tier, _AFF_GIFT_DEFAULT.get(tier, _AFF_GIFT_DEFAULT["plain"])))


## 액션별 고정 호감도(drink/drink_favorite/cheki/touch/touch_session_cap/sion/sion_favorite).
static func aff(key: String) -> int:
  return int(_aff_table().get(key, _AFF_DEFAULT.get(key, 0)))
