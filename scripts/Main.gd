extends Node2D
## 나라카찌 부트스트랩 — 게임기 셸 + 메인 교감 화면(또는 첫 접속 온보딩). (→ ADR 0001)
##
## 셸(ShellFrame) LCD(333×480) 안에 Cafe(메인 교감 화면)를 올린다.
## 첫 접속(flags.onboarded 미설정)이면 Cafe 위에 Onboarding 오버레이를 띄우고,
##   끝나면 걷어낸 뒤 Cafe.start() 로 세션을 연다.
## 셸 3버튼(SELECT/OK/CANCEL)은 활성 화면(온보딩 또는 카페)으로 중계한다.
##
## 구성 요소: 셸 scripts/systems/shell.gd · 카페 scripts/cafe.gd · 온보딩 scripts/onboarding.gd
## 미터 scripts/systems/meters.gd · 대사 data/dialogue.gd · 팔레트 data/palette.gd · 폰트 scripts/systems/fonts.gd

var _cafe: Cafe
var _onboarding: Onboarding  # 진행 중이면 셸 입력을 여기로 (없으면 카페로)


func _ready() -> void:
  # 갈무리 폰트 전역 테마 (없으면 엔진 기본)
  get_window().theme = Fonts.make_theme()
  # 셸 바깥 여백 투명 — 웹/창 배경이 비치게
  get_window().transparent_bg = true

  var shell := ShellFrame.new()
  add_child(shell)
  shell.button_pressed.connect(_on_shell_button)

  # LCD 안에 메인 교감 화면
  _cafe = Cafe.new()
  shell.lcd_root.add_child(_cafe)

  # 첫 접속이면 온보딩, 아니면 바로 세션 시작
  if bool(SaveManager.get_value("flags.onboarded", false)):
    _cafe.start()
  else:
    _start_onboarding(shell.lcd_root)


## 온보딩 오버레이를 카페 위에 띄운다. 끝나면 걷고 카페 세션 시작.
func _start_onboarding(lcd_root: Node2D) -> void:
  _onboarding = Onboarding.new()
  _onboarding.finished.connect(_on_onboarding_done)
  lcd_root.add_child(_onboarding)


func _on_onboarding_done() -> void:
  _onboarding.queue_free()
  _onboarding = null
  _cafe.start()


## 셸 3버튼 → 활성 화면으로 중계.
func _on_shell_button(action: StringName) -> void:
  if _onboarding != null:
    _onboarding.handle_shell_action(action)
  else:
    _cafe.handle_shell_action(action)
