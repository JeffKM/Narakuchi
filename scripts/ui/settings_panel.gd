class_name SettingsPanel
extends Control
## 설정 패널 (→ ADR 0004) — 음소거 · 볼륨 · 게임 초기화. 코너 기어로 진입하는 LCD(333×480) 모달.
##
## Main 이 소유해 _lcd_root 최상단에 띄운다(스플래시/온보딩/카페/북 무엇 위든 덮음). 셸 3버튼은
## Main 이 "패널 > 그 외 화면" 우선으로 여기로 위임한다(handle_shell_action). 변경은 즉시 저장.
##   ① 음소거 = flags.sfx_on (ShellSpeaker 글리프 재활용, 볼륨과 독립)
##   ② 볼륨   = flags.volume 0.0~1.0 선형, 6레벨(0~5) 세그먼트 바. Sfx.apply_volume 즉시 적용 + 프리뷰 블립.
##   ③ 초기화 = 패널 내 인라인 2단계 확인(기본 취소) → reset_requested (Main 이 wipe+reload).
## 온보딩 중엔 show_reset=false 로 초기화 행을 숨긴다(이미 새 게임이라 무의미).
## 입력(평면 링 [음소거·볼륨·(초기화)·닫기]): SELECT=순환 · OK=실행(음소거 토글 / 볼륨 한 칸↑ wrap /
##   초기화 확인 진입 / 닫기) · CANCEL=닫기(확인 중이면 확인 취소). 터치가 주, 3버튼 보조.

signal closed
signal reset_requested

const LCD := Vector2(333, 480)
const STEPS := 5  # 볼륨 세그먼트 칸 수 — 레벨 0~5(6단계). flags.volume = level/STEPS.

# 카드(모달 본체) 규격 — LCD 중앙. 초기화 행 유무로 높이가 달라진다.
const CARD_W := 250.0

var _show_reset := true

var _card: Panel
var _mute: ShellSpeaker
var _vol: VolumeBar
var _reset_btn: Button
var _close_btn: Button
var _confirm: Control          # 인라인 리셋 확인 오버레이(떠 있으면 평면 링 대신 확인 포커스)

var _focus_ring: Panel         # 현재 포커스 항목을 감싸는 골드 테두리
var _items: Array = []         # 평면 링: {kind:String, node:Control}
var _focus_index := 0

var _confirm_items: Array = [] # 확인 모드 포커스: [취소, 초기화]
var _confirm_index := 0        # 기본 0 = 취소(실수 방지)


## show_reset=false 면 초기화 행을 숨긴다(온보딩 중). _ready 전에 호출.
func setup(show_reset: bool) -> void:
  _show_reset = show_reset


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤 화면 입력 차단(모달)

  _build_backdrop()
  _build_card()
  _rebuild_focus()
  _focus_index = 0
  _apply_focus()

  modulate.a = 0.0
  create_tween().tween_property(self, "modulate:a", 1.0, 0.16)


# ── 입력 (Main → 여기 → 확인 오버레이) ────────────────────────

func handle_shell_action(action: StringName) -> void:
  if _confirm != null:
    _handle_confirm_action(action)
    return
  match action:
    &"select": _move_focus(1)
    &"ok": _activate_focused()
    &"cancel": _close()


# ── 화면 구성 ────────────────────────────────────────────

## 딤 백드롭 — 카드 바깥을 탭하면 닫힌다(모달 관용). 카드는 그 위 Panel 이 입력을 막는다.
func _build_backdrop() -> void:
  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.72)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(func(e: InputEvent) -> void:
    if e is InputEventScreenTouch and e.pressed:
      _close()
    elif e is InputEventMouseButton and e.pressed:
      _close())
  add_child(dim)


func _build_card() -> void:
  # 행 레이아웃 — 제목 + 음소거 + 볼륨 + (초기화). 높이를 내용에 맞춰 잡는다.
  var rows := 2 + (1 if _show_reset else 0)  # 음소거·볼륨(+초기화)
  var card_h := 86.0 + rows * 52.0 + 16.0

  _card = Panel.new()
  _card.size = Vector2(CARD_W, card_h)
  _card.position = ((LCD - _card.size) / 2.0).round()
  _card.mouse_filter = Control.MOUSE_FILTER_STOP  # 카드 위 탭은 백드롭으로 안 샌다
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.CHARCOAL
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(2)
  sb.border_color = Palette.GOLD
  sb.shadow_color = Color(0, 0, 0, 0.5)
  sb.shadow_size = 6
  _card.add_theme_stylebox_override("panel", sb)
  add_child(_card)

  # 포커스 링(항목 강조) — 카드 자식, 항목 위로 이동.
  _focus_ring = Panel.new()
  _focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var fr := StyleBoxFlat.new()
  fr.bg_color = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.12)
  fr.set_corner_radius_all(6)
  fr.set_border_width_all(2)
  fr.border_color = Palette.GOLD
  _focus_ring.add_theme_stylebox_override("panel", fr)
  _card.add_child(_focus_ring)

  # 제목 + 닫기(×)
  var title := _label(Fonts.SIZE_TITLE, Palette.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
  title.text = "설정"
  title.position = Vector2(16, 12)
  title.size = Vector2(120, 26)
  _card.add_child(title)

  _close_btn = Button.new()
  _close_btn.text = "×"
  UiTheme.style_button(_close_btn)
  _close_btn.position = Vector2(CARD_W - 40.0, 12)
  _close_btn.size = Vector2(28, 24)
  _close_btn.pressed.connect(_close)
  _card.add_child(_close_btn)

  var y := 56.0
  _build_mute_row(y); y += 52.0
  _build_volume_row(y); y += 52.0
  if _show_reset:
    _build_reset_row(y)


## ① 음소거 행 — ShellSpeaker 글리프(스피커/X) 재활용 + 라벨. 토글 시 저장(볼륨과 독립).
func _build_mute_row(y: float) -> void:
  var lb := _label(Fonts.SIZE_LEAD, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
  lb.text = "효과음"
  lb.position = Vector2(16, y)
  lb.size = Vector2(110, 32)
  _card.add_child(lb)

  _mute = ShellSpeaker.new()
  _mute.position = Vector2(CARD_W - 80.0, y + 4.0)
  _mute.size = Vector2(60, 24)
  _mute.setup(bool(SaveManager.get_value("flags.sfx_on", true)))
  _mute.sfx_toggled.connect(_on_mute_toggled)
  _card.add_child(_mute)


## ② 볼륨 행 — 스피커 라벨 + 6레벨 세그먼트 바. 변경 시 적용·저장·프리뷰 블립.
func _build_volume_row(y: float) -> void:
  var lb := _label(Fonts.SIZE_LEAD, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
  lb.text = "볼륨"
  lb.position = Vector2(16, y)
  lb.size = Vector2(60, 32)
  _card.add_child(lb)

  _vol = VolumeBar.new()
  _vol.position = Vector2(76, y + 4.0)
  _vol.size = Vector2(CARD_W - 76.0 - 16.0, 24)
  _vol.set_level(_volume_to_level(float(SaveManager.get_value("flags.volume", 1.0))))
  _vol.level_changed.connect(_on_volume_changed)
  _card.add_child(_vol)


## ③ 초기화 행 — 누르면 인라인 2단계 확인으로 전환(기본 취소).
func _build_reset_row(y: float) -> void:
  _reset_btn = Button.new()
  _reset_btn.text = "게임 초기화"
  UiTheme.style_button(_reset_btn)
  _reset_btn.add_theme_color_override("font_color", Palette.ROSE)
  _reset_btn.position = Vector2(16, y)
  _reset_btn.size = Vector2(CARD_W - 32.0, 34)
  _reset_btn.pressed.connect(_enter_confirm)
  _card.add_child(_reset_btn)


# ── 값 변경 (즉시 저장) ────────────────────────────────────

## 음소거 토글 → flags.sfx_on 저장. 켠 직후 확인음 1회(들리는지 즉시 확인 — 구 코너 토글 동작 계승).
func _on_mute_toggled(on: bool) -> void:
  SaveManager.set_value("flags.sfx_on", on)
  SaveManager.save_game()
  if on:
    Sfx.event(&"confirm")


## 볼륨 레벨(0~STEPS) → 선형 저장 + Master 적용 + 프리뷰 블립(음소거면 자연히 무음).
func _on_volume_changed(level: int) -> void:
  var linear := float(level) / float(STEPS)
  SaveManager.set_value("flags.volume", linear)
  SaveManager.save_game()
  Sfx.apply_volume(linear)
  Sfx.event(&"confirm")  # 바뀐 레벨을 귀로 확인


func _volume_to_level(linear: float) -> int:
  return clampi(int(round(linear * STEPS)), 0, STEPS)


# ── 인라인 리셋 확인 ──────────────────────────────────────

## 카드 위에 확인 오버레이를 띄운다 — 문구 + [취소][초기화], 기본 포커스 취소.
func _enter_confirm() -> void:
  if _confirm != null:
    return
  Sfx.event(&"cancel")
  _confirm = Panel.new()
  _confirm.size = _card.size
  _confirm.mouse_filter = Control.MOUSE_FILTER_STOP
  var sb := StyleBoxFlat.new()
  sb.bg_color = Palette.CHARCOAL
  sb.set_corner_radius_all(10)
  sb.set_border_width_all(2)
  sb.border_color = Palette.ROSE
  _confirm.add_theme_stylebox_override("panel", sb)
  _card.add_child(_confirm)

  var msg := _label(Fonts.SIZE_LEAD, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
  msg.text = "정말 초기화할까요?\n모은 체키와 친밀도가\n모두 사라져요."
  msg.position = Vector2(16, 22)
  msg.size = Vector2(_card.size.x - 32.0, 80)
  msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _confirm.add_child(msg)

  var cancel := Button.new()
  cancel.text = "취소"
  UiTheme.style_button(cancel)
  cancel.position = Vector2(20, _card.size.y - 50.0)
  cancel.size = Vector2((_card.size.x - 52.0) / 2.0, 34)
  cancel.pressed.connect(_exit_confirm)
  _confirm.add_child(cancel)

  var ok := Button.new()
  ok.text = "초기화"
  UiTheme.style_button(ok)
  ok.add_theme_color_override("font_color", Palette.ROSE)
  ok.position = Vector2(20 + (_card.size.x - 52.0) / 2.0 + 12.0, _card.size.y - 50.0)
  ok.size = Vector2((_card.size.x - 52.0) / 2.0, 34)
  ok.pressed.connect(_do_reset)
  _confirm.add_child(ok)

  # 확인 포커스 링(취소·초기화) — 기본 취소.
  _confirm_items = [cancel, ok]
  _confirm_index = 0
  var ring := Panel.new()
  ring.name = "ring"
  ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var rb := StyleBoxFlat.new()
  rb.bg_color = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.12)
  rb.set_corner_radius_all(6)
  rb.set_border_width_all(2)
  rb.border_color = Palette.GOLD
  ring.add_theme_stylebox_override("panel", rb)
  _confirm.add_child(ring)
  _apply_confirm_focus()


func _exit_confirm() -> void:
  if _confirm == null:
    return
  _confirm.queue_free()
  _confirm = null
  _confirm_items.clear()
  _apply_focus()  # 평면 링 포커스 복귀


func _do_reset() -> void:
  reset_requested.emit()  # Main 이 wipe + reload (패널째 사라짐)


func _handle_confirm_action(action: StringName) -> void:
  match action:
    &"select":
      Sfx.event(&"cursor_move")
      _confirm_index = (_confirm_index + 1) % _confirm_items.size()
      _apply_confirm_focus()
    &"ok":
      _confirm_items[_confirm_index].pressed.emit()
    &"cancel":
      _exit_confirm()


func _apply_confirm_focus() -> void:
  var ring: Panel = _confirm.get_node("ring")
  var btn: Control = _confirm_items[_confirm_index]
  ring.position = btn.position - Vector2(3, 3)
  ring.size = btn.size + Vector2(6, 6)


# ── 평면 링 포커스 ───────────────────────────────────────

func _rebuild_focus() -> void:
  _items.clear()
  _items.append({"kind": "mute", "node": _mute})
  _items.append({"kind": "volume", "node": _vol})
  if _show_reset:
    _items.append({"kind": "reset", "node": _reset_btn})
  _items.append({"kind": "close", "node": _close_btn})


func _move_focus(dir: int) -> void:
  Sfx.event(&"cursor_move")
  _focus_index = (_focus_index + dir + _items.size()) % _items.size()
  _apply_focus()


## 현재 포커스 실행 — 음소거 토글 / 볼륨 한 칸↑(wrap) / 초기화 확인 / 닫기.
func _activate_focused() -> void:
  match String(_items[_focus_index]["kind"]):
    "mute": _mute.pressed.emit()
    "volume": _vol.bump()       # 한 칸↑, 최대 도달 시 0 으로 wrap
    "reset": _enter_confirm()
    "close": _close()


## 포커스 링을 현재 항목 위로 이동(여백 3px). 카드 로컬 좌표.
func _apply_focus() -> void:
  if _items.is_empty() or _focus_ring == null:
    return
  var node: Control = _items[_focus_index]["node"]
  _focus_ring.position = node.position - Vector2(4, 4)
  _focus_ring.size = node.size + Vector2(8, 8)


# ── 닫기 / 헬퍼 ──────────────────────────────────────────

func _close() -> void:
  Sfx.event(&"cancel")
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.14)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


func _label(font_size: int, color: Color, align: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = align
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb


# ── 볼륨 세그먼트 바 (내부 클래스) ─────────────────────────
## 6레벨(0~STEPS) 세그먼트 바. 칸 직접 탭/드래그로 레벨 점프(0 포함), 또는 외부 bump 으로 한 칸↑ wrap.
## 도트 결: 채운 칸=골드, 빈 칸=흐린 골드 테두리. level_changed(level:int) 방출.
class VolumeBar extends Control:
  signal level_changed(level: int)

  const STEPS := 5
  const GAP := 3.0

  var _level := STEPS

  func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP

  func set_level(level: int) -> void:
    _level = clampi(level, 0, STEPS)
    queue_redraw()

  ## 한 칸↑ — 최대면 0 으로 wrap. (셸 OK 보조 입력용)
  func bump() -> void:
    _level = 0 if _level >= STEPS else _level + 1
    queue_redraw()
    level_changed.emit(_level)

  func _gui_input(event: InputEvent) -> void:
    var x := -1.0
    if event is InputEventScreenTouch and event.pressed:
      x = event.position.x
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
      x = event.position.x
    elif event is InputEventScreenDrag:
      x = event.position.x
    elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
      x = event.position.x
    if x < 0.0:
      return
    # 탭 x → 레벨(0~STEPS). 칸 폭 기준 반올림으로 0 도 집을 수 있게.
    var lv := clampi(int(round(x / size.x * STEPS)), 0, STEPS)
    if lv != _level:
      _level = lv
      queue_redraw()
      level_changed.emit(_level)

  func _draw() -> void:
    var cell_w := (size.x - GAP * (STEPS - 1)) / STEPS
    for i in STEPS:
      var r := Rect2(i * (cell_w + GAP), 0.0, cell_w, size.y)
      if i < _level:
        draw_rect(r, Palette.GOLD)
      else:
        draw_rect(r, Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.18))
        draw_rect(r, Palette.GOLD_DARK, false, 1.0)
