class_name Dialogue
extends RefCounted
## 옥자/시온이 한 줄 티커 보이스 풀 (docs/script-okja.md 기반). (→ PRD §4.3)
## 표정 9할·대사 한 줄 원칙: 상시 대화창 없이 화면 맨 아래 한 줄로만 보이스를 띄운다.
##
## 상황(situation) × 관계 단계(stage)로 라인 풀을 고른다.
##   - stage "guest"   → 단계1: 존댓말 + "{nick}님"
##   - stage "regular"/"close" → 단계2: 반말 + 닉네임
## {nick} 토큰은 닉네임으로 치환된다.
##
## 티커 한 줄 풀(OKJA/SION) + 대화 팝업 토막(TALK) + 선물 선호표(GIFTS). (T11)
## 이모지는 폰트 호환을 위해 풀에서는 뺐다(원본 톤은 docs/script-okja.md 참조).
## 호감 수치는 여기서 안 박는다 — 선택지의 tier("good"/"match"/"sion"/"plain")만 들고,
## 실제 호감도 매핑은 Cafe 가 Balance.AFF_* 로 한다(수치 단일 출처 사수).

# 상황별 라인 풀. 각 상황 = { "guest": [존댓말...], "regular": [반말...] }
const OKJA := {
  "enter": {
    "guest":   ["또 왔네요, {nick}님.", "한가하신가 봐요, {nick}님."],
    "regular": ["왔어, {nick}? 흥.", "{nick}야~ 늦었어."],
  },
  "neglect": {  # 방치 후 복귀
    "guest":   ["오랜만이네요. 바쁘셨나 봐요.", "이제 오셨네요, {nick}님."],
    "regular": ["......이제 와? 흥.", "안 올 줄 알았잖아."],
  },
  "cheki": {  # 체키 주문 (획득 아님 — 조르기)
    "guest":   ["찍을 거면 빨리요.", "이상하게 찍지 마세요."],
    "regular": ["또 찍자고? 못 말려.", "표정 풀어. 잘 나오게."],
  },
  "drink": {  # 음료 주문
    "guest":   ["버건디예요. 마시세요.", "오늘의 시그니처예요."],
    "regular": ["자, 버건디. 마셔.", "단골 서비스야."],
  },
  "talk": {  # 대화 (Phase 1 간이 — 분기 팝업은 T11)
    "guest":   ["......무슨 할 말이라도.", "듣고는 있어요."],
    "regular": ["응, 말해 봐.", "뭐, 들어줄게."],
  },
  "gift": {  # 선물 (Phase 1 간이 — 선호 분기는 T11)
    "guest":   ["예쁘네요. 꽂아둘게요.", "......어떻게 아셨죠."],
    "regular": ["오, 고마워. 어디 둘까.", "이거 좋아하는 건데. 고마워."],
  },
  "touch": {  # 옥자 터치
    "guest":   ["......손버릇 나쁘시네요.", "간지러워요. 그만."],
    "regular": ["야, 간지러워.", "자꾸 만지면 문다?"],
  },
  "touch_cap": {  # 터치 세션 상한 도달
    "guest":   ["이제 그만 좀......", "정신없어요, {nick}님."],
    "regular": ["그만, 그만. 닳겠다.", "적당히 해, {nick}."],
  },
  "no_stamina": {  # 스태미나 소진 (오늘 끝)
    "guest":   ["오늘은 여기까지예요. 또 오세요.", "피곤하네요. 내일 봬요, {nick}님."],
    "regular": ["오늘은 그만. 내일 또 와.", "쉴래. ......또 와, {nick}."],
  },
  "cheki_get": {  # 게이지 풀 → 오늘의 체키 (실제 획득 연출은 T13/T18)
    "guest":   ["오늘 건 잘 나왔네요. 가지세요.", "이건 특별히 드릴게요."],
    "regular": ["자, 오늘의 체키. 소중히 해.", "후. 잘 나왔잖아."],
  },
  "stage_up": {  # 관계 단계 상승 (반말 전환 컷인은 T11)
    "guest":   ["......자주 오시네요, {nick}님."],
    "regular": ["이제 그냥 {nick}이라고 부를게.", "......착각 마. 부르기 편해서야."],
  },
  "idle": {
    "guest":   ["손님이 없네요.", "시온이가 또 자네요."],
    "regular": ["심심해. ......아니, 안 심심해.", "옆에 있어도 돼."],
  },
}

# 시온이 티커 — 고양이라 행동·의성어 (단계 구분 없음)
const SION := [
  "시온이가 골골거린다.",
  "시온이: 야옹—",
  "시온이가 꼬리를 흔든다.",
  "시온이가 배를 보인다!",
]

# ── 대화 팝업 토막 (T11) — `대화` 버튼, 단계별 2~3지선다 ──────────────
# 토막 = { prompt(옥자 질문), choices:[ {label, reply(옥자 반응), tier, expr} ] }.
#   tier: "good"(↑↑ 위트·솔직) | "plain"(↑/· 무난). expr: 선택 후 옥자 표정(okja.gd 상태).
#   단계 키: "guest"(존댓말+님) | "regular"(반말). {nick} 토큰 치환.
const TALK := {
  "guest": [
    {
      "prompt": "또 오셨네요. 일은 안 하세요?",
      "choices": [
        {"label": "쉬러 왔어요",   "reply": "팔자 좋으시네요.",        "tier": "plain", "expr": &"idle"},
        {"label": "마녀님 보러요", "reply": "후, 입만 살아서는.",      "tier": "good",  "expr": &"shy"},
        {"label": "그냥요",         "reply": "성의 없으시긴.",          "tier": "plain", "expr": &"talk"},
      ],
    },
    {
      "prompt": "시온이 예쁘죠. ……제 새끼라.",
      "choices": [
        {"label": "마녀님 닮았어요", "reply": "……누가 누굴.",          "tier": "good",  "expr": &"shy"},
        {"label": "통통해요",        "reply": "먹는 게 일이라.",        "tier": "plain", "expr": &"smile"},
      ],
    },
  ],
  "regular": [
    {
      "prompt": "왔어? ……오늘은 좀 보고 싶었는데.",
      "choices": [
        {"label": "나도",          "reply": "흥, 솔직하긴.",          "tier": "good",  "expr": &"shy"},
        {"label": "방금 뭐랬어?",   "reply": "못 들었으면 말고.",      "tier": "plain", "expr": &"talk"},
        {"label": "농담이지?",      "reply": "……됐어, 앉아.",         "tier": "plain", "expr": &"idle"},
      ],
    },
    {
      "prompt": "요즘 시온이가 너만 따라. 뭐 먹였어?",
      "choices": [
        {"label": "비밀이야",       "reply": "쳇, 치사해.",            "tier": "good",  "expr": &"shy"},
        {"label": "간식 줬어",      "reply": "고마워. 걔 잘 챙겨줘서.", "tier": "good",  "expr": &"smile"},
      ],
    },
  ],
}

# ── 선물 선호표 (T11) — `선물` 버튼, 4종 중 선택 ──────────────
# 선물 = { label, reply(옥자 반응), tier, expr }.
#   tier: "match"(좋아함 ↑↑) | "sion"(시온이 간식, 매우 좋아함 ↑↑↑) | "plain"(보통 ↑).
const GIFTS := [
  {"label": "다크 초콜릿",  "reply": "……단 거 좋아하는 거, 어떻게 알았죠.", "tier": "match", "expr": &"shy"},
  {"label": "회중시계",      "reply": "취향이네요. 나쁘지 않아요.",          "tier": "match", "expr": &"smile"},
  {"label": "시온이 간식",   "reply": "이건… 시온이 거잖아. ……고마워.",      "tier": "sion",  "expr": &"smile"},
  {"label": "꽃다발",        "reply": "예쁘네요. 꽂아둘게요.",               "tier": "plain", "expr": &"idle"},
]


## 상황+단계에 맞는 옥자 티커 한 줄을 랜덤으로 골라 {nick} 치환해 반환한다.
## stage 는 Balance.relationship_stage() 결과("guest"|"regular"|"close").
static func okja_line(situation: String, stage: String, nick: String) -> String:
  var pools: Dictionary = OKJA.get(situation, OKJA["idle"])
  # 단계2(regular/close)는 반말 풀, 그 외(guest)는 존댓말 풀
  var key := "regular" if stage != "guest" else "guest"
  var pool: Array = pools.get(key, pools.get("guest", []))
  if pool.is_empty():
    return ""
  var line: String = pool[randi() % pool.size()]
  return line.replace("{nick}", nick)


## 시온이 티커 한 줄 랜덤.
static func sion_line() -> String:
  return SION[randi() % SION.size()]


## 단계에 맞는 대화 토막 하나를 랜덤으로 골라 {nick} 치환해 반환. (대화 팝업 T11)
## 반환 { prompt:String, choices:Array[{label, reply, tier, expr}] }. (사본 — 원본 불변)
static func pick_talk(stage: String, nick: String) -> Dictionary:
  var key := "regular" if stage != "guest" else "guest"
  var pool: Array = TALK.get(key, TALK["guest"])
  var topic: Dictionary = pool[randi() % pool.size()]
  var choices: Array = []
  for c in topic["choices"]:
    var c2: Dictionary = (c as Dictionary).duplicate()
    c2["reply"] = String(c["reply"]).replace("{nick}", nick)
    choices.append(c2)
  return {"prompt": String(topic["prompt"]).replace("{nick}", nick), "choices": choices}


## 선물 팝업 오프닝 프롬프트(단계별).
static func gift_prompt(stage: String) -> String:
  return "뭐 줄 건데?" if stage != "guest" else "저한테 주실 거예요?"


## 선물 선택지 목록(표시명·반응). {nick} 치환한 사본 반환. (선호표 T11)
static func gift_choices(nick: String) -> Array:
  var out: Array = []
  for g in GIFTS:
    var g2: Dictionary = (g as Dictionary).duplicate()
    g2["reply"] = String(g["reply"]).replace("{nick}", nick)
    out.append(g2)
  return out
