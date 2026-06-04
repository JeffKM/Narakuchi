class_name Onboarding
extends Node2D
## 온보딩 (T06b) — 첫 접속 1회. (→ PRD §6, §4.5)
##   1) 닉네임 입력 → 옥자가 그 이름을 불러줌(몰입)
##   2) 옥자 존댓말 맞이 + 첫 방문 기념 지뢰계 일반체키 증정
## 끝나면 finished 신호 → Main 이 오버레이를 걷고 Cafe.start() 호출.
##
## flags.onboarded 로 1회만 뜬다(분기는 Main). 셸 OK 로도 진행 가능(터치 하이브리드).

signal finished

const LCD_W := 333
const LCD_H := 480
const NICK_MAX := 8
const NICK_DEFAULT := "손님"

var _step := 0  # 0=닉네임 입력, 1=맞이/증정
var _title: Label
var _body: Label
var _nick_edit: LineEdit
var _confirm: Button
var _nick := ""


func _ready() -> void:
  # 화면 전체를 덮는 어두운 패널 (뒤 Cafe 입력 차단)
  var bg := ColorRect.new()
  bg.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.94)
  bg.position = Vector2.ZERO
  bg.size = Vector2(LCD_W, LCD_H)
  add_child(bg)

  _title = _make_label("나라카에 오신 걸\n환영해요", 120, Fonts.SIZE_TITLE, Palette.CANDLE)
  add_child(_title)

  _body = _make_label("당신을 뭐라고 부를까요?", 196, Fonts.SIZE_BODY, Palette.CREAM)
  add_child(_body)

  _nick_edit = LineEdit.new()
  _nick_edit.placeholder_text = "닉네임"
  _nick_edit.max_length = NICK_MAX
  _nick_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
  _nick_edit.position = Vector2((LCD_W - 180) / 2, 230)
  _nick_edit.size = Vector2(180, 34)
  _nick_edit.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  _nick_edit.text_submitted.connect(func(_t): _advance())  # 엔터로 제출
  add_child(_nick_edit)

  _confirm = Button.new()
  _confirm.text = "들어가기"
  _confirm.focus_mode = Control.FOCUS_NONE
  _confirm.position = Vector2((LCD_W - 140) / 2, 300)
  _confirm.size = Vector2(140, 40)
  _confirm.add_theme_font_size_override("font_size", Fonts.SIZE_BODY)
  _confirm.pressed.connect(_advance)
  add_child(_confirm)

  _nick_edit.grab_focus()


## 셸 OK → 진행 (SELECT/CANCEL 은 온보딩에선 무시).
func handle_shell_action(action: StringName) -> void:
  if action == &"ok":
    _advance()


# ── 진행 ─────────────────────────────────────────────────

func _advance() -> void:
  if _step == 0:
    _submit_nickname()
  else:
    finished.emit()


## 닉네임 확정 → 저장 + 첫 체키 증정 → 맞이 화면으로.
func _submit_nickname() -> void:
  _nick = _nick_edit.text.strip_edges()
  if _nick.is_empty():
    _nick = NICK_DEFAULT
  SaveManager.set_value("player.nickname", _nick)
  _grant_first_cheki()
  SaveManager.set_value("flags.onboarded", true)
  SaveManager.save_game()

  # 입력 UI 숨기고 맞이 메시지로 전환
  _nick_edit.hide()
  _step = 1
  _title.text = "어서 오세요,\n%s님" % _nick
  _body.text = "첫 방문 기념이에요.\n지뢰계 체키를 드릴게요.\n\n(소중히 간직하세요)"
  _confirm.text = "시작하기"


## 첫 방문 기념: 지뢰계(★히어로) 일반체키 1장. (체키 모델 본격화는 T12)
func _grant_first_cheki() -> void:
  var key := Events.cheki_key(Events.OKJA, Events.FIRST_GIFT_EVENT)
  var cheki: Dictionary = SaveManager.get_value("cheki", {})
  cheki[key] = {"common": 1, "butterfly": false, "shards": 0}
  SaveManager.set_value("cheki", cheki)


## 가운데 정렬 + 외곽선 라벨 헬퍼.
func _make_label(text: String, y: int, size: int, color: Color) -> Label:
  var lb := Label.new()
  lb.text = text
  lb.position = Vector2(16, y)
  lb.size = Vector2(LCD_W - 32, 0)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  lb.add_theme_font_size_override("font_size", size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 4)
  lb.add_theme_constant_override("line_spacing", 4)
  return lb
