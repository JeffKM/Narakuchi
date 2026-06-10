class_name CollectionBook
extends Control
## 체키북 (T16 + 장식 패스) — 실물 포토카드 바인더. (→ ADR 0002·0003 / 장식 합의 2026-06-05)
##
## 카페 위 풀스크린 오버레이(ChekiReveal 패턴). cafe.gd 가 우상단 아이콘/CANCEL 로 토글하고 소유한다.
## 은유: 앤틱 마녀 바인더 = 가죽 테두리(다크 무드) + 크림 속지(카드 팝).
## 레이어(뒤→앞):
##   딤 백드롭 · 가죽 프레임(베젤) · 크림 속지(+N 워터마크·코너 오너먼트) ·
##   헤더(타이틀 + 진행도 카운터 + ✕) · 캐릭터 색인 탭 · 2열 그리드(ChekiSlot) · 힌트 · 장식 나비.
##   - 칸: ChekiSlot 가 owned/empty/locked/limited 렌더(미보유=표지 디밍+참). owned 탭 → CardDetail 모달.
##         옥자 그리드 끝 "한정" 슬롯 1칸 = 현장 한정 예고(컨셉/예정, 데모 해금 불가 — T21).
##   - 탭: 좌측 GroupChip(메인/펫 토글) + 그 뒤 현재 그룹의 CharacterTab(초상 색인, 레지스트리 파생).
##         그룹 칩 누르면 그 그룹의 마지막 본 캐릭터로 즉시 전환(_last_main/_last_pet). 9명이 한 줄에 안 들어가 분리.
##   - 카운터: 활성 캐릭터 ◆◆◇◇◇ n/m (미래 포함 전체, 잠긴 핍 회색 — 콘텐츠 예고 후크).
## 입력(평면 링): SELECT=포커스 순환(그룹 칩+탭+칸) · OK=활성(그룹/탭 전환·모달 열기) · CANCEL=책 닫기.
##   터치가 주 입력(탭/칸 직접 터치), 3버튼은 보조. _detail 떠 있으면 그쪽으로 위임.
##
## 가죽 프레임(book_frame_leather) + 불투명 크림 속지(book_page_parchment 종이결) 연결됨.
##    속지는 카드를 받치는 불투명 페이지라 데클 엣지로 어두운 백드롭이 비치지 않는다.
##    코너 장식·N 워터마크는 가죽 프레임에 이미 있고 카드 가독성을 해쳐 제거. (→ docs/asset-checklist.md A6)
##    가죽 에셋이 없으면 StyleBox 플레이스홀더로 폴백.

signal closed

const LCD := Vector2(333, 480)

# A6 체키북 장식 에셋 경로 — 없으면 플레이스홀더 폴백.
const TEX_FRAME := "res://assets/sprites/book_frame_leather.png"      # 가죽 바인더(333×480, 중앙 투명)
const TEX_PAGE := "res://assets/sprites/book_page_parchment.png"      # 크림 속지(불투명 크림 위 종이결)
# 가죽 프레임 오버스캔 — book_frame_leather PNG는 외곽에 먹빛 띠(#0d0b12)가 구워져 있어,
# 그대로 두면 가장자리에 검은 줄이 남는다. 각 변을 FRAME_BLEED 만큼 키워(=확대) 그 검은 띠를
# 캔버스 밖으로 밀어내고 루트 clip_contents 로 잘라낸다.
const FRAME_BLEED := 15.0
# 가죽 프레임 창이 PNG 안에서 우측으로 치우쳐(좌 테두리 두껍·우 얇) 구워져 있어, 오버스캔만으론
# 창이 LCD 중앙에 안 온다(좌우 그늘 틈 비대칭). 프레임 그리기를 이만큼 좌측으로 시프트해 창을
# LCD 가운데로 맞춘다. PNG는 그대로 두고 위치만 보정. (측정: 창 중심이 LCD 중심보다 +8px → 2026-06-06)
const WINDOW_RECENTER := 8.0

# 크림 속지가 가죽 창으로 드러나는 영역(오버스캔 M=15 + 리센터 8 반영) — 카드는 이 안에 들어가야
# 가죽 테두리를 침범하지 않는다. x37~295(258) · y31~447.  (← 합성 측정, 2026-06-06)
const WINDOW := Rect2(37, 31, 258, 416)

# 그리드 — 창(258px) 중앙에 2열 120px 카드. margin 5 / gutter 8 (5+120+8+120+5=258).
const GRID_COLS := 2
const GRID_X := 42           # WINDOW.x(37) + margin 5 — 리센터된 창 중앙
const GRID_Y := 84
const GRID_W := 248          # 120*2 + 8
const GRID_H := 346
const H_SEP := 8
const V_SEP := 16
# 진행도 핍.
const PIP := Vector2(7, 10)
const PIP_GAP := 9.0

# 그룹 토글(메인/펫) — 탭 줄 좌측 세그먼트. 캐릭터 탭은 레지스트리(Characters)에서 그룹별로 파생(단일 출처).
#   메인=교감·관계단계·기분 보유 / 펫=게이지만. 새 캐릭터는 characters.gd 만 고치면 여기 자동 반영.
#   그룹 칩을 누르면 그 그룹의 "마지막 본 캐릭터"로 즉시 전환(_last_main/_last_pet, C1-b).
#   (구 TABS 하드코딩 배열 + section 갭 + locked 예고 분기 폐기 → 메인/펫 탭 분리 2026-06-10)
const GROUPS := [
  {"kind": Characters.MAIN, "label": "메인"},
  {"kind": Characters.PET, "label": "펫"},
]
const CHIP_GAP := 5.0   # 그룹 칩(메인/펫) 사이 간격
const GROUP_GAP := 8.0  # 그룹 칩 묶음과 캐릭터 탭 묶음 사이 간격

var _active_group: String = Characters.MAIN  # 현재 보는 그룹(메인/펫)
var _active_char: String = "okja"
var _last_main: String = "okja"  # 그룹 복귀용 — 마지막 본 메인 (C1-b, _ready 에서 레지스트리 기본값)
var _last_pet: String = "sion"   # 그룹 복귀용 — 마지막 본 펫
var _group_chips: Array = []     # GroupChip (GROUPS 순서)
var _tabs: Array = []            # 현재 그룹 CharacterTab
var _tab_ids: Array = []         # _tabs[i] 대응 캐릭터 id (현재 그룹 순서)
var _slots: Array = []           # 현재 캐릭터 ChekiSlot
var _focus: Array = []           # 평면 링: {kind:"group"|"tab"|"slot", i:int}
var _focus_index: int = 0

var _scroll: ScrollContainer
var _grid: GridContainer
var _shelf: Control              # 탭 선반(골드 룰) — 그룹 전환 후 항상 칩/탭 위로 올린다
var _hint: Label
var _counter: Control            # 진행도 핍+숫자 홀더(재구성)
var _char_label: Label           # 헤더 "· 옥자" — 활성 캐릭터명(탭 초상-only 대체 방향감)
var _detail: CardDetail


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤(카페) 입력 차단
  clip_contents = true  # 오버스캔된 가죽 프레임의 검은 외곽 띠를 LCD 밖으로 잘라낸다

  # 그룹별 기본/마지막-본 캐릭터는 레지스트리 단일 출처에서(첫 진입 메인=옥자·펫=시온이).
  _last_main = Characters.default_main()
  _last_pet = Characters.default_pet()
  _active_group = Characters.MAIN
  _active_char = _last_main

  # 레이어 순서(뒤→앞): 크림 속지(전면) → 가죽 프레임(테두리, 위) → 헤더/탭/그리드.
  # 속지를 화면 전체에 깔고 가죽을 그 위에 얹어, 가죽 투명 창으로만 속지가 드러나게 한다.
  # → 사방 일관된 장식 테두리 + 균일한 속지(회색 틈 0).
  _build_page()
  _build_book_frame()
  _build_header()
  _build_tabs()
  _build_grid_container()
  _build_attendance()
  _build_hint()
  _build_butterflies()

  modulate.a = 0.0  # 부드러운 등장 페이드
  create_tween().tween_property(self, "modulate:a", 1.0, 0.18)

  _populate(_active_char)
  _rebuild_focus()
  _focus_index = _first_slot_focus_index()
  _apply_focus()
  _update_counter()


# ── 입력 (cafe → 여기 → _detail) ──────────────────────────

func handle_shell_action(action: StringName) -> void:
  if _detail != null:
    _detail.handle_shell_action(action)
    return
  match action:
    &"select": _move_focus(1)
    &"ok": _activate_focused()
    &"cancel": _close()


## 외부 새로고침 — 책이 열린 채 컬렉션 데이터가 바뀐 경우(예: 디버그로 체키 지급) 현재 보기를 다시 그린다.
## 탭 전환 없이 활성 캐릭터 그리드·카운터만 최신 상태로 재빌드한다(_on_tab 과 동일 골격, 캐릭터 유지).
func refresh() -> void:
  _populate(_active_char)
  _rebuild_focus()
  _focus_index = clampi(_focus_index, 0, maxi(0, _focus.size() - 1))
  _apply_focus()
  _update_counter()


# ── 화면 구성 ─────────────────────────────────────────────

## 가죽 바인더 베젤 — book_frame_leather.png 를 각 변 FRAME_BLEED 만큼 오버스캔해서
## 외곽 먹빛 띠를 캔버스 밖으로 밀어낸다(루트 clip_contents 로 잘림). 버건디가 가장자리까지 참.
## 에셋 없으면 버건디 테두리 + 골드 스티치 StyleBox 플레이스홀더로 폴백.
func _build_book_frame() -> void:
  var tex := _tex(TEX_FRAME)
  if tex:
    var frame := TextureRect.new()
    frame.texture = tex
    frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    frame.stretch_mode = TextureRect.STRETCH_SCALE
    # 좌측으로 WINDOW_RECENTER 만큼 더 밀어 창을 LCD 중앙에 맞춘다(좌우 그늘 틈 대칭).
    frame.position = Vector2(-FRAME_BLEED - WINDOW_RECENTER, -FRAME_BLEED)
    frame.size = LCD + Vector2(FRAME_BLEED * 2.0, FRAME_BLEED * 2.0)
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(frame)
    return

  var leather := Panel.new()
  leather.size = LCD
  leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(0, 0, 0, 0)          # 가운데 비움(속지·그리드 노출)
  sb.set_border_width_all(14)
  sb.border_color = Palette.BURGUNDY_DARK
  sb.set_corner_radius_all(16)
  leather.add_theme_stylebox_override("panel", sb)
  add_child(leather)

  var stitch := Panel.new()
  stitch.position = Vector2(6, 6)
  stitch.size = LCD - Vector2(12, 12)
  stitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var ss := StyleBoxFlat.new()
  ss.bg_color = Color(0, 0, 0, 0)
  ss.set_border_width_all(1)
  ss.border_color = Palette.GOLD_DARK
  ss.set_corner_radius_all(11)
  stitch.add_theme_stylebox_override("panel", ss)
  add_child(stitch)


## 크림 속지 — 화면 전체를 덮는 불투명 페이지. 위에 얹는 가죽 프레임의 투명 창으로만 드러난다.
## 전체를 깔기 때문에 가죽 어디에도 어두운 틈이 생기지 않는다(=사방 일관된 테두리).
##   레이어: 불투명 크림 바탕(전면) → 종이결 텍스처(book_page_parchment, 살짝 비침).
func _build_page() -> void:
  # 1) 불투명 크림 바탕 — LCD 전체. 가죽이 위에서 테두리를 만든다.
  var base := ColorRect.new()
  base.color = Palette.CREAM
  base.position = Vector2.ZERO
  base.size = LCD
  base.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(base)

  # 2) 종이결 텍스처(있으면) — 크림 위에 살짝 올려 질감만. 가죽 창 영역만 보이면 충분.
  var page_tex := _tex(TEX_PAGE)
  if page_tex:
    var page := TextureRect.new()
    page.texture = page_tex
    page.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    page.stretch_mode = TextureRect.STRETCH_SCALE
    page.position = Vector2.ZERO
    page.size = LCD
    page.modulate = Color(1, 1, 1, 0.5)  # 은은하게 — 바탕 크림이 메인
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(page)


func _build_header() -> void:
  var title := _make_label(Fonts.SIZE_TITLE, Palette.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
  title.text = "체키북"
  title.position = Vector2(14, 6)
  title.size = Vector2(70, 26)
  add_child(title)

  # 활성 캐릭터명 — 탭이 초상-only라 "내가 누구 페이지인지"를 헤더가 담당.
  # 타이틀("체키북") 오른쪽에 캔들색 브레드크럼으로. _update_title 이 텍스트 채움.
  _char_label = _make_label(Fonts.SIZE_LEAD, Palette.CANDLE, HORIZONTAL_ALIGNMENT_LEFT)
  _char_label.position = Vector2(82, 12)
  _char_label.size = Vector2(120, 18)
  add_child(_char_label)

  # 진행도 카운터 홀더(우측, ✕ 왼쪽) — _update_counter 가 채운다.
  _counter = Control.new()
  _counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_counter)

  var close := Button.new()
  close.text = "×"  # U+00D7 — 갈무리 지원(✕ U+2715 는 글리프 없어 두부)
  UiTheme.style_button(close)
  close.position = Vector2(LCD.x - 38, 6)
  close.size = Vector2(28, 24)
  close.pressed.connect(_close)
  add_child(close)


## 탭 줄 구성 — 좌측 그룹 칩(메인/펫) + 그 뒤 현재 그룹의 캐릭터 탭(레지스트리 파생).
## 선반(골드 룰)은 한 번만 깔고, 캐릭터 탭은 그룹 전환마다 _build_char_tabs 가 재생성한다.
func _build_tabs() -> void:
  _build_group_chips()
  _build_char_tabs()
  _build_tab_shelf()


## 그룹 칩 2개(메인/펫) — 탭 줄 좌단(GRID_X)에 고정. 한 번만 생성(그룹 전환에도 불변).
func _build_group_chips() -> void:
  var x := float(GRID_X)
  for i in GROUPS.size():
    var g: Dictionary = GROUPS[i]
    var chip := GroupChip.new()
    chip.setup(String(g["label"]))
    chip.position = Vector2(x, 38)
    var kind := String(g["kind"])
    chip.pressed.connect(func() -> void: _on_group(kind))
    add_child(chip)
    _group_chips.append(chip)
    x += GroupChip.CHIP.x + CHIP_GAP


## 캐릭터 탭 줄 시작 x — 그룹 칩 묶음(2칩 + 칩 간격) 뒤 GROUP_GAP.
func _char_tabs_x() -> float:
  return float(GRID_X) + GroupChip.CHIP.x * 2.0 + CHIP_GAP + GROUP_GAP


## 현재 그룹의 캐릭터 탭 재생성(레지스트리 그룹별 id 순서). 그룹 전환마다 호출.
## 재생성된 탭은 트리 최상단에 add 되므로, 선반이 있으면 다시 위로 올려 둥근 하단 솔기를 덮는다.
func _build_char_tabs() -> void:
  for t in _tabs:
    t.queue_free()
  _tabs.clear()
  _tab_ids.clear()

  var ids: Array = Characters.mains() if _active_group == Characters.MAIN else Characters.pets()
  var x := _char_tabs_x()
  for i in ids.size():
    var id := String(ids[i])
    var tab := CharacterTab.new()
    tab.setup(id, Characters.display_name(id), false, Characters.accent(id))
    tab.position = Vector2(x, 38)
    var idx := i
    tab.pressed.connect(func() -> void: _on_tab(idx))
    add_child(tab)
    _tabs.append(tab)
    _tab_ids.append(id)
    x += CharacterTab.TAB.x + 6.0

  if _shelf != null:
    _shelf.move_to_front()  # 전환으로 새로 add 된 탭들 위로 선반 복귀
  _refresh_group_marks()
  _refresh_tab_marks()


## 탭 선반 — 탭 행 바로 밑에 깔리는 가로 골드 룰(베벨). 탭 하단(y68)과 살짝 겹쳐(y65~68)
## "선반에 꽂힌 색인 혀"로 보이게 한다 → 탭이 크림 위에 붕 뜨는 느낌·아래 빈 포켓감 제거.
## 룰들을 _shelf 컨테이너에 담아, 그룹 전환으로 탭이 재생성돼도 move_to_front 로 위에 유지한다.
func _build_tab_shelf() -> void:
  _shelf = Control.new()
  _shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(_shelf)
  var x := float(GRID_X) - 2.0
  var w := float(GRID_W) + 4.0
  var y := 65.0
  _add_rule(x, y - 1.0, w, 1.0, Palette.CANDLE)   # 윗 하이라이트(베벨)
  _add_rule(x, y, w, 2.0, Palette.GOLD)           # 골드 본선(탭이 얹히는 선반)
  _add_rule(x, y + 2.0, w, 1.0, Palette.GOLD_DARK) # 아래 그림자


## 가로 룰 1개 — 입력 무시 ColorRect. 선반 컨테이너(_shelf)에 담는다.
func _add_rule(x: float, y: float, w: float, h: float, color: Color) -> void:
  var r := ColorRect.new()
  r.color = color
  r.position = Vector2(x, y)
  r.size = Vector2(w, h)
  r.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _shelf.add_child(r)


func _build_grid_container() -> void:
  _scroll = ScrollContainer.new()
  _scroll.position = Vector2(GRID_X, GRID_Y)
  _scroll.size = Vector2(GRID_W, GRID_H)
  _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
  add_child(_scroll)
  _style_scrollbar()

  _grid = GridContainer.new()
  _grid.columns = GRID_COLS
  _grid.add_theme_constant_override("h_separation", H_SEP)
  _grid.add_theme_constant_override("v_separation", V_SEP)
  _scroll.add_child(_grid)


## 얇은 골드 스크롤바(넘칠 때만). 도트 톤 유지.
func _style_scrollbar() -> void:
  var bar := _scroll.get_v_scroll_bar()
  if bar == null:
    return
  bar.custom_minimum_size.x = 4
  var grab := StyleBoxFlat.new()
  grab.bg_color = Palette.GOLD_DARK
  grab.set_corner_radius_all(2)
  var grab_hi := StyleBoxFlat.new()
  grab_hi.bg_color = Palette.GOLD
  grab_hi.set_corner_radius_all(2)
  var empty := StyleBoxEmpty.new()
  bar.add_theme_stylebox_override("scroll", empty)
  bar.add_theme_stylebox_override("grabber", grab)
  bar.add_theme_stylebox_override("grabber_highlight", grab_hi)
  bar.add_theme_stylebox_override("grabber_pressed", grab_hi)


func _build_hint() -> void:
  _hint = _make_label(Fonts.SIZE_SMALL, Palette.GREY_300, HORIZONTAL_ALIGNMENT_CENTER)
  _hint.text = "SELECT ▶ 이동 · OK ▶ 보기 · CANCEL ▶ 닫기"
  _hint.position = Vector2(0, 463)
  _hint.size = Vector2(LCD.x, 14)
  add_child(_hint)


## 출석 진행 스트립 (T14) — 하단 가죽 푸터(어두워 가독성↑)에 "출석 N일" + 다음 마일스톤 핍 + 남은 일.
## 마일스톤(나비 조각)이 컬렉션을 채우는 보상이라 체키북에 둔다. 표시값은 Meters.attendance_status().
func _build_attendance() -> void:
  var st := Meters.attendance_status()
  var streak := int(st["streak"])
  var next := int(st["next"])
  var remaining := int(st["remaining"])

  var holder := Control.new()
  holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(holder)

  var x := 0.0
  var head := _make_label(Fonts.SIZE_SMALL, Palette.CANDLE, HORIZONTAL_ALIGNMENT_LEFT)
  head.text = "출석 %d일" % streak
  head.position = Vector2(x, -1)
  head.size = Vector2(52, 13)
  holder.add_child(head)
  x += 52.0

  if next > 0:
    # 다음 마일스톤까지 핍 (next 개, 채움=min(streak, next) → 진행 막대)
    for i in range(next):
      var pip := Panel.new()
      pip.size = PIP
      pip.position = Vector2(x, 1)
      pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
      var sb := StyleBoxFlat.new()
      sb.set_corner_radius_all(2)
      if i < streak:
        sb.bg_color = Palette.GOLD                # 채운 날
      else:
        sb.bg_color = Color(0, 0, 0, 0)           # 남은 날 = 빈 핍
        sb.set_border_width_all(1)
        sb.border_color = Palette.GOLD_DARK
      pip.add_theme_stylebox_override("panel", sb)
      holder.add_child(pip)
      x += PIP_GAP
    var tail := _make_label(Fonts.SIZE_SMALL, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
    tail.text = "  보상까지 %d일" % remaining
    tail.position = Vector2(x + 2.0, -1)
    tail.size = Vector2(90, 13)
    holder.add_child(tail)
    x += 92.0
  else:
    # 데모 마일스톤(3·7일) 다 받음
    var done := _make_label(Fonts.SIZE_SMALL, Palette.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
    done.text = "  출석 보상 다 모음!"
    done.position = Vector2(x + 2.0, -1)
    done.size = Vector2(120, 13)
    holder.add_child(done)
    x += 122.0

  # 가로 가운데 정렬, 가죽 푸터 위쪽 줄(힌트 위)
  holder.position = Vector2((LCD.x - x) / 2.0, 448)
  holder.size = Vector2(x, 14)


## 장식 나비 — 페이지 가장자리(카드 안 가림), 입력 무시.
## TODO(에셋): butterfly_deco.png 로 교체(현재 _draw 플레이스홀더).
func _build_butterflies() -> void:
  # 창 안(가죽 침범 X)·카드 비는 띠(탭 아래 / 그리드 아래)에 둔다.
  var spots := [
    {"pos": Vector2(274, 70), "hue": Palette.VIOLET},      # 우상단(탭 아래) — 리센터 -8
    {"pos": Vector2(48, 432), "hue": Palette.ACCENT_PINK}, # 좌하단(그리드 아래) — 리센터 -8
  ]
  for s in spots:
    var b := ButterflyDeco.new()
    b.setup(Color(s["hue"]))
    b.position = Vector2(s["pos"])
    add_child(b)


# ── 진행도 카운터 ─────────────────────────────────────────

## 활성 캐릭터의 ◆◆◇◇◇ n/m 재구성. m=미래 포함 전체, 잠긴 핍 회색(콘텐츠 예고).
## TODO(에셋): 핍을 pip_card.png(채움/빔)로 승급 가능(현재 Panel 플레이스홀더).
func _update_counter() -> void:
  if _counter == null:
    return
  for c in _counter.get_children():
    c.queue_free()

  var evs := Events.events_for(_active_char)
  var owned := 0
  var x := 0.0
  for ev in evs:
    var pip := Panel.new()
    pip.size = PIP
    pip.position = Vector2(x, 2)
    pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sb := StyleBoxFlat.new()
    sb.set_corner_radius_all(2)
    if Cheki.owned(_active_char, ev):
      sb.bg_color = Palette.GOLD            # 보유 = 채운 카드
      owned += 1
    elif Events.cheki_art_ready(ev):
      sb.bg_color = Color(0, 0, 0, 0)       # 획득가능 = 골드 빈 카드
      sb.set_border_width_all(1)
      sb.border_color = Palette.GOLD_DARK
    else:
      sb.bg_color = Palette.GREY_700        # 잠김(미래) = 회색
    pip.add_theme_stylebox_override("panel", sb)
    _counter.add_child(pip)
    x += PIP_GAP

  var lb := _make_label(Fonts.SIZE_SMALL, Palette.CANDLE, HORIZONTAL_ALIGNMENT_LEFT)
  lb.text = "%d/%d" % [owned, evs.size()]
  lb.position = Vector2(x + 4.0, 0)
  lb.size = Vector2(36, 14)
  _counter.add_child(lb)

  # 우측 정렬(✕ 왼쪽에 끝나게)
  var total_w := x + 4.0 + 30.0
  _counter.position = Vector2(LCD.x - 46.0 - total_w, 10)
  _counter.size = Vector2(total_w, 14)


# ── 그리드 채우기 ─────────────────────────────────────────

## 캐릭터의 모든 이벤트 칸을 LIST 순서로 깐다(owned/empty/locked 다 노출).
func _populate(character: String) -> void:
  for s in _slots:
    s.queue_free()
  _slots.clear()

  _active_char = character
  # 그룹 복귀(C1-b)용 — 마지막 본 캐릭터를 그룹별로 기억. _populate 는 모든 전환의 단일 경로.
  if Characters.is_main(character):
    _last_main = character
  else:
    _last_pet = character
  for ev in Events.events_for(character):
    var slot := ChekiSlot.new()
    slot.setup(character, ev)
    _grid.add_child(slot)
    slot.pressed.connect(_on_slot_pressed.bind(slot))
    _slots.append(slot)

  # 옥자 그리드 끝 "한정" 슬롯 1칸 — 현장 한정 예고(컨셉/예정, 데모 해금 불가). (→ T21)
  if character == Events.OKJA:
    var limited := ChekiSlot.new()
    limited.setup_limited()
    _grid.add_child(limited)
    limited.pressed.connect(_on_slot_pressed.bind(limited))
    _slots.append(limited)

  _refresh_tab_marks()
  _update_title()


## 헤더 캐릭터명 갱신 — 활성 캐릭터의 표시명을 "· 옥자" 형태로. 탭 전환(=_populate)마다 호출.
func _update_title() -> void:
  if _char_label == null:
    return
  var name := Characters.display_name(_active_char)
  _char_label.text = ("· " + name) if not name.is_empty() else ""


# ── 탭 ───────────────────────────────────────────────────

func _on_tab(tab_index: int) -> void:
  var id := String(_tab_ids[tab_index])
  if id == _active_char:
    _focus_to_tab(tab_index)
    return
  Sfx.event(&"tab_switch")  # 캐릭터 탭 전환 → ADR 0004
  _populate(id)
  _rebuild_focus()
  _focus_index = _first_slot_focus_index()
  _apply_focus()
  _update_counter()


## 그룹 토글 — 같은 그룹이면 칩에 포커스만, 다른 그룹이면 마지막 본 캐릭터로 즉시 전환(C1·C1-b).
## 탭 줄(현재 그룹 캐릭터)·그리드·헤더·카운터를 한 번에 그 그룹으로 갈아끼워 불일치 구간이 없다.
func _on_group(kind: String) -> void:
  if kind == _active_group:
    _focus_to_group(kind)
    return
  Sfx.event(&"tab_switch")  # 그룹 전환 → ADR 0004
  _active_group = kind
  _build_char_tabs()  # 현재 그룹 탭 재생성 + 그룹/탭 강조 갱신
  _populate(_last_main if kind == Characters.MAIN else _last_pet)
  _rebuild_focus()
  _focus_index = _first_slot_focus_index()
  _apply_focus()
  _update_counter()


## 활성 캐릭터 탭 강조(현재 그룹 탭만 존재).
func _refresh_tab_marks() -> void:
  for i in _tabs.size():
    _tabs[i].set_active(String(_tab_ids[i]) == _active_char)


## 활성 그룹 칩 강조.
func _refresh_group_marks() -> void:
  for i in _group_chips.size():
    _group_chips[i].set_active(String(GROUPS[i]["kind"]) == _active_group)


# ── 칸 ───────────────────────────────────────────────────

func _on_slot_pressed(slot: ChekiSlot) -> void:
  # 터치/포커스 진입점 통합 — 포커스도 이 칸으로 옮긴다.
  var fi := _slot_focus_index(slot)
  if fi >= 0:
    _focus_index = fi
    _apply_focus()
  _open_slot(slot)


## 칸 열기 — owned 면 모달, 한정 슬롯이면 예고 힌트, 그 외 미보유면 안내.
func _open_slot(slot: ChekiSlot) -> void:
  if slot.is_limited():
    _flash_hint("현장 한정 체키 — 곧 만나요")  # 컨셉/예정 톤다운(데모 해금 불가)
    return
  if not slot.is_owned():
    _flash_hint("아직 못 모은 체키예요")
    return
  _open_detail(slot)


## 확대 모달 — 현재 캐릭터의 "보유" 칸만 prev/next 스코프로 넘긴다.
func _open_detail(slot: ChekiSlot) -> void:
  if _detail != null:
    return
  Sfx.event(&"card_open")  # 카드 확대 모달 진입 → ADR 0004
  var owned_events: Array = []
  for s in _slots:
    if s.is_owned():
      owned_events.append(s.event)
  var start := owned_events.find(slot.event)
  if start < 0:
    start = 0

  _detail = CardDetail.new()
  _detail.setup(_active_char, owned_events, start)
  _detail.closed.connect(_on_detail_closed)
  add_child(_detail)  # 맨 위


func _on_detail_closed() -> void:
  _detail = null


# ── 평면 링 포커스 ────────────────────────────────────────

## 포커스 링 재구성 = 그룹 칩 + 현재 그룹 탭 + 현재 캐릭터 칸 (공간 순서: 위→아래).
func _rebuild_focus() -> void:
  _focus.clear()
  for i in _group_chips.size():
    _focus.append({"kind": "group", "i": i})
  for i in _tabs.size():
    _focus.append({"kind": "tab", "i": i})
  for i in _slots.size():
    _focus.append({"kind": "slot", "i": i})


func _move_focus(dir: int) -> void:
  if _focus.is_empty():
    return
  Sfx.event(&"cursor_move")  # 탭/칸 포커스 이동 → ADR 0004
  _focus_index = (_focus_index + dir + _focus.size()) % _focus.size()
  _apply_focus()


## 현재 포커스 활성화 — 그룹 칩이면 그룹 전환, 탭이면 캐릭터 전환, 칸이면 열기.
func _activate_focused() -> void:
  if _focus.is_empty():
    return
  var f: Dictionary = _focus[_focus_index]
  match String(f["kind"]):
    "group": _on_group(String(GROUPS[int(f["i"])]["kind"]))
    "tab": _on_tab(int(f["i"]))
    "slot": _open_slot(_slots[int(f["i"])])


## 모든 하이라이트 끄고 현재만 켠다. 칸이면 스크롤로 보이게.
func _apply_focus() -> void:
  for chip in _group_chips:
    chip.set_focused(false)
  for tab in _tabs:
    tab.set_focused(false)
  for s in _slots:
    s.set_focused(false)
  if _focus.is_empty():
    return
  var f: Dictionary = _focus[_focus_index]
  match String(f["kind"]):
    "group": _group_chips[int(f["i"])].set_focused(true)
    "tab": _tabs[int(f["i"])].set_focused(true)
    "slot":
      var slot: ChekiSlot = _slots[int(f["i"])]
      slot.set_focused(true)
      _scroll.ensure_control_visible(slot)


func _first_slot_focus_index() -> int:
  for i in _focus.size():
    if String(_focus[i]["kind"]) == "slot":
      return i
  return 0


func _slot_focus_index(slot: ChekiSlot) -> int:
  var slot_i := _slots.find(slot)
  if slot_i < 0:
    return -1
  for i in _focus.size():
    var f: Dictionary = _focus[i]
    if String(f["kind"]) == "slot" and int(f["i"]) == slot_i:
      return i
  return -1


func _focus_to_tab(tab_index: int) -> void:
  for i in _focus.size():
    var f: Dictionary = _focus[i]
    if String(f["kind"]) == "tab" and int(f["i"]) == tab_index:
      _focus_index = i
      _apply_focus()
      return


## 이미 활성인 그룹 칩을 다시 누르면 그 칩으로 포커스만 옮긴다(전환 없음).
func _focus_to_group(kind: String) -> void:
  for i in _focus.size():
    var f: Dictionary = _focus[i]
    if String(f["kind"]) == "group" and String(GROUPS[int(f["i"])]["kind"]) == kind:
      _focus_index = i
      _apply_focus()
      return


# ── 닫기 / 헬퍼 ───────────────────────────────────────────

func _close() -> void:
  Sfx.event(&"cancel")  # 컬렉션북 닫기(뒤로) → ADR 0004
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


## 힌트 라벨을 잠깐 바꿨다가 기본 안내로 복귀.
func _flash_hint(msg: String) -> void:
  _hint.text = msg
  var t := create_tween()
  t.tween_interval(1.6)
  t.tween_callback(func() -> void:
    if is_instance_valid(_hint):
      _hint.text = "SELECT ▶ 이동 · OK ▶ 보기 · CANCEL ▶ 닫기")


## 경로 → 텍스처(없으면 null — 호출부가 플레이스홀더로 폴백, 크래시 없음).
func _tex(path: String) -> Texture2D:
  if ResourceLoader.exists(path):
    return load(path) as Texture2D
  return null


func _make_label(font_size: int, color: Color, align: int) -> Label:
  var lb := Label.new()
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)  # 얇은 외곽선(도트 폰트 부드럽게)
  lb.horizontal_alignment = align
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
