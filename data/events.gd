class_name Events
extends RefCounted
## 데모 이벤트 5종 (PRD §9.1) — 체키 컬렉션의 가로축(세트). (→ ADR 0002)
## 이벤트끼리 등급은 없다(동등). 등급은 오직 프레임(일반/나비)으로만 구분.
## ⚠️ 체키 데이터 모델 본격 구현은 T12. 여기선 식별자·표시명·캐릭터 보유 여부만 정의한다.

# 수집 주체(캐릭터) 키 — 체키 키 포맷 "{character}:{event}" 에 쓰임 (save_manager 참조)
const OKJA := "okja"
const SION := "sion"
const GYUJONG := "gyujong"

## 이벤트 정의: id → { name(표시명), slug(에셋 파일 접미사), okja, sion, theme(나비 테마 프레임 메모) }
## ⚠️ id 와 slug 는 다를 수 있다 — id="mine"(지뢰계)의 에셋 접미사는 "jirai"(okja_jirai/bg_cheki_okja_jirai/frame_jirai).
const LIST := {
  "mine":   {"name": "지뢰계", "slug": "jirai",  "okja": true,  "sion": true,  "miho": true,  "gyujong": true, "bana": true, "coco": true, "mel": true, "suna": true, "sua": true, "theme": "메탈하트·리본"},
  "kinder": {"name": "유치원", "slug": "kinder", "okja": true,  "sion": false, "miho": true, "bana": true, "mel": true, "theme": "크레용·무지개"},
  "hiphop": {"name": "힙합",   "slug": "hiphop", "okja": true,  "sion": false, "theme": "그래피티·체인"},
  "butler": {"name": "집사",   "slug": "butler", "okja": true,  "sion": false, "theme": "은쟁반·장미"},
  "xmas":   {"name": "크리스마스", "slug": "xmas", "okja": true, "sion": true, "gyujong": true, "coco": true, "suna": true, "sua": true, "theme": "눈·리스"},
}

# 체키 카드 아트(의상 누끼 + 사진 배경 + 테마 프레임)가 준비된 이벤트.
# "오늘의 체키"는 여기 있는 이벤트 안에서만 고른다(아트 없는 칸을 렌더러에 넘기지 않게).
# A4/A5로 의상·배경·프레임이 추가되면 해당 id를 켠다. (→ asset-checklist A2~A5)
# A4: kinder·hiphop·butler(옥자 의상 누끼 + bg_cheki_* + frame_*) 검수 통과.
# A5: xmas(옥자 okja_xmas 3겹 합성 / 시온이 photo_sion_xmas 베이크 컷, frame_xmas 공용) 검수 통과.
const ART_READY := {
  "mine": true,
  "kinder": true,
  "hiphop": true,
  "butler": true,
  "xmas": true,
}

# 첫 방문 기념 증정 = 지뢰계(★히어로) 일반체키 (PRD §4.5 / T06b)
const FIRST_GIFT_EVENT := "mine"


## "{character}:{event}" 체키 키를 만든다.
static func cheki_key(character: String, event: String) -> String:
  return "%s:%s" % [character, event]


## 이벤트 표시명. 없으면 id 그대로.
static func event_name(event: String) -> String:
  var e: Dictionary = LIST.get(event, {})
  return e.get("name", event)


## 체키 뒷면 폴라로이드 윗쪽에 오버레이되는 데이 라벨. 표시명에서 "{표시명} 데이"로 파생. (→ ADR 0003)
## (별도 caption 필드를 두지 않고 이름에서 만든다 — 커스텀 문구가 필요해지면 LIST에 필드 추가)
static func cheki_day_label(event: String) -> String:
  return "%s 데이" % event_name(event)


## 에셋 파일 접미사(slug). 없으면 id 그대로. (id="mine" → "jirai")
static func event_slug(event: String) -> String:
  var e: Dictionary = LIST.get(event, {})
  return e.get("slug", event)


## 이 이벤트의 체키 카드 아트가 준비됐나(의상·배경·테마 프레임). "오늘의 체키" 후보 필터.
static func cheki_art_ready(event: String) -> bool:
  return bool(ART_READY.get(event, false))


## 이 캐릭터가 보유 가능한 이벤트 id 목록(LIST 정의 순서). 컬렉션북(T16) 칸 나열용.
## (옥자 → 전체 5종, 시온이·규종이·코코·선아·수아 → mine·xmas)
static func events_for(character: String) -> Array:
  var out: Array = []
  for ev in LIST:
    if bool(LIST[ev].get(character, false)):
      out.append(ev)
  return out


# ── 체키 카드 합성 레이어 에셋 경로 (→ ADR 0003) ─────────────────
# 사진 면 = [배경 bg_cheki_{char}_{slug}] + [의상 누끼 {char}_{slug}] + [테마/표준 프레임]
# 단, photo_{char}_{slug} 베이크 컷이 있으면 배경+의상을 그 한 장으로 대체한다(아래 참조).

## 사진 면을 단일 "베이크 컷"(배경+의상이 한 장에 그려진 풀신 사진)으로 쓸 경우의 경로.
## 이 파일이 있으면 ChekiCard 는 3겹 합성(배경+누끼+프레임) 대신 이 한 장을 창에 깔고 프레임만 덧댄다.
## 누끼 분리가 어렵거나 배경과 함께 연출한 전신 컷에 쓴다 — 캐릭터별·이벤트별.
## 규격: 카드 배경과 동일한 120×180(2:3). 창(108×162)과 비율이 같아 균일 축소만 되고 크롭·왜곡 없음.
static func cheki_photo_path(character: String, event: String) -> String:
  return "res://assets/sprites/photo_%s_%s.png" % [character, event_slug(event)]


## 의상 누끼 스탠딩 경로. okja → okja_{slug}, sion → sion_{slug}.
static func cheki_costume_path(character: String, event: String) -> String:
  return "res://assets/sprites/%s_%s.png" % [character, event_slug(event)]


## 사진 면 배경(불투명 풍경) 경로. 캐릭터×이벤트별 — 멤버마다 그 이벤트 데이 의상에 맞춘 배경.
## (ADR 0003 개정 2026-06-07: 기존 "이벤트별 공유"에서 "캐릭터×이벤트"로 변경)
static func cheki_bg_path(character: String, event: String) -> String:
  return "res://assets/sprites/bg_cheki_%s_%s.png" % [character, event_slug(event)]


## 사진 면 테두리 프레임 경로. 나비 = 이벤트 테마 프레임, 일반 = 표준 프레임.
static func cheki_frame_path(event: String, butterfly: bool) -> String:
  if butterfly:
    return "res://assets/sprites/frame_%s.png" % event_slug(event)
  return "res://assets/sprites/frame_standard.png"
