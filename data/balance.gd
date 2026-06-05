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
const AFF_DRINK := 12            # 🍷 음료 주문
const AFF_DRINK_FAVORITE := 18   # 🍷 선호 음료 보너스
const AFF_CHEKI := 10            # 🃏 체키 주문 (획득 아님, 호감도만)
const AFF_TALK_GOOD := 15        # 💬 대화 — 좋은 선택
const AFF_TALK_PLAIN := 8        # 💬 대화 — 평범한 선택
const AFF_GIFT_MATCH := 20       # 🎁 선물 — 맞음
const AFF_GIFT_PLAIN := 10       # 🎁 선물 — 보통
const AFF_GIFT_SION_TO_OKJA := 25 # 🎁 시온이 간식 → 옥자 호감도
const AFF_TOUCH := 2             # 👆 터치 (무료)
const AFF_TOUCH_SESSION_CAP := 10 # 👆 터치 세션당 호감도 상한
const AFF_SION := 10             # 🐱 시온이 간식/놀기/쓰담 각
const AFF_SION_FAVORITE := 15    # 🐱 선호 간식 보너스

# ── 게이지 → 체키 ─────────────────────────────
const GAUGE_OKJA := 300          # 옥자 호감도 게이지 풀 = 체키 1장
const GAUGE_SION := 200          # 시온이 게이지 풀 = 체키 1장

# ── 관계 단계 (누적 옥자 호감도) ────────────────
const REL_GUEST := 0             # 손님: 존댓말 + "{닉}님"
const REL_REGULAR := 600         # 단골: 반말 + 닉네임 (~2주)
const REL_CLOSE := 2000          # 마음 연 사이: 속내·애칭·특별 대화 (~6주)

# 데모 시연 세이브 시드값 — 첫 세션 한 번의 교감으로 '반말 전환 컷인'(600)이 터지도록 직전까지 채움
# (가장 작은 액션 AFF_TALK_PLAIN=8 만으로도 600 을 넘기게 595)
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


## 누적 옥자 호감도로 관계 단계 문자열을 반환한다. ("guest" | "regular" | "close")
static func relationship_stage(affinity_total: int) -> String:
  if affinity_total >= REL_CLOSE:
    return "close"
  if affinity_total >= REL_REGULAR:
    return "regular"
  return "guest"
