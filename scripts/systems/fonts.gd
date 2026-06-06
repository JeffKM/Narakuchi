class_name Fonts
extends RefCounted
## 갈무리(한글 도트) 폰트 로더 (→ ADR 0001)
## assets/fonts/Galmuri11.ttf 를 넣으면 자동으로 픽셀-크리스프 설정으로 적용된다.
## 파일이 없으면 null 을 반환 → 호출부에서 엔진 기본 폰트로 폴백.
## 폰트 설치 안내: assets/fonts/README.md

const GALMURI11 := "res://assets/fonts/Galmuri11.ttf"
const GALMURI9 := "res://assets/fonts/Galmuri9.ttf"

const SIZE_TITLE := 22  # 11 ×2
const SIZE_LEAD := 14   # 한 줄 강조용 — 대화·선물 질문, 티커 보이스(11보다 키움)
const SIZE_CHOICE := 15 # 선택지 버튼 라벨
const SIZE_BODY := 11
const SIZE_SMALL := 9


## 갈무리11 로드 (없으면 null). 픽셀 폰트라 안티앨리어싱·힌팅을 끈다.
static func galmuri() -> FontFile:
  if not ResourceLoader.exists(GALMURI11):
    return null
  var f := load(GALMURI11) as FontFile
  if f:
    f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    f.hinting = TextServer.HINTING_NONE
    f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
    f.multichannel_signed_distance_field = false
  return f


## 갈무리9 로드 (없으면 null). 작은 글자(≤9px) 전용 — Galmuri11을 9px로 축소하면
## 비정수 스케일로 흐려져, 9px 네이티브로 디자인된 별도 폰트를 쓴다.
static func galmuri9() -> FontFile:
  if not ResourceLoader.exists(GALMURI9):
    return null
  var f := load(GALMURI9) as FontFile
  if f:
    f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    f.hinting = TextServer.HINTING_NONE
    f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
    f.multichannel_signed_distance_field = false
  return f


## 프로젝트 기본 테마 (갈무리 적용). 폰트가 없으면 빈 테마(엔진 기본 폰트 사용).
static func make_theme() -> Theme:
  var t := Theme.new()
  var f := galmuri()
  if f:
    t.default_font = f
    t.default_font_size = SIZE_BODY
  return t


## 갈무리를 엔진 전역 기본 폰트로 설치 (부트 시 1회). 폰트 없으면 무시(엔진 기본 폰트).
##
## Window 테마는 뷰포트 경계를 못 넘어, 셸 LCD(SubViewport, shell.gd) 안의 Control 은
## 테마 소유주가 없어 ThemeDB 기본 테마의 default_font(=Open Sans, 한글 글리프 없음)로
## 폴백한다 → 웹에서 한글이 .notdef 박스로 깨진다(데스크톱은 OS 한글 시스템폴백이 가려
## 증상이 안 보였을 뿐). 기본 테마의 default_font 자체를 갈무리로 교체해 소유주 유무·
## 뷰포트 경계와 무관하게 모든 Control 이 한글을 그리게 한다. (단일 출처: 부트에서만 호출)
static func install_global() -> void:
  var f := galmuri()
  if f == null:
    return
  var dt := ThemeDB.get_default_theme()
  dt.default_font = f
  dt.default_font_size = SIZE_BODY


## 갈무리 사용 가능 여부 (한글 표기 분기용)
static func has_galmuri() -> bool:
  return ResourceLoader.exists(GALMURI11)
