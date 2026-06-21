class_name PetEvolveFx
extends Node2D
## 펫 진화 연출 (D3) — 단계 도달 순간 화이트 플래시 + 골든 햇살 + ★ 반짝임. 추가 아트 0.
##
## 셰이더 없이 `_draw`(흰 광휘 원) + BurstRays(골든 햇살) + 라벨 트윈(반짝이)으로 진화 임팩트를 낸다.
## play(swap) 시퀀스:
##   ① 흰 빛이 펫을 덮으며 팽창·밝아짐(플래시 절정) → 그 순간 swap() 호출(텍스처 하드 스왑)
##   ② 흰 빛이 사그라들며 새 모습 공개 + ★ 반짝이가 사방으로 흩날림
## 성체(분기 reveal)면 더 크고 길게 번쩍인다. 발밑 피벗 펫 위에 z_index 로 얹고, 끝나면 queue_free.

const CENTER := Vector2(0, -42)   # 펫 몸통 중심(발밑 노드 원점 기준 위로 — 96px 도트)
const R_CHILD := 60.0             # 아기→유년 단계 플래시 반경
const R_ADULT := 84.0             # 성체(분기 reveal) — 크게 번쩍

var _radius := 0.0
var _flash_a := 0.0               # 흰 광휘 알파(0~1) — 노드 modulate 와 독립(자식 반짝이는 제 수명대로)
var _is_adult := false


## is_adult = 성체 도달(체형 분기 reveal) → 더 크고 길게.
func setup(is_adult: bool) -> void:
  _is_adult = is_adult


func _ready() -> void:
  z_index = 50  # 펫 스프라이트·접지 그림자 위로


## swap = 플래시 절정에 부를 텍스처 교체 콜백(흰 빛 속에서 새 모습으로). done = 연출 종료 콜백(선택).
func play(swap: Callable, done := Callable()) -> void:
  var peak := R_ADULT if _is_adult else R_CHILD

  # 흰 원 뒤 골든 햇살 — 캔들 톤, 성체일수록 잔광이 길게 남는다.
  var rays := BurstRays.new()
  rays.setup(Palette.CANDLE)
  rays.position = CENTER
  add_child(rays)
  rays.burst()

  var t := create_tween()
  # ① 팽창 + 밝아짐(병렬) — 둘 중 긴 0.18s 뒤 절정.
  t.tween_method(_set_radius, 0.0, peak, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  t.parallel().tween_method(_set_flash, 0.0, 1.0, 0.12)
  # ② 절정 = 텍스처 스왑 + 반짝이 분출.
  t.tween_callback(func() -> void:
    if swap.is_valid():
      swap.call()
    _spawn_sparkles(peak))
  # ③ 흰 빛 사그라듦(새 모습 공개). 성체는 좀 더 길게 여운.
  t.tween_method(_set_flash, 1.0, 0.0, 0.34 if _is_adult else 0.24)
  # ④ 반짝이가 다 흩날릴 시간을 둔 뒤 정리.
  t.tween_interval(0.5)
  t.tween_callback(func() -> void:
    if done.is_valid():
      done.call()
    queue_free())


func _set_radius(r: float) -> void:
  _radius = r
  queue_redraw()


func _set_flash(a: float) -> void:
  _flash_a = a
  queue_redraw()


func _draw() -> void:
  if _radius <= 0.0 or _flash_a <= 0.0:
    return
  var c := Palette.WHITE
  # 옅은 외곽 광휘 + 진한 흰 코어(부드러운 빛 흉내 — 두 겹 원, 셰이더 없이).
  draw_circle(CENTER, _radius, Color(c.r, c.g, c.b, 0.35 * _flash_a))
  draw_circle(CENTER, _radius * 0.62, Color(c.r, c.g, c.b, _flash_a))


## ★/♡ 반짝이 사방으로 — 흰 빛 절정에서 터져 새 모습을 축하한다. (나비 승급 연출의 펫판 축소)
func _spawn_sparkles(reach: float) -> void:
  var n := 9 if _is_adult else 6
  for i in range(n):
    var p := Label.new()
    p.text = "★" if (i % 2 == 0) else "♡"  # 갈무리 지원 글자
    p.add_theme_font_size_override("font_size", Fonts.SIZE_SMALL)
    p.add_theme_color_override("font_color", Palette.CANDLE if (i % 2 == 0) else Palette.WHITE)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    p.position = CENTER
    add_child(p)
    var ang := TAU * float(i) / float(n) - PI / 2.0
    var dist := reach * (0.7 + 0.5 * float(i % 2))
    var dest := CENTER + Vector2(cos(ang), sin(ang)) * dist
    var tw := create_tween().set_parallel(true)
    tw.tween_property(p, "position", dest, 0.5 + float(i) * 0.03) \
      .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(p, "modulate:a", 0.0, 0.55 + float(i) * 0.03)
    tw.chain().tween_callback(p.queue_free)
