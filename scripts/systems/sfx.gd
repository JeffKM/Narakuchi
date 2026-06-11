extends Node
## 효과음 시스템 — 이벤트 바인딩 디스패처. (→ ADR 0004 / PRD §10)
##
## 게임은 **의미 이벤트**만 발화한다: `Sfx.event(&"okja_touch")`.
## 바인딩(이벤트→파일·피치·지터·카테고리)은 `data/sound.json`(GameData.sound() 게이트웨이)에서 읽는다.
## 콘텐츠 스튜디오가 같은 JSON 을 편집한다 → 게임/툴 단일 출처(밸런스·대사와 동형).
##
## 해소 순서: events[id].file → 없으면 defaults[cat] → 그래도 없으면 무음(no-op, "사운드 자리" 관용).
## 음높이 = pitch × (1 + 지터). 음량 = 카테고리 gain(dB). flags.sfx_on=false 면 전역 음소거.
##
## AudioStreamPlayer 풀을 기본 Master 버스로 직접 출력한다(런타임 add_bus 는 web 에서 무음 → 사용 안 함).
## 오토로드 "Sfx" (project.godot). 일시정지/오버레이 중에도 울리게 PROCESS_MODE_ALWAYS.

const AUDIO_DIR := "res://assets/audio/"
const VOICES := 6          # 동시 발화 풀(빠른 연속 큐 겹침 허용)

var _players: Array[AudioStreamPlayer] = []
var _cache := {}           # path → AudioStream (null 도 캐시 — 반복 exists 체크 회피)
var _next := 0


func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS  # 오버레이/일시정지 중에도 울림
  # web(HTML5)에서 런타임 add_bus → set_bus_send("Master") 라우팅이 무음을 유발(네이티브는 정상).
  # 그래서 별도 SFX 버스를 두지 않고 AudioStreamPlayer 를 기본 Master 버스로 직접 출력한다.
  for _i in VOICES:
    var p := AudioStreamPlayer.new()
    add_child(p)
    _players.append(p)
  # 저장된 마스터 음량을 부팅 시 1회 적용(설정 패널 변경 시에도 apply_volume 으로 재적용).
  apply_volume(float(SaveManager.get_value("flags.volume", 1.0)))


## 마스터 음량 적용 — 선형 0.0~1.0 을 dB 로 환산해 기본 Master 버스(인덱스 0)에 건다.
## Master 는 런타임 추가 버스가 아니라 web 무음 함정과 무관(→ ADR 0004). 0 이면 -80dB(사실상 무음).
## 음소거(flags.sfx_on)와 독립 — 음소거 해제 시 이 음량으로 복원된다.
func apply_volume(linear: float) -> void:
  var v := clampf(linear, 0.0, 1.0)
  var db := linear_to_db(v) if v > 0.0 else -80.0
  AudioServer.set_bus_volume_db(0, db)


## 이벤트 발화. 바인딩이 없거나 파일이 아직 없으면 조용히 무시(no-op).
## pitch_override > 0 이면 데이터 pitch 대신 그 값을 쓴다(특수 연출용).
func event(id: StringName, pitch_override := 0.0) -> void:
  if not _enabled():
    return
  var bind := _binding_for(id)
  if bind.is_empty():
    return
  var stream := _stream_for(String(bind["file"]))
  if stream == null:
    return
  var p := _players[_next]
  _next = (_next + 1) % _players.size()
  p.stream = stream
  var base_pitch: float = pitch_override if pitch_override > 0.0 else float(bind["pitch"])
  var jit: float = float(bind["jitter"])
  p.pitch_scale = maxf(0.05, base_pitch + (randf_range(-jit, jit) if jit > 0.0 else 0.0))
  p.volume_db = float(bind["gain"])
  p.play()


# ── 내부 ─────────────────────────────────────────────────

## 플레이어 SFX on/off (셸 토글 → flags.sfx_on, 기본 on).
func _enabled() -> bool:
  return bool(SaveManager.get_value("flags.sfx_on", true))


## 이벤트 id → 해소된 바인딩 { file, pitch, jitter, gain }. 없으면 빈 사전.
## file 은 events[id].file → 없으면 defaults[cat] → 둘 다 없으면 빈 사전(무음).
func _binding_for(id: StringName) -> Dictionary:
  var snd := GameData.sound()
  var events: Dictionary = snd.get("events", {})
  if not events.has(id):
    return {}
  var e: Dictionary = events[id]
  if bool(e.get("mute", false)):  # 스튜디오 음소거 토글 → 강제 무음 (→ ADR 0004)
    return {}
  var cat := String(e.get("cat", ""))
  var file := String(e.get("file", ""))
  if file.is_empty():
    var defaults: Dictionary = snd.get("defaults", {})
    file = String(defaults.get(cat, "")) if defaults.get(cat) != null else ""
  if file.is_empty():
    return {}
  var gains: Dictionary = snd.get("gain", {})
  return {
    "file": file,
    "pitch": float(e.get("pitch", 1.0)),
    "jitter": float(e.get("jitter", 0.0)),
    "gain": float(gains.get(cat, 0.0)),
  }


## 파일명의 스트림(없으면 null). 경로별 1회 로드 후 캐시.
func _stream_for(file: String) -> AudioStream:
  var path := AUDIO_DIR + file
  if _cache.has(path):
    return _cache[path]
  var s: AudioStream = null
  if ResourceLoader.exists(path):
    s = load(path) as AudioStream
  _cache[path] = s
  return s
