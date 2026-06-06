class_name Dialogue
extends RefCounted
## 옥자/시온이 한 줄 티커 보이스 + 대화/선물 토막 — 데이터는 data/*.json (GameData 로드). (→ PRD §4.3)
## 표정 9할·대사 한 줄 원칙: 상시 대화창 없이 화면 맨 아래 한 줄로만 보이스를 띄운다.
##
## 상황(situation) × 관계 단계(stage)로 라인 풀을 고른다.
##   - 존댓말: 손님(guest) · 단골(regular) — 단골은 살가운 존댓말
##   - 반말  : 편해진 사이(comfy) · 마음 연 사이(close) — 반말 해금
##   분기 단일 출처는 Balance.is_casual(stage)(반말이면 "regular" 풀, 아니면 "guest" 풀).
## {nick} 토큰은 닉네임으로 치환된다.
##
## ⚠️ 이 클래스는 더 이상 대사를 const 로 들고 있지 않다 — content_studio(GUI)가 편집하는
##    data/ticker.json · talk.json · gifts.json 을 GameData 통해 읽는다(게임/툴 단일 출처).
##    정적 API(okja_line/sion_line/pick_talk/gift_prompt/gift_choices) 시그니처는 그대로다.
## 호감 수치는 여기서 안 박는다 — 선택지의 tier("good"/"match"/"sion"/"plain")만 들고,
## 실제 tier→수치 매핑은 Balance.aff_talk()/aff_gift() (data/balance.json, content_studio '밸런스' 탭 편집).


## 상황+단계에 맞는 옥자 티커 한 줄을 랜덤으로 골라 {nick} 치환해 반환한다.
## stage 는 Balance.relationship_stage() 결과("guest"|"regular"|"comfy"|"close").
static func okja_line(situation: String, stage: String, nick: String) -> String:
  var okja: Dictionary = GameData.ticker().get("okja", {})
  var pools: Dictionary = okja.get(situation, okja.get("idle", {}))
  # 반말 단계(편해진 사이 이상)는 반말 풀, 그 외(손님·단골)는 존댓말 풀
  var key := "regular" if Balance.is_casual(stage) else "guest"
  var pool: Array = pools.get(key, pools.get("guest", []))
  if pool.is_empty():
    return ""
  var line: String = pool[randi() % pool.size()]
  return line.replace("{nick}", nick)


## 관계 단계 상승 컷인 데이터(StageCutin 오버레이용). stage 는 도달 단계("regular"|"comfy").
## 반환 { lines:[{text,expr}], reveal:String, badge:String } — {nick} 치환된 사본. 없으면 빈 사전.
## okja_cutin 은 단계 키 직접 매핑(존댓말/반말 분기 아님) — regular=단골 등극, comfy=반말 해금.
static func okja_cutin(stage: String, nick: String) -> Dictionary:
  var pools: Dictionary = GameData.ticker().get("okja_cutin", {})
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


## 시온이 티커 한 줄 랜덤 — 버튼 id 별 풀에서 고른다(없으면 idle 폴백). (버튼별 풀 분리)
## action: 버튼 id("cheki"|"snack"|"play"|"pet") 또는 "idle"(터치·획득·평소).
static func sion_line(action: String = "idle") -> String:
  var sion: Dictionary = GameData.ticker().get("sion", {})
  var pool: Array = sion.get(action, sion.get("idle", []))
  if pool.is_empty():
    return ""
  return pool[randi() % pool.size()]


## 단계에 맞는 대화 토막 하나를 랜덤으로 골라 {nick} 치환해 반환. (대화 팝업)
## 반환 { prompt:String, choices:Array[{label, reply, tier, expr}] }. (사본 — 원본 불변)
static func pick_talk(stage: String, nick: String) -> Dictionary:
  var key := "regular" if Balance.is_casual(stage) else "guest"
  var pool: Array = GameData.talk().get(key, GameData.talk().get("guest", []))
  if pool.is_empty():
    return {"prompt": "", "choices": []}
  var topic: Dictionary = pool[randi() % pool.size()]
  return {
    "prompt": String(topic.get("prompt", "")).replace("{nick}", nick),
    "choices": _copy_choices(topic.get("choices", []), nick),
  }


## 선물 팝업 오프닝 프롬프트(단계별).
static func gift_prompt(stage: String) -> String:
  var prompts: Dictionary = GameData.gifts().get("prompt", {})
  var key := "regular" if Balance.is_casual(stage) else "guest"
  return String(prompts.get(key, prompts.get("guest", "")))


## 선물 선택지 목록(표시명·반응). {nick} 치환한 사본 반환. (선호표)
static func gift_choices(nick: String) -> Array:
  return _copy_choices(GameData.gifts().get("gifts", []), nick)


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
