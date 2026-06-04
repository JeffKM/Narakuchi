extends Node2D
## 나라카찌 부트스트랩 — 게임기 셸 + 옥자 스탠딩 + 표정 스왑 시연. (→ ADR 0001 / ROADMAP T07)
## 셸(ShellFrame) LCD 안에 나라카 배경 + 라이브 옥자를 올리고,
##   SELECT(표정 순환) · OK(폴짝/리워드) · CANCEL(기본으로) 으로 표정 스왑 트윈을 보인다.
## 실제 교감 루프(온보딩 → 4버튼 교감 → 컬렉션북 → 공유)는 ROADMAP T06a~ 에서 구현.
## 팔레트: data/palette.gd · 폰트: scripts/systems/fonts.gd · 셸: scripts/systems/shell.gd · 옥자: scripts/okja.gd

# 내부 화면 = 셸 LCD 구멍 크기 (ShellFrame.LCD_SIZE 와 일치)
const LCD_W := 333
const LCD_H := 480

const BG_TEX := "res://assets/sprites/bg_naraka.png"
const OkjaScript := preload("res://scripts/okja.gd")

# 표정 순환 목록 (영문 키 = 에셋/상태, 라벨 = 표시용)
const EXPR_ORDER: Array[StringName] = [&"idle", &"smile", &"shy", &"sad", &"brew", &"talk"]
const EXPR_LABEL := {
  &"idle": "기본", &"smile": "웃음", &"shy": "부끄",
  &"sad": "시무룩", &"brew": "제조", &"talk": "말하기",
}

var _okja: Node2D
var _expr_idx := 0

var _status: Label  # 현재 표정 표시
var _dbg: Label     # 마지막 입력


func _ready() -> void:
  # 갈무리 폰트가 있으면 전역 기본 테마로 적용 (없으면 엔진 기본 폰트)
  get_window().theme = Fonts.make_theme()
  # 셸 바깥 여백은 투명 — 웹/창 배경이 비치게 (per_pixel_transparency 허용됨)
  get_window().transparent_bg = true

  # 셸을 띄우고 LCD 안에 배경 + 옥자를 붙인다
  var shell := ShellFrame.new()
  add_child(shell)
  shell.button_pressed.connect(_on_shell_button)
  _build_lcd(shell.lcd_root, Fonts.has_galmuri())
  _refresh()


## LCD(333×480) 안에 배경 → 옥자 → UI 라벨 순으로 쌓는다(뒤→앞).
func _build_lcd(root: Node2D, kr: bool) -> void:
  # 1) 나라카 지옥 배경 (LCD 꽉 — 333×480)
  var bg := Sprite2D.new()
  bg.texture = load(BG_TEX)
  bg.centered = false
  bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  root.add_child(bg)

  # 2) 라이브 옥자 — 통로 바닥 중앙(발밑 기준 배치)
  _okja = OkjaScript.new()
  _okja.position = Vector2(LCD_W / 2.0, 452)
  root.add_child(_okja)

  # 3) 상단 상태 줄(현재 표정) + 하단 조작 힌트 (옥자 위에 얹음)
  _status = _make_label("", 14, Fonts.SIZE_BODY, Palette.CANDLE)
  root.add_child(_status)

  root.add_child(_make_label(
    ("SELECT 표정 · OK 폴짝 · CANCEL 기본" if kr
      else "SELECT expr / OK hop / CANCEL idle"),
    452, Fonts.SIZE_SMALL, Palette.GREY_300))

  _dbg = _make_label(
    ("마지막 입력: -" if kr else "last input: -"),
    458, Fonts.SIZE_SMALL, Palette.GREY_400)
  _dbg.position.y = LCD_H - 18
  root.add_child(_dbg)


## 가로 중앙 정렬 라벨 헬퍼 (LCD 로컬 좌표).
func _make_label(text: String, y: int, size: int, color: Color) -> Label:
  var lb := Label.new()
  lb.text = text
  lb.position = Vector2(0, y)
  lb.size = Vector2(LCD_W, size + 6)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.add_theme_font_size_override("font_size", size)
  lb.add_theme_color_override("font_color", color)
  # 어두운 배경 위 가독성 — 외곽선 살짝
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 4)
  return lb


## 셸 버튼 입력 → 옥자 표정 스왑 시연
func _on_shell_button(action: StringName) -> void:
  match action:
    &"select":
      _expr_idx = (_expr_idx + 1) % EXPR_ORDER.size()
      _okja.set_expression(EXPR_ORDER[_expr_idx])
    &"ok":
      _okja.hop()  # 리워드 폴짝 (smile 재사용)
      _expr_idx = EXPR_ORDER.find(&"smile")
    &"cancel":
      _expr_idx = 0
      _okja.set_expression(&"idle")
  _dbg.text = "마지막 입력: %s" % String(action).to_upper()
  _refresh()


## 현재 표정을 상단 상태 줄에 반영
func _refresh() -> void:
  var key := EXPR_ORDER[_expr_idx]
  _status.text = "옥자 — %s" % EXPR_LABEL.get(key, String(key))
