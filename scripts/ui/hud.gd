class_name Hud
extends Node2D
## 상단 HUD (T06a + T08 표시) — 호감도 게이지 · 기분 · 스태미나 · 코인.
## SaveManager.data 를 읽어 표시만 한다(미터 변경은 Meters 가 담당).
## 수치 최대값은 Balance 에서.

const LCD_W := 333

# 호감도 게이지 바 규격 (상단 중앙)
const GAUGE_W := 240
const GAUGE_H := 12
const GAUGE_X := (LCD_W - GAUGE_W) / 2
const GAUGE_Y := 8

const MOOD_LABEL := {
  Meters.MOOD_HAPPY: "기분 좋음",
  Meters.MOOD_NORMAL: "기분 보통",
  Meters.MOOD_SULKY: "시무룩",
}

var _gauge_fill: ColorRect
var _gauge_text: Label
var _info: Label  # 기분 · 기력 · 코인 한 줄
var _attend: Label  # 출석 진행 한 줄 (T14 — 캐릭터 무관, 항상 표시)
var _focus: String = "okja"  # 현재 게이지 표시 대상 (okja | sion). T15 시온이 모드에서 전환.


func _ready() -> void:
  # ── 호감도 게이지 (배경 트랙 + 채움 + 텍스트) ──
  var track := ColorRect.new()
  track.color = Palette.GREY_900
  track.position = Vector2(GAUGE_X, GAUGE_Y)
  track.size = Vector2(GAUGE_W, GAUGE_H)
  track.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(track)

  _gauge_fill = ColorRect.new()
  _gauge_fill.color = Palette.BLOOD  # 나라카 시그니처 레드
  _gauge_fill.position = Vector2(GAUGE_X, GAUGE_Y)
  _gauge_fill.size = Vector2(0, GAUGE_H)
  _gauge_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_gauge_fill)

  # 골드 테두리 (StyleBox Panel 오버레이)
  var border := Panel.new()
  border.position = Vector2(GAUGE_X, GAUGE_Y)
  border.size = Vector2(GAUGE_W, GAUGE_H)
  border.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(0, 0, 0, 0)
  sb.set_border_width_all(1)
  sb.border_color = Palette.GOLD
  border.add_theme_stylebox_override("panel", sb)
  add_child(border)

  _gauge_text = _make_label(GAUGE_X, GAUGE_Y - 1, GAUGE_W, Fonts.SIZE_SMALL,
    Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
  add_child(_gauge_text)

  # ── 기분 · 기력 · 코인 한 줄 ──
  _info = _make_label(8, GAUGE_Y + GAUGE_H + 3, LCD_W - 16, Fonts.SIZE_SMALL,
    Palette.GREY_200, HORIZONTAL_ALIGNMENT_CENTER)
  add_child(_info)

  # ── 출석 진행 한 줄 (T14) — 정보 라인 아래, 캔들색으로 살짝 구분 ──
  _attend = _make_label(8, GAUGE_Y + GAUGE_H + 3 + 15, LCD_W - 16, Fonts.SIZE_SMALL,
    Palette.CANDLE, HORIZONTAL_ALIGNMENT_CENTER)
  add_child(_attend)


## 게이지 표시 대상을 바꾼다(okja | sion). T15 시온이 모드 전환에서 호출.
func set_focus(character: String) -> void:
  _focus = character
  refresh()


## 세이브에서 현재 수치를 읽어 표시를 갱신한다. (Meters.changed 에 연결)
func refresh() -> void:
  var stamina := int(SaveManager.get_value("stamina", 0))
  var coins := int(SaveManager.get_value("player.coins", 0))

  # 출석 진행 — 캐릭터 무관, 옥자/시온이 모드 공통. (컬렉션북 푸터와 같은 Meters 헬퍼)
  _refresh_attendance()

  if _focus == "sion":
    # 시온이: 게이지만(펫이라 기분·관계 단계 없음)
    var sg := int(SaveManager.get_value("sion.gauge", 0))
    var sr := clampf(float(sg) / float(Balance.GAUGE_SION), 0.0, 1.0)
    _gauge_fill.size.x = round(GAUGE_W * sr)
    _gauge_text.text = "시온이 호감도 %d/%d" % [sg, Balance.GAUGE_SION]
    _info.text = "기력 %d/%d   코인 %d" % [stamina, Balance.STAMINA_MAX, coins]
    return

  # 옥자: 게이지 + 기분
  var gauge := int(SaveManager.get_value("okja.gauge", 0))
  var ratio := clampf(float(gauge) / float(Balance.GAUGE_OKJA), 0.0, 1.0)
  _gauge_fill.size.x = round(GAUGE_W * ratio)
  _gauge_text.text = "옥자 호감도 %d/%d" % [gauge, Balance.GAUGE_OKJA]

  var mood := String(SaveManager.get_value("okja.mood", Meters.MOOD_HAPPY))
  _info.text = "%s   기력 %d/%d   코인 %d" % [
    MOOD_LABEL.get(mood, mood), stamina, Balance.STAMINA_MAX, coins]


## 출석 진행 한 줄 갱신 (T14) — "출석 N일 · 다음 보상까지 D일" / 다 받았으면 "보상 다 모음".
## 컬렉션북 푸터와 동일한 Meters.attendance_status() 단일 출처.
func _refresh_attendance() -> void:
  if _attend == null:
    return
  var st := Meters.attendance_status()
  var streak := int(st["streak"])
  if int(st["next"]) > 0:
    _attend.text = "출석 %d일 · 다음 보상까지 %d일" % [streak, int(st["remaining"])]
  else:
    _attend.text = "출석 %d일 · 출석 보상 다 모음" % streak


## 외곽선 두른 라벨 헬퍼 (어두운 배경 가독성).
func _make_label(x: int, y: int, w: int, size: int, color: Color, align: int) -> Label:
  var lb := Label.new()
  lb.position = Vector2(x, y)
  lb.size = Vector2(w, size + 6)
  lb.horizontal_alignment = align
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  lb.add_theme_font_size_override("font_size", size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  return lb
