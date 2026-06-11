extends Node
## 로컬 세이브 매니저 (T05) — 저장/불러오기/초기화 골격
##
## autoload 싱글톤으로 등록되어 어디서든 `SaveManager.data` 로 접근한다.
## (project.godot [autoload] 에 "SaveManager" 로 등록)
##
## 저장 방식: user://narakuchi_save.json (JSON 텍스트)
##   - 데스크톱: 유저 데이터 폴더의 실제 파일
##   - 웹(HTML5 export): Godot 이 user:// 를 브라우저 IndexedDB 에 자동 영속화 →
##     사실상 localStorage 와 동일한 '브라우저 로컬 저장'. 별도 JS 연동 불필요.
##
## 서버/계정 없음. 단일 슬롯. 스키마는 default_save() 가 단일 출처(SSOT).

const SAVE_PATH := "user://narakuchi_save.json"
const SAVE_VERSION := 2  # 스키마 버전 (v2: 캐릭터 레지스트리 + active_main — T30/이슈 #2)

## 현재 게임 상태. 항상 default_save() 스키마를 만족한다고 가정해도 되도록 load 시 보정한다.
var data: Dictionary = {}

## 저장 성공/실패를 UI 등에서 구독할 수 있게 신호 제공 (골격 — 후속 태스크에서 활용)
signal saved
signal loaded
signal save_failed(reason: String)


func _ready() -> void:
  load_game()


## 새 게임 기본 세이브 스키마 — 모든 키의 단일 출처(SSOT).
## 기본 수치는 전부 Balance(data/balance.gd)에서 가져온다 (하드코딩 금지).
func default_save() -> Dictionary:
  var d := {
    "version": SAVE_VERSION,
    "player": {
      "nickname": "",        # 온보딩에서 입력 (T06b)
      "coins": 0,
    },
    "stamina": Balance.STAMINA_MAX,  # 캐릭터 공유, 매일 풀 충전
    # 보유 체키 (T12 → scripts/systems/cheki.gd). 키 "{character}:{event}" →
    #   {common:int 획득누적, butterfly:bool 나비승급, shards:int 나비조각,
    #    nickname:String 첫획득 닉 스냅샷, acquired_at:int 첫획득 epoch}  (→ ADR 0002·0003)
    "cheki": {},
    # 출석/연속출석. last_date 는 "YYYY-MM-DD" 로컬 날짜 문자열.
    "attendance": {
      "last_date": "",
      "streak": 0,
    },
    # 이번 세션 한정 누적값 (예: 터치 호감도 상한). 날짜 바뀌면 리셋 (후속 태스크).
    "session": {
      "touch_affinity": 0,
    },
    # 임의 플래그 (온보딩 완료, 튜토리얼 등)
    #   announced_stage = 마지막으로 '입장 연출'한 관계 단계. 단계 상승은 그 자리서 안 터지고
    #     다음 입장(Cafe.start)에 1회만 발화 — 이 값으로 재발화를 막는다. (guest/regular/comfy/close)
    #   active_main = 현재 교감 중인 메인 id (로스터 선택으로 교체). (T30/이슈 #2)
    #   active_pet  = 곁의 펫 id (로스터에서 메인과 자유 조합). 펫은 현재 시온이 1종.
    #   sfx_on = 전역 음소거(설정 패널 토글 → Sfx._enabled 게이트). 볼륨과 독립.
    #   volume = 마스터 음량 0.0~1.0 선형(설정 패널 6단계 → step/5). Sfx 가 Master 버스 dB 로 적용.
    "flags": {
      "announced_stage": "guest", "sfx_on": true, "volume": 1.0,
      "active_main": Characters.default_main(), "active_pet": Characters.default_pet(),
    },
    "last_saved_unix": 0,    # 마지막 저장 시각 (epoch sec) — 기분 경과시간 계산용
  }
  # 캐릭터별 상태(레지스트리 주도 — okja/sion/miho… 하드코딩 제거 → T30/이슈 #2).
  #   메인: affinity_total(관계 단계 판정) + gauge(가득→체키) + mood. 펫: 게이지만(기분 없음).
  for id in Characters.REGISTRY:
    var c := {"affinity_total": 0, "gauge": 0}
    if Characters.has_mood(id):
      c["mood"] = "happy"  # happy | normal | sulky
    d[id] = c
  return d


## 세이브 불러오기. 파일이 없거나 손상되면 기본 세이브로 시작한다(앱이 죽지 않게).
func load_game() -> void:
  if not FileAccess.file_exists(SAVE_PATH):
    data = default_save()
    loaded.emit()
    return

  var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
  if f == null:
    push_warning("[Save] 파일 열기 실패(코드 %d) → 기본 세이브로 시작" % FileAccess.get_open_error())
    data = default_save()
    loaded.emit()
    return

  var text := f.get_as_text()
  f.close()

  var parsed: Variant = JSON.parse_string(text)
  if typeof(parsed) != TYPE_DICTIONARY:
    push_warning("[Save] JSON 파싱 실패(손상된 세이브) → 기본 세이브로 시작")
    data = default_save()
    loaded.emit()
    return

  var defaults := default_save()
  data = _migrate(parsed as Dictionary)
  data = _merge_defaults(data, defaults)  # 신규 키 누락 보정
  data = _coerce_types(data, defaults)    # JSON float → 스키마 int 보정
  loaded.emit()


## 세이브 저장. JSON 으로 직렬화해 user:// 에 기록한다(웹은 IndexedDB 자동 영속).
## 반환값: 성공 여부.
func save_game() -> bool:
  data["last_saved_unix"] = Clock.now()  # Clock seam: 테스트가 방치 경과시간을 제어할 수 있게

  var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if f == null:
    var reason := "파일 쓰기 열기 실패(코드 %d)" % FileAccess.get_open_error()
    push_error("[Save] " + reason)
    save_failed.emit(reason)
    return false

  f.store_string(JSON.stringify(data, "  "))  # 들여쓰기 2칸 (가독성)
  f.close()
  saved.emit()
  return true


## 세이브를 새 게임 기본값으로 초기화하고 저장한다.
func reset() -> void:
  data = default_save()
  save_game()


## 파라미터로 세이브 상태를 조립한다 — 테스트/개발 프리셋의 단일 상태 출처.
## default_save() 스키마 위에 주어진 키만 '의미 단위'로 덮어쓴다. 내러티브 시드(매직넘버)가
## 아니라 호출자가 의도를 명시한다. 게임 로직(relationship_stage/컷인)과 독립적으로 상태만 만든다.
## 지원 키: nickname, coins, onboarded, announced_stage, active_main, active_pet,
##   okja_affinity(정확값) | okja_stage(단계 임계값), okja_gauge, okja_mood,
##   miho_affinity, miho_gauge, miho_mood,
##   sion_affinity, sion_gauge, attendance_streak, attendance_last_date.
func build_state(opts: Dictionary = {}) -> Dictionary:
  var d := default_save()
  if opts.has("nickname"):
    d["player"]["nickname"] = String(opts["nickname"])
  if opts.has("coins"):
    d["player"]["coins"] = int(opts["coins"])
  if opts.has("onboarded"):
    d["flags"]["onboarded"] = bool(opts["onboarded"])
  if opts.has("announced_stage"):
    d["flags"]["announced_stage"] = String(opts["announced_stage"])
  if opts.has("active_main"):
    d["flags"]["active_main"] = String(opts["active_main"])
  if opts.has("active_pet"):
    d["flags"]["active_pet"] = String(opts["active_pet"])
  # 옥자 호감도: 정확값(okja_affinity) 우선, 없으면 단계(okja_stage)의 임계값.
  if opts.has("okja_affinity"):
    d["okja"]["affinity_total"] = int(opts["okja_affinity"])
  elif opts.has("okja_stage"):
    d["okja"]["affinity_total"] = Balance.stage_threshold(String(opts["okja_stage"]))
  if opts.has("okja_gauge"):
    d["okja"]["gauge"] = int(opts["okja_gauge"])
  if opts.has("okja_mood"):
    d["okja"]["mood"] = String(opts["okja_mood"])
  # 미호(메인) — 옥자와 동형. 정확값(miho_affinity) 우선, 없으면 단계(miho_stage).
  if opts.has("miho_affinity"):
    d["miho"]["affinity_total"] = int(opts["miho_affinity"])
  elif opts.has("miho_stage"):
    d["miho"]["affinity_total"] = Balance.stage_threshold(String(opts["miho_stage"]))
  if opts.has("miho_gauge"):
    d["miho"]["gauge"] = int(opts["miho_gauge"])
  if opts.has("miho_mood"):
    d["miho"]["mood"] = String(opts["miho_mood"])
  if opts.has("sion_affinity"):
    d["sion"]["affinity_total"] = int(opts["sion_affinity"])
  if opts.has("sion_gauge"):
    d["sion"]["gauge"] = int(opts["sion_gauge"])
  if opts.has("attendance_streak"):
    d["attendance"]["streak"] = int(opts["attendance_streak"])
  if opts.has("attendance_last_date"):
    d["attendance"]["last_date"] = String(opts["attendance_last_date"])
  return d


## 개발/시연용 상태 프리셋을 적용하고 저장한다(디버그 키 전용 — release 미노출).
## build_state 로 상태만 조립한다(게임 로직과 분리). 이름에 "demo" 를 쓰지 않는다.
func apply_dev_preset(preset: String) -> void:
  var opts := {}
  match preset:
    "comfy_edge":
      # 반말 전환(편해진 사이, REL_COMFY) 직전 — 다음 입장 한 번의 교감으로 반말 컷인이 터지게.
      # announced=regular 라 단골 인사는 건너뛰고 comfy(반말) 연출만 남긴다. 온보딩 끝, 샘플 닉.
      opts = {
        "nickname": "지은",
        "onboarded": true,
        "announced_stage": "regular",
        "okja_affinity": Balance.REL_COMFY - 1,
      }
    "regular_edge":
      # 단골(REL_REGULAR) 직전 — 한 번의 교감으로 단골 등극, 다음 입장에 단골 인사 비트가 터지게.
      # announced=guest 라 손님→단골 알림이 살아있다(comfy_edge 와 대칭인 '단골 직전' 데모/픽스처).
      opts = {
        "nickname": "지은",
        "onboarded": true,
        "announced_stage": "guest",
        "okja_affinity": Balance.REL_REGULAR - 1,
      }
    _:
      push_warning("[Save] 알 수 없는 dev preset: %s → 기본값" % preset)
  data = build_state(opts)
  save_game()


## 세이브 파일 자체를 삭제하고 메모리도 기본값으로 되돌린다(완전 초기화).
func wipe() -> void:
  if FileAccess.file_exists(SAVE_PATH):
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
  data = default_save()


# ── 헬퍼: 점 경로 접근 (예: get_value("okja.gauge")) ─────────────
## "a.b.c" 경로로 중첩 dict 값을 읽는다. 없으면 default 반환.
func get_value(path: String, default_value: Variant = null) -> Variant:
  var node: Variant = data
  for key in path.split("."):
    if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has(key):
      return default_value
    node = (node as Dictionary)[key]
  return node


## "a.b.c" 경로에 값을 쓴다. 중간 dict 가 없으면 만든다. (자동 저장은 하지 않음)
func set_value(path: String, value: Variant) -> void:
  var keys := path.split(".")
  var node: Dictionary = data
  for i in range(keys.size() - 1):
    var key := keys[i]
    if typeof(node.get(key)) != TYPE_DICTIONARY:
      node[key] = {}
    node = node[key]
  node[keys[keys.size() - 1]] = value


# ── 내부 ─────────────────────────────────────────────────────

## 구버전 세이브를 최신 스키마로 끌어올린다 (골격 — 버전 오를 때 분기 추가).
func _migrate(loaded_data: Dictionary) -> Dictionary:
  var v := int(loaded_data.get("version", 0))
  if v == SAVE_VERSION:
    return loaded_data
  # v1 이하(캐릭터 레지스트리 도입 전) → 클린 리셋. (미호 슬라이스 #2 합의 2026-06-07)
  #   active_main·캐릭터 id-맵 도입으로 구 스키마와 비호환이라 새 게임으로 시작한다.
  push_warning("[Save] 세이브 v%d → v%d: 캐릭터 레지스트리 도입으로 클린 리셋" % [v, SAVE_VERSION])
  return default_save()


## 로드한 세이브에 빠진 키를 기본값으로 채워 넣는다(앱 업데이트로 키가 늘어난 경우 대비).
## dict 는 재귀적으로 병합, 그 외 타입은 기존 값을 보존한다.
func _merge_defaults(target: Dictionary, defaults: Dictionary) -> Dictionary:
  for key in defaults:
    if not target.has(key):
      target[key] = defaults[key]
    elif typeof(defaults[key]) == TYPE_DICTIONARY and typeof(target[key]) == TYPE_DICTIONARY:
      target[key] = _merge_defaults(target[key], defaults[key])
  return target


## 로드한 값의 타입을 기본 스키마에 맞춰 보정한다.
## Godot JSON 은 모든 수를 float 로 파싱하므로, 스키마가 int 인 필드(코인·게이지·호감도 등)가
## 50.0 처럼 깨지는 것을 막는다. (스키마에 없는 동적 키는 후속 태스크에서 별도 처리)
func _coerce_types(target: Dictionary, defaults: Dictionary) -> Dictionary:
  for key in defaults:
    if not target.has(key):
      continue
    var dv: Variant = defaults[key]
    var tv: Variant = target[key]
    if typeof(dv) == TYPE_DICTIONARY and typeof(tv) == TYPE_DICTIONARY:
      _coerce_types(tv, dv)
    elif typeof(dv) == TYPE_INT and typeof(tv) == TYPE_FLOAT:
      target[key] = int(tv)
    elif typeof(dv) == TYPE_FLOAT and typeof(tv) == TYPE_INT:
      target[key] = float(tv)
  return target
