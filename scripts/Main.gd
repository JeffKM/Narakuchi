extends Node2D
## 나라카찌 부트스트랩 — 270×480 화면이 뜨는지 확인하는 플레이스홀더.
## 실제 화면(온보딩 → 교감 → 컬렉션북 → 공유)은 ROADMAP T06~ 에서 구현.
## 팔레트: data/palette.gd · 폰트: scripts/systems/fonts.gd

const VIEW_W := 270
const VIEW_H := 480


func _ready() -> void:
  # 갈무리 폰트가 있으면 전역 기본 테마로 적용 (없으면 엔진 기본 폰트)
  get_window().theme = Fonts.make_theme()
  _build_placeholder()


func _build_placeholder() -> void:
  var has_font := Fonts.has_galmuri()

  # 배경 (나라카 다크 앤틱)
  var bg := ColorRect.new()
  bg.color = Palette.INK
  bg.size = Vector2(VIEW_W, VIEW_H)
  add_child(bg)

  # 타이틀 — 갈무리가 있으면 한글, 없으면 영문 폴백
  var title := Label.new()
  title.text = "나라카찌" if has_font else "NARAKATCHI"
  title.position = Vector2(0, 198)
  title.size = Vector2(VIEW_W, 28)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.add_theme_color_override("font_color", Palette.GOLD)
  title.add_theme_font_size_override("font_size", Fonts.SIZE_TITLE)
  add_child(title)

  var sub := Label.new()
  sub.text = "boot ok  -  270x480"
  sub.position = Vector2(0, 230)
  sub.size = Vector2(VIEW_W, 16)
  sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(sub)

  # 상태: 폰트/팔레트 적용 여부
  var status := Label.new()
  if has_font:
    status.text = "갈무리 OK · 팔레트 %d색" % Palette.ALL.size()
    status.add_theme_color_override("font_color", Palette.BURGUNDY)
  else:
    status.text = "next: drop Galmuri11.ttf (T03)"
    status.add_theme_color_override("font_color", Palette.GREY_300)
  status.position = Vector2(0, 252)
  status.size = Vector2(VIEW_W, 16)
  status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(status)
