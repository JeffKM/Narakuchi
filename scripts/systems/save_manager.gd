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
const SAVE_VERSION := 1  # 스키마 버전 (마이그레이션 분기용)

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
  return {
    "version": SAVE_VERSION,
    "player": {
      "nickname": "",        # 온보딩에서 입력 (T06b)
      "coins": 0,
    },
    "stamina": Balance.STAMINA_MAX,  # 옥자/시온이 공유, 매일 풀 충전
    # 옥자: 메인 교감·수집 캐릭터
    "okja": {
      "affinity_total": 0,   # 누적 호감도 (관계 단계 판정용)
      "gauge": 0,            # 현재 호감도 게이지 (가득 → 체키 1장)
      "mood": "happy",       # happy | normal | sulky
    },
    # 시온이: 교감 가능한 펫 (옥자와 같은 시스템 복제)
    "sion": {
      "affinity_total": 0,
      "gauge": 0,
    },
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
    "flags": {},
    "last_saved_unix": 0,    # 마지막 저장 시각 (epoch sec) — 기분 경과시간 계산용
  }


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
  data["last_saved_unix"] = int(Time.get_unix_time_from_system())

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


## 세이브 초기화. seed_demo=true 면 데모 시연용 시드(반말 전환 직전)로 채운다.
func reset(seed_demo: bool = false) -> void:
  data = default_save()
  if seed_demo:
    _apply_demo_seed()
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

## 데모 시연 시드: 누적 옥자 호감도를 반말 전환(600) 직전인 ~560으로 채운다.
## 첫 세션 한 번의 교감으로 '반말 전환 컷인'이 터지게 하는 연출 장치 (PRD §4.5).
## 온보딩은 끝난 단골 직전 상태이므로 onboarded=true 로 둬 바로 교감 화면으로 진입한다.
func _apply_demo_seed() -> void:
  data["okja"]["affinity_total"] = Balance.DEMO_SEED_AFFINITY
  data["player"]["nickname"] = "지은"  # 시연용 샘플 닉(체키 표지·반말 전환에 이름이 보이게)
  data["flags"]["onboarded"] = true


## 구버전 세이브를 최신 스키마로 끌어올린다 (골격 — 버전 오를 때 분기 추가).
func _migrate(loaded_data: Dictionary) -> Dictionary:
  var v := int(loaded_data.get("version", 0))
  if v == SAVE_VERSION:
    return loaded_data
  # 예시: v0 → v1 마이그레이션은 여기에. 현재는 버전만 갱신.
  push_warning("[Save] 세이브 버전 %d → %d 마이그레이션" % [v, SAVE_VERSION])
  loaded_data["version"] = SAVE_VERSION
  return loaded_data


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
