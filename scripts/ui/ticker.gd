class_name Ticker
extends Node2D
## 한 줄 티커 (T06a) — 화면 맨 아래 옥자/시온이 보이스 한 줄. (→ PRD §4.3)
## 표정 9할·대사 한 줄 원칙: 상시 대화창 대신 이 한 줄로만 보이스를 보여준다.
## 라인 풀은 data/dialogue.gd. 새 줄이 들어오면 살짝 페이드인.

const LCD_W := 333
const STRIP_H := 22  # 티커 스트립 높이

var _label: Label
var _fade: Tween


func _ready() -> void:
  # 가독성용 반투명 어두운 스트립 (배경 위에 깔림)
  var strip := ColorRect.new()
  strip.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.62)
  strip.position = Vector2(0, 0)
  strip.size = Vector2(LCD_W, STRIP_H)
  strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(strip)

  _label = Label.new()
  _label.position = Vector2(8, 0)
  _label.size = Vector2(LCD_W - 16, STRIP_H)
  _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  _label.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  _label.add_theme_color_override("font_color", Palette.CREAM)
  _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_label)


## 한 줄을 띄운다(짧은 페이드인). 빈 문자열이면 무시.
func show_line(text: String) -> void:
  if text.is_empty():
    return
  _label.text = text
  if _fade and _fade.is_valid():
    _fade.kill()
  _label.modulate.a = 0.0
  _fade = create_tween()
  _fade.tween_property(_label, "modulate:a", 1.0, 0.18)
