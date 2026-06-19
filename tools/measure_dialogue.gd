extends SceneTree
## 대사 잘림 진단기 — 실제 Galmuri11 폰트로 모든 대사의 렌더 폭/줄수를 측정해
## UI 한계를 넘는(=잘리는) 줄을 찾아낸다. (일회성 도구)
##
##   godot --headless --path . --script res://tools/measure_dialogue.gd
##
## 측정 대상:
##  - 티커(단일 줄, 잘림): ticker.json 전 줄 + talk/gifts 의 reply
##  - 대화 프롬프트(자동 2줄): talk/gifts prompt
##  - 선택 버튼(단일 줄): talk choices label
##  - 컷인(다중 줄): *_cutin lines/reveal

const FONT := "res://assets/fonts/Galmuri11.ttf"

# UI 상수(렌더 코드와 동일)
const TICKER_W := 317      # ticker.gd: LCD_W(333) - 16
const TICKER_FS := 14      # Fonts.SIZE_LEAD
const PROMPT_W := 273      # choice_popup: PANEL_W(301) - PAD(14)*2
const PROMPT_FS := 14      # Fonts.SIZE_LEAD
const PROMPT_MAX_LINES := 2
const BTN_W := 273         # choice_popup: 버튼 폭(대화는 아이콘 없음)
const BTN_FS := 15         # Fonts.SIZE_CHOICE
const CUTIN_W := 277       # stage_cutin: pw(297) - 20
const CUTIN_FS := 11       # Fonts.SIZE_BODY
const CUTIN_MAX_LINES := 3

var _font: FontFile
var _nicks := ["여섯글자닉넴"]  # 6자(최대 NICK_MAX) — 최악 폭 1회만 측정
var _overflow := 0
var _checked := 0


func _init() -> void:
  _font = load(FONT) as FontFile
  if _font == null:
    push_error("폰트 로드 실패: %s" % FONT)
    quit(2)
    return

  print("════════ 대사 잘림 진단 (Galmuri11) ════════\n")

  _check_ticker()
  _check_talk()
  _check_gifts()
  _check_cutin()

  print("\n════════ 요약 ════════")
  print("검사 %d건 중 잘림 %d건" % [_checked, _overflow])
  quit(0 if _overflow == 0 else 1)


# ── 측정 헬퍼 ─────────────────────────────────────────────

func _w(text: String, fs: int) -> float:
  return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

func _line_h(fs: int) -> float:
  return _font.get_string_size("가", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).y

func _wrap_lines(text: String, fs: int, w: int) -> int:
  var total := _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y
  return int(round(total / _line_h(fs)))

func _load_json(path: String) -> Dictionary:
  var f := FileAccess.open(path, FileAccess.READ)
  if f == null:
    push_error("JSON 못 엶: %s" % path)
    return {}
  return JSON.parse_string(f.get_as_text())

func _sub(text: String, nick: String) -> String:
  return text.replace("{nick}", nick)

## 단일 줄(티커/버튼) 폭 검사. {nick} 있으면 닉 길이별로, 없으면 1회.
func _check_single(tag: String, text: String, fs: int, w: int) -> void:
  if text.is_empty():
    return
  var has_nick := text.contains("{nick}")
  var nicks := _nicks if has_nick else ["손님"]
  for nk in nicks:
    _checked += 1
    var s := _sub(text, nk) if has_nick else text
    var pw := _w(s, fs)
    if pw > w:
      _overflow += 1
      var over := int(pw - w)
      var label := "[%s] (+%dpx)" % [tag, over]
      if has_nick:
        label += " nick=%d자" % nk.length()
      print("✂ %s\n   「%s」" % [label, s])

## 다중 줄(프롬프트/컷인) 줄수 검사.
func _check_multi(tag: String, text: String, fs: int, w: int, max_lines: int) -> void:
  if text.is_empty():
    return
  var has_nick := text.contains("{nick}")
  var nicks := _nicks if has_nick else ["손님"]
  for nk in nicks:
    _checked += 1
    var s := _sub(text, nk) if has_nick else text
    var lines := _wrap_lines(s, fs, w)
    if lines > max_lines:
      _overflow += 1
      var label := "[%s] (%d줄 > %d)" % [tag, lines, max_lines]
      if has_nick:
        label += " nick=%d자" % nk.length()
      print("✂ %s\n   「%s」" % [label, s])


# ── 검사 루틴 ─────────────────────────────────────────────

func _check_ticker() -> void:
  print("── 티커(단일 줄, 폭 %d) ──" % TICKER_W)
  var db := _load_json("res://data/ticker.json")
  for key in db:
    if String(key).begins_with("_"):
      continue
    var node = db[key]
    if String(key).ends_with("_cutin"):
      continue  # 컷인은 별도 검사
    _walk_ticker(String(key), node)

func _walk_ticker(prefix: String, node) -> void:
  if node is Array:
    for ln in node:
      if ln is String:
        _check_single("ticker:%s" % prefix, ln, TICKER_FS, TICKER_W)
  elif node is Dictionary:
    for k in node:
      _walk_ticker("%s/%s" % [prefix, k], node[k])

func _check_talk() -> void:
  print("\n── 대화: 프롬프트(2줄)·버튼(단일)·reply(티커) ──")
  var db := _load_json("res://data/talk.json")
  for key in db:
    if String(key).begins_with("_"):
      continue
    var section = db[key]
    var who := String(key)
    # 옥자=평면(guest/regular 가 루트), 캐릭터=하위
    if section is Array:
      _walk_talk_pool(who, section)
    elif section is Dictionary:
      for sk in section:
        if section[sk] is Array:
          _walk_talk_pool(who, section[sk])

func _walk_talk_pool(who: String, pool: Array) -> void:
  for topic in pool:
    if not (topic is Dictionary):
      continue
    _check_multi("prompt:%s" % who, String(topic.get("prompt", "")), PROMPT_FS, PROMPT_W, PROMPT_MAX_LINES)
    for c in topic.get("choices", []):
      _check_single("label:%s" % who, String(c.get("label", "")), BTN_FS, BTN_W)
      _check_single("reply:%s" % who, String(c.get("reply", "")), TICKER_FS, TICKER_W)

func _check_gifts() -> void:
  print("\n── 선물: prompt(2줄)·reply(티커) ──")
  var db := _load_json("res://data/gifts.json")
  for key in db:
    if String(key).begins_with("_"):
      continue
    var who := String(key)
    if who == "prompt" or who == "gifts":
      _walk_gift_section("okja", db)  # 옥자 평면 — 1회만
      break
  # 캐릭터 하위
  for key in db:
    if String(key).begins_with("_") or key == "prompt" or key == "gifts":
      continue
    if db[key] is Dictionary:
      _walk_gift_section(String(key), db[key])

func _walk_gift_section(who: String, sec: Dictionary) -> void:
  var prompts = sec.get("prompt", {})
  if prompts is Dictionary:
    for sk in prompts:
      _check_multi("giftprompt:%s" % who, String(prompts[sk]), PROMPT_FS, PROMPT_W, PROMPT_MAX_LINES)
  for g in sec.get("gifts", []):
    var reply = g.get("reply", "")
    if reply is Dictionary:
      for sk in reply:
        _check_single("giftreply:%s" % who, String(reply[sk]), TICKER_FS, TICKER_W)
    elif reply is String:
      _check_single("giftreply:%s" % who, reply, TICKER_FS, TICKER_W)

func _check_cutin() -> void:
  print("\n── 컷인(다중 줄, 폭 %d, ≤%d줄) ──" % [CUTIN_W, CUTIN_MAX_LINES])
  var db := _load_json("res://data/ticker.json")
  for key in db:
    if not String(key).ends_with("_cutin"):
      continue
    var who := String(key)
    for stage in db[key]:
      var data = db[key][stage]
      if not (data is Dictionary):
        continue
      for ln in data.get("lines", []):
        _check_multi("cutin:%s/%s" % [who, stage], String(ln.get("text", "")), CUTIN_FS, CUTIN_W, CUTIN_MAX_LINES)
      _check_multi("reveal:%s/%s" % [who, stage], String(data.get("reveal", "")), CUTIN_FS, CUTIN_W, CUTIN_MAX_LINES)
