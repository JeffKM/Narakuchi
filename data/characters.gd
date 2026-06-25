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
#   dialogue/buttons: 보이스·버튼 데이터 키 (캐릭터별 전용 — 메인은 buttons[key].emotion, 펫은 buttons[key].actions)
#                     ※ 메인 버튼 라벨·순서는 코드 흐름(talk/gift 분기)과 잠금 — okja.actions 단일 출처를 공유한다.
#   sprite          : 라이브 스탠딩 표정 파일 접두어("{sprite}_{표정}.png"). 보통 id 와 같지만 시온이만 'sioni'.
#                     (portrait 는 id 기준 — portrait_sion.png. 표정 스탠딩만 이 접두어로 매핑한다.)
#   intro_event     : 온보딩/인트로 체키 이벤트 id (→ Events)
#   accent          : 로스터/잠긴멤버 등 UI 강조 색(Palette) — 캐릭터 시그니처 톤
#   tag             : 로스터 카드 한 줄 소개(펫은 관계 단계가 없어 이 문구를 부제로 쓴다)
const REGISTRY := {
  "okja": {"name": "옥자",   "kind": MAIN, "dialogue": "okja", "buttons": "okja", "sprite": "okja", "intro_event": "mine",
    "accent": Palette.VIOLET,      "tag": "지옥의 마녀"},
  "miho": {"name": "미호",   "kind": MAIN, "dialogue": "miho", "buttons": "miho", "sprite": "miho", "intro_event": "mine",
    "accent": Palette.CANDLE,      "tag": "백·노랑 구미호"},
  "sion": {"name": "시온이", "kind": PET,  "dialogue": "sion", "buttons": "sion", "sprite": "sioni", "intro_event": "mine",
    "accent": Palette.ACCENT_PINK, "tag": "곁의 흰 고양이", "growth_art": true},
  "gyujong": {"name": "규종이", "kind": PET, "dialogue": "gyujong", "buttons": "gyujong", "sprite": "gyujong", "intro_event": "mine",
    "accent": Palette.ACCENT_PINK, "tag": "미호의 까만 고양이"},
  "bana": {"name": "바나",   "kind": MAIN, "dialogue": "bana", "buttons": "bana", "sprite": "bana", "intro_event": "mine",
    "accent": Palette.PURPLE,      "tag": "뱀파이어 메이드"},
  "coco": {"name": "코코",   "kind": PET,  "dialogue": "coco", "buttons": "coco", "sprite": "coco", "intro_event": "mine",
    "accent": Palette.PURPLE,      "tag": "바나의 까만 고양이"},
  # 멜(강시 메이드) — 본배선(#14): 표정 6종 누끼·전용 ticker/talk/gifts/buttons.emotion 확정.
  # 옥자/미호/바나와 동일한 메인 틀(라이브·관계단계·반말 컷인·인트로 체키=지뢰계).
  "mel": {"name": "멜",     "kind": MAIN, "dialogue": "mel", "buttons": "mel", "sprite": "mel", "intro_event": "mine",
    "accent": Palette.TEAL,        "tag": "강시 메이드"},
  # 선아(멜의 갈색 푸들) — 펫 슬라이스. idle 확정(나머지 반응은 sioni.gd 폴백=idle), 전용 버튼/티커 배선.
  "suna": {"name": "선아",   "kind": PET,  "dialogue": "suna", "buttons": "suna", "sprite": "suna", "intro_event": "mine",
    "accent": Palette.TEAL,        "tag": "멜의 갈색 푸들"},
  # 수아(멜의 베이지 닥스훈트) — 멜 슬라이스의 둘째 펫(선아 미러). idle 확정(나머지 반응 폴백=idle), 전용 버튼/티커 배선.
  "sua": {"name": "수아",    "kind": PET,  "dialogue": "sua", "buttons": "sua", "sprite": "sua", "intro_event": "mine",
    "accent": Palette.TEAL,        "tag": "멜의 베이지 닥스훈트"},
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


## 라이브 스탠딩 표정 파일 접두어("{prefix}_{표정}.png"). 정의에 없으면 id 폴백(보통 id=접두어, 시온이만 'sioni').
static func sprite_prefix(id: String) -> String:
  return String(get_def(id).get("sprite", id))


## 성장 단계·체형 분기 아트가 갖춰진 펫인가 — 그 외 펫은 항상 캐논 스프라이트(기존 그대로). 현재 시온이만.
static func has_growth_art(id: String) -> bool:
  return bool(get_def(id).get("growth_art", false))


## 성장 단계 문자열("baby"|"child"|"adult") + 성체 체형(body) → 라이브 스프라이트 접두어. (D1/D2)
## 아기·유년만 단계 접미사를 붙이고, 성체는 체형 분기: 마름(_thin)·통통(_fat)만 신규 아트,
## 보통(normal)·미확정("")은 접두어 그대로 = 기존 시온이 캐논 재사용(D0). body 는 성체에서만 의미.
## 단, 성장·체형 아트가 완비된 펫(growth_art)만 분기하고, 그 외 펫은 항상 캐논(기존 그대로 — 깨진 경로 방지).
static func pet_stage_prefix(id: String, stage: String, body := "") -> String:
  var base := sprite_prefix(id)
  if not has_growth_art(id):
    return base
  match stage:
    "baby": return base + "_baby"
    "child": return base + "_child"
  # adult — 체형 분기(D2): 양끝만 접미사, 보통/미확정은 캐논 그대로.
  match body:
    "thin": return base + "_thin"
    "fat": return base + "_fat"
  return base


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


## 라이브 스탠딩 표정 6종 경로(누끼 PNG) — sprite 접두어로 파생: "{sprite}_{key}.png".
static func expressions(id: String) -> Dictionary:
  var out := {}
  var prefix := sprite_prefix(id)
  for k in EXPRESSION_KEYS:
    out[k] = "res://assets/sprites/%s_%s.png" % [prefix, k]
  return out


## 호감도 게이지 풀(체키 1장) — 숫자는 Balance 가 단일 출처.
static func gauge_full(id: String) -> int:
  match id:
    "okja": return Balance.GAUGE_OKJA
    "miho": return Balance.GAUGE_MIHO
    "sion": return Balance.GAUGE_SION
    "gyujong": return Balance.GAUGE_GYUJONG
    "bana": return Balance.GAUGE_BANA
    "coco": return Balance.GAUGE_COCO
    "mel": return Balance.GAUGE_MEL
    "suna": return Balance.GAUGE_SUNA
    "sua": return Balance.GAUGE_SUA
  return Balance.GAUGE_OKJA
