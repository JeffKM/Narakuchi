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
#   dialogue/buttons: 보이스·버튼 데이터 키 (미호는 #4 전까지 옥자 템플릿 공유)
#   intro_event     : 온보딩/인트로 체키 이벤트 id (→ Events)
const REGISTRY := {
  "okja": {"name": "옥자",   "kind": MAIN, "dialogue": "okja", "buttons": "okja", "intro_event": "mine"},
  "miho": {"name": "미호",   "kind": MAIN, "dialogue": "okja", "buttons": "okja", "intro_event": "mine"},
  "sion": {"name": "시온이", "kind": PET,  "dialogue": "sion", "buttons": "sion", "intro_event": "mine"},
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


## kind 로 거른 id 목록(레지스트리 삽입 순서 유지).
static func ids_of_kind(kind: String) -> Array:
  var out: Array = []
  for id in REGISTRY:
    if String(REGISTRY[id].get("kind", MAIN)) == kind:
      out.append(id)
  return out


static func mains() -> Array:
  return ids_of_kind(MAIN)


static func pets() -> Array:
  return ids_of_kind(PET)


## 기본(첫) 메인 — 로스터 선택(#3) 전까지의 기본 active_main.
static func default_main() -> String:
  var m := mains()
  return String(m[0]) if not m.is_empty() else "okja"


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
