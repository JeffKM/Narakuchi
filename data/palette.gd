class_name Palette
extends RefCounted
## 나라쿠치 마스터 팔레트 (~32색) — 다크 앤틱 무드 (→ ADR 0001)
## 모든 도트 에셋은 이 팔레트로 인덱싱해 통일감을 강제한다.
## 사용 예: Palette.GOLD, Palette.BG

# ── 베이스 / 다크 ──────────────────────────────
const INK := Color("0d0b12")        # 먹빛 블랙 (배경 기본)
const CHARCOAL := Color("1c1a24")
const SHADOW := Color("2b2733")
const WOOD_DARK := Color("2a1d18")
const WOOD := Color("3a2a22")        # 앤틱 우드
const WOOD_LIGHT := Color("5a4334")

# ── 버건디 / 레드 (나라카 시그니처) ────────────────
const BURGUNDY_DARK := Color("4d1226")
const BURGUNDY := Color("7a1f3d")    # 버건디 윗치
const BLOOD := Color("c0263c")       # 블러드 레드
const ROSE := Color("e0556b")

# ── 골드 / 캔들 (앤틱 조명) ──────────────────────
const GOLD_DARK := Color("8a6f33")
const GOLD := Color("caa75a")        # 앤틱 골드 (프레임/포인트)
const CANDLE := Color("f2d49b")      # 캔들 옐로
const CREAM := Color("f7ecd0")

# ── 뉴트럴 그레이 램프 ───────────────────────────
const GREY_900 := Color("161420")
const GREY_700 := Color("2e2b3a")
const GREY_500 := Color("4b4756")
const GREY_400 := Color("6d6a78")
const GREY_300 := Color("9a96a3")
const GREY_200 := Color("c4c1cc")
const WHITE := Color("f4f2f7")

# ── 피부 톤 ────────────────────────────────────
const SKIN_SHADOW := Color("c98a6a")
const SKIN := Color("f0b890")
const SKIN_LIGHT := Color("ffd9b8")

# ── 쿨 액센트 (마법/음료) ────────────────────────
const PURPLE := Color("5b3d7a")      # 마녀 퍼플
const VIOLET := Color("9a6fd0")
const TEAL := Color("2f7d72")        # 청운 에이드
const CYAN := Color("6fd0c4")

# ── 캐릭터/이벤트 액센트 슬롯 (의상마다 교체) ──────────
const ACCENT_PINK := Color("ff6fae")   # 지뢰계
const ACCENT_YELLOW := Color("ffd23f") # 유치원
const ACCENT_BLUE := Color("3fa9ff")   # 힙합
const ACCENT_GREEN := Color("3fd47a")  # 크리스마스

## 전체 팔레트 배열 (도트 인덱싱/검수용 참조)
const ALL: Array[Color] = [
  INK, CHARCOAL, SHADOW, WOOD_DARK, WOOD, WOOD_LIGHT,
  BURGUNDY_DARK, BURGUNDY, BLOOD, ROSE,
  GOLD_DARK, GOLD, CANDLE, CREAM,
  GREY_900, GREY_700, GREY_500, GREY_400, GREY_300, GREY_200, WHITE,
  SKIN_SHADOW, SKIN, SKIN_LIGHT,
  PURPLE, VIOLET, TEAL, CYAN,
  ACCENT_PINK, ACCENT_YELLOW, ACCENT_BLUE, ACCENT_GREEN,
]
