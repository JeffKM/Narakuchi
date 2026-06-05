extends Node2D
## 나라쿠치 부트스트랩 — 게임기 셸 + 메인 교감 화면(또는 첫 접속 온보딩). (→ ADR 0001)
##
## 셸(ShellFrame) LCD(333×480) 안에 Cafe(메인 교감 화면)를 올린다.
## 첫 접속(flags.onboarded 미설정)이면 Cafe 위에 Onboarding 오버레이를 띄우고,
##   끝나면 걷어낸 뒤 Cafe.start() 로 세션을 연다.
## 셸 3버튼(SELECT/OK/CANCEL)은 활성 화면(온보딩 또는 카페)으로 중계한다.
##
## 구성 요소: 셸 scripts/systems/shell.gd · 카페 scripts/cafe.gd · 온보딩 scripts/onboarding.gd
## 미터 scripts/systems/meters.gd · 대사 data/dialogue.gd · 팔레트 data/palette.gd · 폰트 scripts/systems/fonts.gd

var _lcd_root: Node2D
var _cafe: Cafe
var _splash: Splash       # 진입 스플래시(지옥문 열림 + 옥자 맞이). 진행 중이면 셸 입력을 여기로.
var _onboarding: Onboarding  # 진행 중이면 셸 입력을 여기로 (없으면 카페로)


func _ready() -> void:
  # 갈무리 폰트 전역 테마 (없으면 엔진 기본)
  get_window().theme = Fonts.make_theme()
  # 셸 바깥 여백 투명 — 웹/창 배경이 비치게
  get_window().transparent_bg = true

  var shell := ShellFrame.new()
  add_child(shell)
  shell.button_pressed.connect(_on_shell_button)
  _lcd_root = shell.lcd_root

  # LCD 안에 메인 교감 화면 (아직 세션 시작 안 함 — 스플래시 뒤에 깔아둠)
  _cafe = Cafe.new()
  _lcd_root.add_child(_cafe)

  # 진입 스플래시 오버레이 — 끝나면 온보딩(첫 접속) 또는 카페 세션으로
  _start_splash()

  # 디버그 빌드에서만: 초기화/시드/리로드 단축키 + 화면 힌트 (release 데모엔 미노출)
  if OS.is_debug_build():
    add_child(DebugTools.new())
    add_child(_make_debug_hint())


## 진입 스플래시를 카페 위에 띄운다. 끝나면 걷고 분기.
func _start_splash() -> void:
  _splash = Splash.new()
  _splash.finished.connect(_on_splash_done)
  _lcd_root.add_child(_splash)


func _on_splash_done() -> void:
  _splash.queue_free()
  _splash = null
  # 첫 접속이면 온보딩, 아니면 바로 세션 시작
  if bool(SaveManager.get_value("flags.onboarded", false)):
    _cafe.start()
  else:
    _start_onboarding(_lcd_root)


## 온보딩 오버레이를 카페 위에 띄운다. 끝나면 걷고 카페 세션 시작.
func _start_onboarding(lcd_root: Node2D) -> void:
  _onboarding = Onboarding.new()
  _onboarding.finished.connect(_on_onboarding_done)
  lcd_root.add_child(_onboarding)


func _on_onboarding_done() -> void:
  _onboarding.queue_free()
  _onboarding = null
  _cafe.start()


## 디버그 단축키 힌트 — 셸 하단 여백(캔버스 좌표)에 작게 (디버그 빌드만).
func _make_debug_hint() -> Label:
  var lb := Label.new()
  lb.text = "[1] 초기화  [2] 데모시드  [3] 리로드  [4] 체키획득  [5] 출석보상"
  lb.position = Vector2(0, ShellFrame.CANVAS.y - 26)
  lb.size = Vector2(ShellFrame.CANVAS.x, 20)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.add_theme_font_size_override("font_size", Fonts.SIZE_SMALL)
  lb.add_theme_color_override("font_color", Palette.GREY_300)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  return lb


## 셸 3버튼 → 활성 화면으로 중계 (스플래시 → 온보딩 → 카페 순).
func _on_shell_button(action: StringName) -> void:
  if _splash != null:
    _splash.handle_shell_action(action)
  elif _onboarding != null:
    _onboarding.handle_shell_action(action)
  else:
    _cafe.handle_shell_action(action)
