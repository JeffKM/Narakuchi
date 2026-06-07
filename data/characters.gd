class_name Characters
## 캐릭터 데이터 레지스트리 (T30 / 이슈 #2) — 메인·펫의 단일 정의 출처.
##
## 라이브 스탠딩 표정 경로·세이브 상태 블록·게이지 풀·대사/버튼 키를 여기서 파생한다.
## 수치(게이지)는 Balance, 이벤트 슬러그는 Events 가 단일 출처 — 여기선 참조만 한다.
## (확장 트랙: 바나·멜 메인 + 코코·선아·수아·규종이 펫이 같은 틀로 추가 → character-expansion-plan)

const MAIN := "main"
const PET := "pet"

# id → 정의. 삽입 순서 = 로스터/탭 표시 순서.
#   kind            : main(교감·관계단계·기분) | pet(게이지만)
#   dialogue/buttons: 보이스·버튼 데이터 키 (미호는 #4부터 전용 대사 miho / 버튼·표정 매핑은 okja 공유)
#   intro_event     : 온보딩/인트로 체키 이벤트 id (→ Events)
#   accent          : 로스터/잠긴멤버 등 UI 강조 색(Palette) — 캐릭터 시그니처 톤
#   tag             : 로스터 카드 한 줄 소개(펫은 관계 단계가 없어 이 문구를 부제로 쓴다)
const REGISTRY := {
  "okja": {"name": "옥자",   "kind": MAIN, "dialogue": "okja", "buttons": "okja", "intro_event": "mine",
    "accent": Palette.VIOLET,      "tag": "지옥의 마녀"},
  "miho": {"name": "미호",   "kind": MAIN, "dialogue": "miho", "buttons": "okja", "intro_event": "mine",
    "accent": Palette.CANDLE,      "tag": "백·노랑 구미호"},
  "sion": {"name": "시온이", "kind": PET,  "dialogue": "sion", "buttons": "sion", "intro_event": "mine",
    "accent": Palette.ACCENT_PINK, "tag": "곁의 흰 고양이"},
}

# 라이브 스탠딩 표정 6종 (얼굴+팔 하드컷 스왑 → ADR 0001).
const EXPRESSION_KEYS := [&"idle", &"smile", &"shy", &"sad", &"brew", &"talk"]


static func has(id: String) -> bool:
  return REGISTRY.has(id)


static func get_def(id: String) -> Dictionary:
  return REGISTRY.get(id, {})


static func display_name(id: String) -> String:
  return String(get_def(id).get("name", id))


## 메인 캐릭터인가(교감·관계단계·기분 보유). 펫은 게이지만.
static func is_main(id: String) -> bool:
  return String(get_def(id).get("kind", MAIN)) == MAIN


## 기분(시무룩까지)을 가지는가 — 메인만. 펫은 기분 없음(벌 없는 설계).
static func has_mood(id: String) -> bool:
  return is_main(id)


static func dialogue_key(id: String) -> String:
  return String(get_def(id).get("dialogue", id))


static func buttons_key(id: String) -> String:
  return String(get_def(id).get("buttons", id))


static func intro_event(id: String) -> String:
  return String(get_def(id).get("intro_event", Events.FIRST_GIFT_EVENT))


## UI 강조 색(로스터 카드 테두리·실루엣 등). 정의에 없으면 중립 골드.
static func accent(id: String) -> Color:
  return get_def(id).get("accent", Palette.GOLD)


## 로스터 카드 한 줄 소개(펫 부제 등). 없으면 빈 문자열.
static func tag(id: String) -> String:
  return String(get_def(id).get("tag", ""))


## 24×24 도트 포트레이트 경로 — id 로 파생. (로스터/컬렉션 탭 공용)
static func portrait(id: String) -> String:
  return "res://assets/sprites/portrait_%s.png" % id


## kind 로 거른 id 목록(레지스트리 삽입 순서 유지).
static func ids_of_kind(kind: String) -> Array:
  var out: Array = []
  for id in REGISTRY:
    if String(REGISTRY[id].get("kind", MAIN)) == kind:
      out.append(id)
  return out


## 전체 캐릭터 id(메인+펫, 레지스트리 삽입 순서) — 체키 마일스톤 등 전수 순회용.
static func all_ids() -> Array:
  return REGISTRY.keys()


static func mains() -> Array:
  return ids_of_kind(MAIN)


static func pets() -> Array:
  return ids_of_kind(PET)


## 기본(첫) 메인 — 로스터 선택 전까지의 기본 active_main.
static func default_main() -> String:
  var m := mains()
  return String(m[0]) if not m.is_empty() else "okja"


## 기본(첫) 펫 — 로스터 선택 전까지의 기본 active_pet.
static func default_pet() -> String:
  var p := pets()
  return String(p[0]) if not p.is_empty() else "sion"


## 라이브 스탠딩 표정 6종 경로(누끼 PNG) — id 로 파생: "{id}_{key}.png".
static func expressions(id: String) -> Dictionary:
  var out := {}
  for k in EXPRESSION_KEYS:
    out[k] = "res://assets/sprites/%s_%s.png" % [id, k]
  return out


## 호감도 게이지 풀(체키 1장) — 숫자는 Balance 가 단일 출처.
static func gauge_full(id: String) -> int:
  match id:
    "okja": return Balance.GAUGE_OKJA
    "miho": return Balance.GAUGE_MIHO
    "sion": return Balance.GAUGE_SION
  return Balance.GAUGE_OKJA
