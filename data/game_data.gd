class_name GameData
extends RefCounted
## 콘텐츠 JSON 단일 로더 — res://data/*.json 를 1회 로드해 정적 캐시한다.
## content_studio(GUI 툴)가 같은 JSON 을 편집한다 → 게임/툴 단일 출처.
##
## dialogue.gd(티커·대화·선물) / action_bar.gd·cafe.gd(버튼·감정) 가 여기서 읽는다.
## 정적 캐시라 첫 접근에만 파일을 읽고, 이후엔 메모리에서 즉시 돌려준다.
## (런타임 편집은 없으므로 reload 는 디버그용으로만 둔다.)
##
## ⚠️ JSON 의 "_doc"/"_*_doc" 키는 사람용 주석 — 코드는 무시한다.

const TICKER_PATH := "res://data/ticker.json"
const TALK_PATH := "res://data/talk.json"
const GIFTS_PATH := "res://data/gifts.json"
const BUTTONS_PATH := "res://data/buttons.json"

static var _ticker: Dictionary
static var _talk: Dictionary
static var _gifts: Dictionary
static var _buttons: Dictionary


## 티커 풀 { okja:{상황:{guest,regular}}, sion:{버튼키:[...]} }.
static func ticker() -> Dictionary:
  if _ticker.is_empty():
    _ticker = _load_dict(TICKER_PATH)
  return _ticker


## 대화 토막 { guest:[토막...], regular:[토막...] }.
static func talk() -> Dictionary:
  if _talk.is_empty():
    _talk = _load_dict(TALK_PATH)
  return _talk


## 선물 { prompt:{guest,regular}, gifts:[...] }.
static func gifts() -> Dictionary:
  if _gifts.is_empty():
    _gifts = _load_dict(GIFTS_PATH)
  return _gifts


## 버튼/감정 { okja:{actions,emotion}, sion:{actions} }.
static func buttons() -> Dictionary:
  if _buttons.is_empty():
    _buttons = _load_dict(BUTTONS_PATH)
  return _buttons


## 캐시 비우기(디버그 — 다음 접근에 다시 읽음).
static func reload() -> void:
  _ticker = {}
  _talk = {}
  _gifts = {}
  _buttons = {}


## JSON 파일 한 장을 Dictionary 로 읽는다. 실패 시 빈 사전 + 에러 로그(게임은 멈추지 않음).
static func _load_dict(path: String) -> Dictionary:
  if not FileAccess.file_exists(path):
    push_error("[GameData] 파일 없음: %s" % path)
    return {}
  var f := FileAccess.open(path, FileAccess.READ)
  if f == null:
    push_error("[GameData] 열기 실패: %s (%d)" % [path, FileAccess.get_open_error()])
    return {}
  var txt := f.get_as_text()
  f.close()
  var parsed: Variant = JSON.parse_string(txt)
  if typeof(parsed) != TYPE_DICTIONARY:
    push_error("[GameData] JSON 파싱 실패(사전 아님): %s" % path)
    return {}
  return parsed
