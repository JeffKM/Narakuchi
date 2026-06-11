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
var _shell: ShellFrame     # 코너 기어 활성/비활성 제어용
var _splash: Splash       # 진입 스플래시(지옥문 열림 + 옥자 맞이). 진행 중이면 셸 입력을 여기로.
var _onboarding: Onboarding  # 진행 중이면 셸 입력을 여기로 (없으면 카페로)
var _settings: SettingsPanel  # 설정 패널(코너 기어). 떠 있으면 셸 입력을 최우선으로 여기로.


func _ready() -> void:
  # 갈무리를 엔진 전역 기본 폰트로 설치 — Window 테마는 SubViewport(셸 LCD) 경계를 못 넘어
  # 내부 Control 이 엔진 기본 폰트(Open Sans, 한글 없음)로 폴백해 웹에서 한글이 깨진다.
  # 기본 테마 폰트 자체를 갈무리로 교체해 전역 보장. (상세 사유는 Fonts.install_global)
  Fonts.install_global()
  # 셸 바깥 여백 투명 — 웹/창 배경이 비치게
  get_window().transparent_bg = true

  _shell = ShellFrame.new()
  add_child(_shell)
  _shell.button_pressed.connect(_on_shell_button)
  _shell.settings_requested.connect(_open_settings)
  _lcd_root = _shell.lcd_root

  # LCD 안에 메인 교감 화면 (아직 세션 시작 안 함 — 스플래시 뒤에 깔아둠)
  _cafe = Cafe.new()
  _lcd_root.add_child(_cafe)

  # 진입 스플래시 오버레이 — 끝나면 온보딩(첫 접속) 또는 카페 세션으로.
  # 스플래시 연출 중엔 코너 기어 비활성(진입 차단), 끝나면 활성.
  _shell.set_settings_enabled(false)
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
  _shell.set_settings_enabled(true)  # 연출 끝 — 코너 기어 활성
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
  lb.text = "[1]초기화 [2]반말직전 [3]리로드 [4]체키 [5]출석보상 [6]시온체키 [7]단골직전"
  lb.position = Vector2(0, ShellFrame.CANVAS.y - 26)
  lb.size = Vector2(ShellFrame.CANVAS.x, 20)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.add_theme_font_size_override("font_size", Fonts.SIZE_SMALL)
  lb.add_theme_color_override("font_color", Palette.GREY_300)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  return lb


## 셸 3버튼 → 활성 화면으로 중계 (설정 패널 → 스플래시 → 온보딩 → 카페 순).
## 설정 패널은 어느 화면 위든 덮는 모달이라 떠 있으면 최우선으로 가로챈다.
func _on_shell_button(action: StringName) -> void:
  if _settings != null:
    _settings.handle_shell_action(action)
  elif _splash != null:
    _splash.handle_shell_action(action)
  elif _onboarding != null:
    _onboarding.handle_shell_action(action)
  else:
    _cafe.handle_shell_action(action)


## 코너 기어 → 설정 패널을 _lcd_root 최상단(모든 화면 위)에 띄운다.
## 온보딩 중엔 초기화 행을 숨긴다(이미 새 게임이라 무의미). 이미 떠 있으면 무시.
func _open_settings() -> void:
  if _settings != null:
    return
  _settings = SettingsPanel.new()
  _settings.setup(_onboarding == null)  # 온보딩 중이면 초기화 숨김
  _settings.closed.connect(_on_settings_closed)
  _settings.reset_requested.connect(_on_settings_reset)
  _lcd_root.add_child(_settings)  # 맨 위(마지막 자식) → 모든 화면 덮음


func _on_settings_closed() -> void:
  _settings = null


## 게임 초기화 — 세이브 삭제 후 씬 리로드(디버그 wipe 경로 재사용). onboarded=false → 스플래시·온보딩 복귀.
func _on_settings_reset() -> void:
  SaveManager.wipe()
  get_tree().reload_current_scene()
