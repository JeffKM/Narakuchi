class_name Dialogue
extends RefCounted
## 메인 캐릭터(옥자·미호…) 한 줄 티커 보이스 + 대화/선물 토막 + 시온이 보이스. (→ PRD §4.3)
## 데이터는 data/*.json (GameData 로드). 표정 9할·대사 한 줄 원칙: 상시 대화창 없이 화면 맨 아래 한 줄로만.
##
## 상황(situation) × 관계 단계(stage)로 라인 풀을 고른다.
##   - 존댓말: 손님(guest) · 단골(regular) — 단골은 살가운 존댓말
##   - 반말  : 편해진 사이(comfy) · 마음 연 사이(close) — 반말 해금
##   분기 단일 출처는 Balance.is_casual(stage)(반말이면 "regular" 풀, 아니면 "guest" 풀).
## {nick} 토큰은 닉네임으로 치환된다.
##
## ★ 캐릭터별 일반화(T31/이슈 #4): 모든 메인 함수는 첫 인자로 dialogue_key(Characters.dialogue_key)를 받는다.
##   - ticker: data/ticker.json 의 {key}(상황 풀) / {key}_cutin(단계 컷인) — 옥자=okja, 미호=miho.
##   - talk/gifts: 캐릭터 키 하위가 있으면 그걸, 없으면 평면 루트(옥자 legacy) — _section 폴백.
##     이 폴백 덕에 옥자 talk.json/gifts.json 은 평면 그대로 두어 content_studio(GUI 툴)가 무손상이고,
##     미호 등 신규 캐릭터만 character 키로 추가하면 된다.
##   - 미호 데이터가 아직 없으면 ticker 도 okja 로 폴백 → 안전(옥자 대사로 보임).
##
## ⚠️ 대사는 const 가 아니라 content_studio(GUI)가 편집하는 data/*.json 을 GameData 통해 읽는다(게임/툴 단일 출처).
## 호감 수치는 여기서 안 박는다 — 선택지의 tier("good"/"match"/"sion"/"plain")만 들고,
## 실제 tier→수치 매핑은 Balance.aff_talk()/aff_gift() (data/balance.json).


## 상황+단계에 맞는 메인 캐릭터 티커 한 줄을 랜덤으로 골라 {nick} 치환해 반환한다.
## key 는 Characters.dialogue_key("okja"|"miho"…), stage 는 Balance.relationship_stage() 결과.
static func line(key: String, situation: String, stage: String, nick: String) -> String:
  var char_pool: Dictionary = GameData.ticker().get(key, GameData.ticker().get("okja", {}))
  var pools: Dictionary = char_pool.get(situation, char_pool.get("idle", {}))
  # 반말 단계(편해진 사이 이상)는 반말 풀, 그 외(손님·단골)는 존댓말 풀
  var sk := "regular" if Balance.is_casual(stage) else "guest"
  var pool: Array = pools.get(sk, pools.get("guest", []))
  if pool.is_empty():
    return ""
  var ln: String = pool[randi() % pool.size()]
  return ln.replace("{nick}", nick)


## 관계 단계 상승 컷인 데이터(StageCutin 오버레이용). stage 는 도달 단계("regular"|"comfy").
## 반환 { lines:[{text,expr}], reveal:String, badge:String } — {nick} 치환된 사본. 없으면 빈 사전.
## 단계 키 직접 매핑(존댓말/반말 분기 아님) — regular=단골 등극, comfy=반말 해금.
## ticker.json 의 {key}_cutin (옥자=okja_cutin, 미호=miho_cutin). 미호 컷인 없으면 okja_cutin 폴백.
static func cutin(key: String, stage: String, nick: String) -> Dictionary:
  var t: Dictionary = GameData.ticker()
  var pools: Dictionary = t.get("%s_cutin" % key, t.get("okja_cutin", {}))
  var data: Dictionary = pools.get(stage, {})
  if data.is_empty():
    return {}
  var lines: Array = []
  for ln in data.get("lines", []):
    lines.append({
      "text": String(ln.get("text", "")).replace("{nick}", nick),
      "expr": StringName(ln.get("expr", "talk")),
    })
  return {
    "lines": lines,
    "reveal": String(data.get("reveal", "")).replace("{nick}", nick),
    "badge": String(data.get("badge", "")),
  }


## 시온이 티커 한 줄 랜덤 — 버튼 id 별 풀에서 고른다(없으면 idle 폴백). (펫 — 단계 구분 없음)
## action: 버튼 id("cheki"|"snack"|"play"|"pet") 또는 "idle"(터치·획득·평소).
static func sion_line(action: String = "idle") -> String:
  var sion: Dictionary = GameData.ticker().get("sion", {})
  var pool: Array = sion.get(action, sion.get("idle", []))
  if pool.is_empty():
    return ""
  return pool[randi() % pool.size()]


## 단계에 맞는 대화 토막 하나를 랜덤으로 골라 {nick} 치환해 반환. (대화 팝업)
## 반환 { prompt:String, choices:Array[{label, reply, tier, expr}] }. (사본 — 원본 불변)
static func pick_talk(key: String, stage: String, nick: String) -> Dictionary:
  var root := _section(GameData.talk(), key)
  var sk := "regular" if Balance.is_casual(stage) else "guest"
  var pool: Array = root.get(sk, root.get("guest", []))
  if pool.is_empty():
    return {"prompt": "", "choices": []}
  var topic: Dictionary = pool[randi() % pool.size()]
  return {
    "prompt": String(topic.get("prompt", "")).replace("{nick}", nick),
    "choices": _copy_choices(topic.get("choices", []), nick),
  }


## 선물 팝업 오프닝 프롬프트(단계별).
static func gift_prompt(key: String, stage: String) -> String:
  var root := _section(GameData.gifts(), key)
  var prompts: Dictionary = root.get("prompt", {})
  var sk := "regular" if Balance.is_casual(stage) else "guest"
  return String(prompts.get(sk, prompts.get("guest", "")))


## 선물 선택지 목록(표시명·반응). {nick} 치환한 사본 반환. (선호표)
## reply 는 단계별(존댓말/반말), label/tier/expr/icon 은 공통. {nick} 치환.
static func gift_choices(key: String, stage: String, nick: String) -> Array:
  var root := _section(GameData.gifts(), key)
  var sk := "regular" if Balance.is_casual(stage) else "guest"
  var out: Array = []
  for g in root.get("gifts", []):
    out.append({
      "label": String(g.get("label", "")),
      "reply": _stage_reply(g.get("reply", ""), sk).replace("{nick}", nick),
      "tier": String(g.get("tier", "plain")),
      "expr": StringName(g.get("expr", "shy")),
      "icon": String(g.get("icon", "")),  # 선물 팝업 버튼 좌측 아이콘 슬롯 id(없으면 텍스트만)
    })
  return out


## talk/gifts 의 캐릭터 섹션 — key 하위가 있으면 그걸, 없으면 평면 루트(옥자 legacy).
## 옥자는 평면 구조(content_studio 무손상), 미호 등은 character 키 하위.
static func _section(db: Dictionary, key: String) -> Dictionary:
  if db.has(key):
    return db[key]
  return db


## 선물 reply 단계 선택 — {guest,regular} 객체면 단계 키로, 단일 문자열이면 그대로(구버전 호환).
static func _stage_reply(reply: Variant, key: String) -> String:
  if reply is Dictionary:
    return String(reply.get(key, reply.get("guest", "")))
  return String(reply)


## 선택지 배열을 사본으로 복제 + {nick} 치환 + expr 을 StringName 으로 정규화.
## (JSON 의 expr 은 String — Okja.set_expression(StringName) 호환을 위해 변환)
static func _copy_choices(choices: Array, nick: String) -> Array:
  var out: Array = []
  for c in choices:
    var src: Dictionary = c
    out.append({
      "label": String(src.get("label", "")),
      "reply": String(src.get("reply", "")).replace("{nick}", nick),
      "tier": String(src.get("tier", "plain")),
      "expr": StringName(src.get("expr", "talk")),
    })
  return out
