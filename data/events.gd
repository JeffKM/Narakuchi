class_name Events
extends RefCounted
## 데모 이벤트 5종 (PRD §9.1) — 체키 컬렉션의 가로축(세트). (→ ADR 0002)
## 이벤트끼리 등급은 없다(동등). 등급은 오직 프레임(일반/나비)으로만 구분.
## ⚠️ 체키 데이터 모델 본격 구현은 T12. 여기선 식별자·표시명·캐릭터 보유 여부만 정의한다.

# 수집 주체(캐릭터) 키 — 체키 키 포맷 "{character}:{event}" 에 쓰임 (save_manager 참조)
const OKJA := "okja"
const SION := "sion"

## 이벤트 정의: id → { name(표시명), okja(옥자 칸 여부), sion(시온이 칸 여부), theme(나비 테마 프레임 메모) }
const LIST := {
  "mine":   {"name": "지뢰계", "okja": true,  "sion": true,  "theme": "메탈하트·리본"},
  "kinder": {"name": "유치원", "okja": true,  "sion": false, "theme": "크레용·무지개"},
  "hiphop": {"name": "힙합",   "okja": true,  "sion": false, "theme": "그래피티·체인"},
  "butler": {"name": "집사",   "okja": true,  "sion": false, "theme": "은쟁반·장미"},
  "xmas":   {"name": "크리스마스", "okja": true, "sion": true, "theme": "눈·리스"},
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
