class_name ShareCard
extends Control
## 공유 이미지 내보내기 (T19 + T24 QR) — 체키 한 장을 워터마크 `@나라카` + 배포 링크 QR 과 합성해 저장/공유. (→ PRD §5.4 / ADR 0003)
##
## 흐름(PRD §142): 카드 확대/획득 화면 → "공유" → 이 오버레이가 **공유용 이미지를 합성**해 미리보기 →
##   "저장" → 웹은 브라우저 다운로드(JavaScriptBridge), 데스크톱은 user://shares/ 에 PNG.
## 합성 = SubViewport 에 [크림 액자 + 체키 사진면(2배) + 푸터(@나라카 워드마크 · 배포 링크 QR)]를 그려
##   한 프레임 렌더 → get_image(). 도트 유지(전부 NEAREST, 카드는 정수 2배). QR 은 스캔 위해 네이티브 1:1.
## 셸 3버튼: OK=저장 · CANCEL=닫기. 터치는 버튼/딤(바깥 탭=닫기).
## LCD(333×480) 전체를 덮는 오버레이. 닫히면 closed 신호.

signal closed

const LCD := Vector2(333, 480)

# 합성 캔버스(공유 이미지 원본) — 카드 정수 2배(240×360) + 패드 + 푸터.
const PAD := 12.0
const CARD_SCALE := 2.0
const FOOTER_GAP := 8.0
const FOOTER_PAD := 8.0     # 푸터 상하 여백
const QR_FALLBACK := 96.0   # qr_naraka.png 없을 때 QrPlaceholder 크기

const HANDLE := "@나라카"
# T24 실제 QR(배포 링크) — 있으면 네이티브 크기로 깨짐 없이 박고, 없으면 QrPlaceholder 폴백.
const QR_TEX := "res://assets/sprites/qr_naraka.png"

# 푸터 높이·QR 표시 크기는 QR 에셋에 맞춰 _init_qr_and_size() 가 런타임에 정한다(스캔 위해 정수 1:1).
var SHARE_SIZE := Vector2.ZERO
var _qr_tex: Texture2D
var _qr_side := QR_FALLBACK
var _footer_h := QR_FALLBACK + FOOTER_PAD * 2.0

var _character: String
var _event: String
var _butterfly: bool
var _nickname: String
var _acquired_at: int

var _image: Image          # 저장용 원본(합성 결과)
var _compose_card: ChekiCard  # 합성 캔버스의 체키 카드(트리 진입 후 setup)
var _preview: TextureRect
var _hint: Label
var _closing := false


## 공유할 체키 데이터 주입(트리 진입 전).
func setup(character: String, event: String, butterfly: bool, nickname: String, acquired_at: int) -> void:
  _character = character
  _event = event
  _butterfly = butterfly
  _nickname = nickname
  _acquired_at = acquired_at


func _ready() -> void:
  size = LCD
  mouse_filter = Control.MOUSE_FILTER_STOP  # 뒤 입력 차단

  _init_qr_and_size()  # QR 에셋 로드 + 푸터/합성 캔버스 크기 확정(SHARE_SIZE)

  var dim := ColorRect.new()
  dim.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.0)
  dim.size = LCD
  dim.mouse_filter = Control.MOUSE_FILTER_STOP
  dim.gui_input.connect(_on_dim_input)
  add_child(dim)
  create_tween().tween_property(dim, "color:a", 0.84, 0.2)

  var title := _make_label(Fonts.SIZE_TITLE, Palette.GOLD, 6)
  title.text = "공유 이미지"
  title.add_theme_constant_override("outline_size", 3)
  add_child(title)

  # 미리보기 자리(합성 완료 전까지 안내)
  _preview = TextureRect.new()
  _preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  _preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  _preview.stretch_mode = TextureRect.STRETCH_SCALE
  _preview.mouse_filter = Control.MOUSE_FILTER_STOP  # 카드 탭은 닫기로 안 넘김
  add_child(_preview)

  _hint = _make_label(Fonts.SIZE_SMALL, Palette.GREY_300, 458)
  _hint.text = "이미지를 만드는 중…"
  add_child(_hint)

  _build_buttons()

  modulate.a = 0.0
  create_tween().tween_property(self, "modulate:a", 1.0, 0.16)

  _compose_async()  # SubViewport 합성 → 미리보기 채움(코루틴)


# ── 입력 ─────────────────────────────────────────────────

## 셸 3버튼 중계 (상위 오버레이 → 여기). OK=저장 · CANCEL=닫기.
func handle_shell_action(action: StringName) -> void:
  match action:
    &"ok", &"select": _save()
    &"cancel": _close()


func _on_dim_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _close()
    accept_event()


# ── 크기 산정 ─────────────────────────────────────────────

## QR 에셋을 로드하고 그에 맞춰 푸터 높이·합성 캔버스(SHARE_SIZE)를 정한다.
## QR 은 스캔 위해 네이티브 1:1 로 박는다(다운스케일 시 모듈 합쳐져 스캔 불가) → 푸터가 QR 에 맞춤.
func _init_qr_and_size() -> void:
  if ResourceLoader.exists(QR_TEX):
    _qr_tex = load(QR_TEX) as Texture2D
    _qr_side = float(_qr_tex.get_height())
  else:
    _qr_side = QR_FALLBACK
  _footer_h = _qr_side + FOOTER_PAD * 2.0
  SHARE_SIZE = Vector2(
    PAD + ChekiCard.CARD.x * CARD_SCALE + PAD,
    PAD + ChekiCard.CARD.y * CARD_SCALE + FOOTER_GAP + _footer_h + PAD)


# ── 합성 (SubViewport → 이미지) ───────────────────────────

## 공유 이미지를 오프스크린에서 한 프레임 렌더해 캡처 → 미리보기 텍스처로.
func _compose_async() -> void:
  var vp := SubViewport.new()
  vp.size = Vector2i(SHARE_SIZE)
  vp.transparent_bg = false
  vp.render_target_update_mode = SubViewport.UPDATE_ONCE
  vp.add_child(_compose())
  add_child(vp)

  # 카드가 이제 트리에 들어와 _ready(내부 _front/_back/_emblem 생성) 가 끝났다 →
  # 그 다음에 내용을 채우고 사진 면으로 돌린다(트리 진입 전 setup 은 null 접근 — 합성 누락).
  _compose_card.setup(_character, _event, _butterfly, _nickname, _acquired_at)
  _compose_card.show_face(true)  # 사진 면(자랑용 비주얼)

  # 렌더 완료 대기(한 프레임) 후 이미지 회수.
  await RenderingServer.frame_post_draw
  await get_tree().process_frame
  _image = vp.get_texture().get_image()
  vp.queue_free()

  if _image == null:
    _hint.text = "이미지 생성 실패"
    return
  _preview.texture = ImageTexture.create_from_image(_image)
  _layout_preview()
  _hint.text = "OK ▶ 저장  ·  바깥 탭 ▶ 닫기"


## 합성 캔버스(공유 이미지 원본) Control 트리 — 크림 액자 + 체키 사진면 + 푸터.
func _compose() -> Control:
  var root := Control.new()
  root.size = SHARE_SIZE

  # 1) 크림 바탕 + 골드 액자(이중 테두리)
  var bg := ColorRect.new()
  bg.color = Palette.CREAM
  bg.size = SHARE_SIZE
  root.add_child(bg)
  _add_border(root, SHARE_SIZE, 4.0, Palette.GOLD)
  _add_border(root, SHARE_SIZE, 1.0, Palette.GOLD_DARK, 5.0)

  # 2) 체키 사진 면(정수 2배) — 액자 안 상단
  var holder := Control.new()
  holder.scale = Vector2(CARD_SCALE, CARD_SCALE)
  holder.position = Vector2(PAD, PAD)
  root.add_child(holder)
  # 카드 내용 채우기(setup)·면 전환은 트리 진입 후 _compose_async 에서(여기선 노드만 단다).
  _compose_card = ChekiCard.new()
  holder.add_child(_compose_card)

  # 2b) 개인화 캡션(공유 전용) — 사진 발치에 반투명 잉크 띠 + {닉} · 날짜.
  #     닉/날짜는 카드 '앞면(표지)'에만 있어 사진면 공유엔 '내 이름'이 안 보인다 → 여기서 새긴다.
  #     루트에 1x 로 얹어 글자를 크리스프하게(홀더 2배 안에 넣으면 흐려짐). 발치라 얼굴 안 가림.
  var cap_y := PAD + ChekiCard.CARD.y * CARD_SCALE - 30.0
  var strip := ColorRect.new()
  strip.color = Color(Palette.INK.r, Palette.INK.g, Palette.INK.b, 0.42)
  strip.position = Vector2(PAD + 12, cap_y)
  strip.size = Vector2(ChekiCard.CARD.x * CARD_SCALE - 24, 22)
  root.add_child(strip)

  var nick := _make_label(Fonts.SIZE_BODY, Palette.CANDLE, 0)
  nick.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  nick.text = _resolve_nick()
  nick.position = Vector2(PAD + 18, cap_y + 2)
  nick.size = Vector2(150, 18)
  root.add_child(nick)

  var date := _make_label(Fonts.SIZE_SMALL, Palette.CREAM, 0)
  date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  date.text = _date_dot()
  date.position = Vector2(strip.position.x, cap_y + 4)
  date.size = Vector2(strip.size.x - 6, 14)
  root.add_child(date)

  # 3) 푸터 — 구분선 + (좌)붓글씨 로고·@나라카 핸들 스택 + (우)QR(스캔용 크게)
  var fy := PAD + ChekiCard.CARD.y * CARD_SCALE + FOOTER_GAP
  var sep := ColorRect.new()
  sep.color = Palette.GOLD_DARK
  sep.position = Vector2(PAD, fy)
  sep.size = Vector2(ChekiCard.CARD.x * CARD_SCALE, 1)
  root.add_child(sep)

  # QR — 우측, 네이티브 1:1(스캔 가능). 에셋 없으면 QrPlaceholder 폴백.
  var qr_x := SHARE_SIZE.x - PAD - _qr_side
  var qr_y := fy + (_footer_h - _qr_side) / 2.0
  if _qr_tex != null:
    var qr_img := TextureRect.new()
    qr_img.texture = _qr_tex
    qr_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    qr_img.position = Vector2(qr_x, qr_y)
    qr_img.size = Vector2(_qr_side, _qr_side)
    qr_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(qr_img)
  else:
    var qr := QrPlaceholder.new()
    qr.setup(_qr_side)
    qr.position = Vector2(qr_x, qr_y)
    root.add_child(qr)

  # 붓글씨 로고 + @나라카 핸들 — 좌측 세로 스택, 푸터 가운데 정렬(QR 왼쪽 공간).
  var logo_h := 0.0
  var logo_tex: Texture2D = null
  if ResourceLoader.exists(ChekiCard.WORDMARK):
    logo_tex = load(ChekiCard.WORDMARK) as Texture2D
  if logo_tex != null:
    logo_h = float(logo_tex.get_height())
  var stack_h := logo_h + (6.0 if logo_h > 0 else 0.0) + 18.0
  var sy := fy + (_footer_h - stack_h) / 2.0
  var lx := PAD + 8.0
  if logo_tex != null:
    var logo := TextureRect.new()
    logo.texture = logo_tex
    logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    logo.position = Vector2(lx, sy)
    logo.size = logo_tex.get_size()
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(logo)
    sy += logo_h + 6.0

  var handle := _make_label(Fonts.SIZE_LEAD, Palette.BURGUNDY, 0)
  handle.add_theme_color_override("font_outline_color", Palette.CANDLE)
  handle.add_theme_constant_override("outline_size", 1)
  handle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
  handle.text = HANDLE
  handle.position = Vector2(lx, sy)
  handle.size = Vector2(qr_x - lx - 6.0, 18)
  root.add_child(handle)

  return root


## 미리보기를 화면에 맞춰 배치(세로 기준 축소 — 원본은 저장 시 크리스프).
func _layout_preview() -> void:
  var avail_h := 392.0
  var s := minf(LCD.x / SHARE_SIZE.x, avail_h / SHARE_SIZE.y)
  var w := SHARE_SIZE.x * s
  var h := SHARE_SIZE.y * s
  _preview.size = Vector2(w, h)
  _preview.position = Vector2((LCD.x - w) / 2.0, 32)


# ── 저장 / 공유 ───────────────────────────────────────────

## 합성 이미지를 PNG 로 내보낸다. 웹=브라우저 다운로드 · 그 외=user://shares/.
func _save() -> void:
  if _image == null:
    return
  Sfx.play(&"shutter")
  var buf := _image.save_png_to_buffer()
  var fname := "narakuchi_cheki_%s_%s.png" % [Events.event_slug(_event), _date_stamp()]

  if OS.has_feature("web"):
    _web_share_or_download(buf, fname)
    _flash("공유/저장했어요  (워터마크 %s)" % HANDLE)
  else:
    var dir := "user://shares"
    DirAccess.make_dir_recursive_absolute(dir)
    var path := "%s/%s" % [dir, fname]
    var err := _image.save_png(path)
    if err == OK:
      _flash("저장됨: %s" % ProjectSettings.globalize_path(path))
    else:
      _flash("저장 실패 (err %d)" % err)


## 웹 — 모바일이면 네이티브 공유 시트(Web Share API, 파일)를 띄우고, 미지원/실패 시 다운로드로 폴백.
## 데스크톱 브라우저는 보통 canShare(files)=false → 바로 다운로드. (HTTPS + 사용자 제스처 필요 — 버튼 클릭이 충족)
func _web_share_or_download(buf: PackedByteArray, fname: String) -> void:
  if not OS.has_feature("web"):
    return
  var b64 := Marshalls.raw_to_base64(buf)
  var js := "(function(d,n){" \
    + "function dl(){var a=document.createElement('a');a.href='data:image/png;base64,'+d;a.download=n;document.body.appendChild(a);a.click();a.remove();}" \
    + "try{var bin=atob(d),arr=new Uint8Array(bin.length);for(var i=0;i<bin.length;i++)arr[i]=bin.charCodeAt(i);" \
    + "var f=new File([arr],n,{type:'image/png'});" \
    + "if(navigator.canShare&&navigator.canShare({files:[f]})){" \
    + "navigator.share({files:[f],title:'나라쿠치 체키',text:'나라쿠치에서 모은 체키 ✦ @나라카'}).catch(dl);return;}" \
    + "}catch(e){}dl();" \
    + "})('%s','%s');"
  JavaScriptBridge.eval(js % [b64, fname], true)


# ── 구성 / 닫기 / 헬퍼 ────────────────────────────────────

func _build_buttons() -> void:
  var save := Button.new()
  save.text = "저장"
  UiTheme.style_button(save)
  save.size = Vector2(120, 28)
  save.position = Vector2(LCD.x / 2.0 - 124, 430)
  save.pressed.connect(_save)
  add_child(save)

  var close := Button.new()
  close.text = "닫기"
  UiTheme.style_button(close)
  close.size = Vector2(120, 28)
  close.position = Vector2(LCD.x / 2.0 + 4, 430)
  close.pressed.connect(_close)
  add_child(close)


func _add_border(parent: Control, sz: Vector2, width: float, color: Color, inset := 0.0) -> void:
  var p := Panel.new()
  p.position = Vector2(inset, inset)
  p.size = sz - Vector2(inset * 2.0, inset * 2.0)
  p.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var sb := StyleBoxFlat.new()
  sb.bg_color = Color(0, 0, 0, 0)
  sb.set_border_width_all(int(width))
  sb.border_color = color
  p.add_theme_stylebox_override("panel", sb)
  parent.add_child(p)


func _close() -> void:
  if _closing:
    return
  _closing = true
  var t := create_tween()
  t.tween_property(self, "modulate:a", 0.0, 0.16)
  t.tween_callback(func() -> void:
    closed.emit()
    queue_free())


## 힌트를 잠깐 바꿨다가 기본 안내로 복귀.
func _flash(msg: String) -> void:
  _hint.text = msg
  var t := create_tween()
  t.tween_interval(2.4)
  t.tween_callback(func() -> void:
    if is_instance_valid(_hint) and not _closing:
      _hint.text = "OK ▶ 저장  ·  바깥 탭 ▶ 닫기")


## 공유 캡션 닉네임 — 스냅샷 우선 → 현재 플레이어 닉 → "손님". (ChekiCard._resolve_nick 과 동일 규칙)
func _resolve_nick() -> String:
  var nick := _nickname.strip_edges()
  if nick.is_empty():
    nick = String(SaveManager.get_value("player.nickname", "")).strip_edges()
  return nick if not nick.is_empty() else "손님"


## epoch(초) → "YYYY.MM.DD"(캡션용 점 표기). 0 이면 오늘.
func _date_dot() -> String:
  var d: Dictionary
  if _acquired_at > 0:
    d = Time.get_datetime_dict_from_unix_time(_acquired_at)
  else:
    d = Time.get_datetime_dict_from_system()
  return "%04d.%02d.%02d" % [d["year"], d["month"], d["day"]]


## epoch(초) → "YYYYMMDD". 0 이면 오늘.
func _date_stamp() -> String:
  var d: Dictionary
  if _acquired_at > 0:
    d = Time.get_datetime_dict_from_unix_time(_acquired_at)
  else:
    d = Time.get_datetime_dict_from_system()
  return "%04d%02d%02d" % [d["year"], d["month"], d["day"]]


func _make_label(font_size: int, color: Color, y: float) -> Label:
  var lb := Label.new()
  if font_size <= 9:
    var f9 := Fonts.galmuri9()
    if f9:
      lb.add_theme_font_override("font", f9)
  lb.add_theme_font_size_override("font_size", font_size)
  lb.add_theme_color_override("font_color", color)
  lb.add_theme_color_override("font_outline_color", Palette.INK)
  lb.add_theme_constant_override("outline_size", 2)
  lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  lb.position = Vector2(0, y)
  lb.size = Vector2(LCD.x, 22)
  lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
  return lb
