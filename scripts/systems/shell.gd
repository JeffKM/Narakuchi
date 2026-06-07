class_name ShellFrame
extends Node2D
## 게임기 셸 — 달걀 바디 + LCD 구멍(333×480) + 3버튼(SELECT/OK/CANCEL). (→ ADR 0001)
## 셸 텍스처가 베이스 캔버스(635×877)를 통째로 채운다(셸 = 화면, 별도 여백 없음).
## LCD 콘텐츠는 외부에서 `lcd_root`(LCD 구멍 333×480 로컬 좌표) 아래에 붙인다.
## LCD 는 333×480 SubViewport 안에서 렌더돼 구멍 경계로 하드 클리핑된다 —
##   디오라마 줌(scale 2x)으로 콘텐츠가 커져도 셸 밖으로 새지 않는다.
## 버튼은 키보드/터치 하이브리드로 받아 `button_pressed(action)` 신호로 통지한다.
##   action: &"select" · &"ok" · &"cancel"

signal button_pressed(action: StringName)

const SHELL_TEX := "res://assets/sprites/shell_frame.png"

# ── 레이아웃 규격 (tools/prep_shell.py 가 레퍼런스에서 계측·출력) ─────────────
# 도트풍 레퍼런스(damagochi_frame.png)를 t=480/LCD높이 로 리샘플 → 캔버스 635×877.
# 내부 화면은 LCD 구멍(333×480)에 꽉 채운다(크롭·여백 없음). (→ ADR 0001)
const CANVAS := Vector2i(635, 877)    # 셸 텍스처 = 캔버스 (셸이 화면 꽉)
const SHELL_POS := Vector2(0, 0)      # 셸 좌상단
const LCD_OFFSET := Vector2(151, 120) # LCD 구멍 좌상단 — 내부 화면 원점
const LCD_SIZE := Vector2(333, 480)   # 내부 화면 = LCD 구멍에 꽉 (크롭 없음)

# 하단 3버튼 (캔버스 좌표 — prep_shell.py 계측)
const BTN_Y := 765
const BTN_W := 83
const BTN_H := 47
const BTN_COLS := {
  &"select": 198,
  &"ok": 317,
  &"cancel": 436,
}

# 코너 스피커 토글(SFX on/off) — LCD 위 우상단 베젤 빈 어깨(계측 근사). (→ ADR 0004)
const SPEAKER_POS := Vector2(426, 56)
const SPEAKER_SIZE := Vector2(48, 42)

# 물리 키 → 액션 매핑 (한 액션에 여러 키)
const KEYMAP := {
  KEY_TAB: &"select", KEY_RIGHT: &"select", KEY_DOWN: &"select",
  KEY_SPACE: &"ok", KEY_ENTER: &"ok", KEY_KP_ENTER: &"ok", KEY_Z: &"ok",
  KEY_ESCAPE: &"cancel", KEY_X: &"cancel", KEY_BACKSPACE: &"cancel",
}

## LCD 콘텐츠를 붙일 루트 (SubViewport 로컬 0,0 원점). _ready 후 사용 가능.
var lcd_root: Node2D

var _lcd_viewport: SubViewport  # LCD 콘텐츠 렌더 타깃 (구멍 333×480 으로 클리핑)
var _flashes := {}  # action -> Panel (눌림 피드백)


func _ready() -> void:
  # ── 1) LCD = SubViewport (구멍 333×480 으로 하드 클리핑, 셸보다 먼저 = 뒤에 깔림) ────
  # 콘텐츠를 333×480 SubViewport 안에서 렌더 → 컨테이너가 LCD 구멍 위치에 1:1 표시.
  # 디오라마 줌(scale 2x)으로 콘텐츠가 커져도 뷰포트 경계에서 잘려 셸 밖으로 새지 않는다.
  # 입력은 SubViewportContainer 가 좌표를 변환해 내부 Control(터치 버튼)로 전달한다.
  var lcd_container := SubViewportContainer.new()
  lcd_container.position = SHELL_POS + LCD_OFFSET
  lcd_container.size = LCD_SIZE
  lcd_container.stretch = false  # 1:1 (정수배·도트 사수 → ADR 0001)
  lcd_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(lcd_container)

  _lcd_viewport = SubViewport.new()
  _lcd_viewport.size = Vector2i(LCD_SIZE)
  _lcd_viewport.transparent_bg = true  # 콘텐츠 없는 부분 = 셸 뒤 투명(웹/창 배경 비침)
  _lcd_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # 줌/표정 트윈 매 프레임
  _lcd_viewport.canvas_item_default_texture_filter = \
    Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST  # 도트 보간 금지
  lcd_container.add_child(_lcd_viewport)

  # 외부에서 LCD 콘텐츠를 붙이는 루트 (SubViewport 로컬 0,0 원점)
  lcd_root = Node2D.new()
  _lcd_viewport.add_child(lcd_root)

  # ── 2) 셸 스프라이트 (콘텐츠 위에 얹혀 구멍/베젤로 보임) ─
  var spr := Sprite2D.new()
  spr.texture = load(SHELL_TEX)
  spr.centered = false
  spr.position = SHELL_POS
  add_child(spr)

  # ── 4) 3버튼 (투명 터치영역 + 눌림 하이라이트) ──────
  for action in BTN_COLS:
    _make_button(action, BTN_COLS[action])

  # ── 5) 코너 스피커 토글 (SFX on/off → flags.sfx_on, 세이브) ── (→ ADR 0004)
  _make_speaker_toggle()


## 셸 내부 버튼 좌표에 투명 Button + 눌림 Panel 을 만든다.
func _make_button(action: StringName, center_x: int) -> void:
  var rect := Rect2(
    SHELL_POS + Vector2(center_x - BTN_W / 2.0, BTN_Y - BTN_H / 2.0),
    Vector2(BTN_W, BTN_H))

  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.position = rect.position
  btn.size = rect.size
  btn.tooltip_text = String(action).to_upper()
  btn.pressed.connect(_trigger.bind(action))
  add_child(btn)

  # 눌림 피드백: 골드 캡슐 (평소 alpha 0)
  var p := Panel.new()
  p.position = rect.position
  p.size = rect.size
  p.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.GOLD
  sb.set_corner_radius_all(int(BTN_H / 2))
  p.add_theme_stylebox_override("panel", sb)
  p.modulate = Color(1, 1, 1, 0)
  add_child(p)
  _flashes[action] = p


## 코너 스피커 토글 — 세이브 flags.sfx_on 을 켜고/끈다. 켤 때만 확인음(끄면 무음).
func _make_speaker_toggle() -> void:
  var sp := ShellSpeaker.new()
  sp.position = SHELL_POS + SPEAKER_POS
  sp.size = SPEAKER_SIZE
  sp.setup(bool(SaveManager.get_value("flags.sfx_on", true)))
  sp.sfx_toggled.connect(_on_sfx_toggled)
  add_child(sp)


func _on_sfx_toggled(on: bool) -> void:
  SaveManager.set_value("flags.sfx_on", on)
  SaveManager.save_game()
  if on:
    Sfx.event(&"confirm")  # 켠 직후 한 번 — 들리는지 즉시 확인


## 키보드 입력 → 액션 (터치는 Button.pressed 가 직접 _trigger 호출)
func _unhandled_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    var action: StringName = KEYMAP.get(
      event.physical_keycode, KEYMAP.get(event.keycode, &""))
    if action != &"":
      _trigger(action)
      get_viewport().set_input_as_handled()


## 키/터치 공통 진입점: 피드백 + 신호 방출
func _trigger(action: StringName) -> void:
  _flash(action)
  button_pressed.emit(action)


## 버튼 눌림 깜빡임 (골드 캡슐 페이드아웃)
func _flash(action: StringName) -> void:
  var p: Panel = _flashes.get(action)
  if p == null:
    return
  p.modulate.a = 0.55
  create_tween().tween_property(p, "modulate:a", 0.0, 0.2)
