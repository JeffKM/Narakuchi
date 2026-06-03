class_name Fonts
extends RefCounted
## 갈무리(한글 도트) 폰트 로더 (→ ADR 0001)
## assets/fonts/Galmuri11.ttf 를 넣으면 자동으로 픽셀-크리스프 설정으로 적용된다.
## 파일이 없으면 null 을 반환 → 호출부에서 엔진 기본 폰트로 폴백.
## 폰트 설치 안내: assets/fonts/README.md

const GALMURI11 := "res://assets/fonts/Galmuri11.ttf"
const GALMURI9 := "res://assets/fonts/Galmuri9.ttf"

const SIZE_TITLE := 22  # 11 ×2
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


## 프로젝트 기본 테마 (갈무리 적용). 폰트가 없으면 빈 테마(엔진 기본 폰트 사용).
static func make_theme() -> Theme:
  var t := Theme.new()
  var f := galmuri()
  if f:
    t.default_font = f
    t.default_font_size = SIZE_BODY
  return t


## 갈무리 사용 가능 여부 (한글 표기 분기용)
static func has_galmuri() -> bool:
  return ResourceLoader.exists(GALMURI11)
