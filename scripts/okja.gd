class_name Okja
extends Node2D
## 옥자 표정 스왑 스탠딩. (→ ADR 0001 / ROADMAP T07)
##
## - 얼굴 + 팔 자세가 다른 6장을 **하드컷**으로 통째 교체한다.
##   (크로스페이드 금지: 팔 자세가 달라 반투명 겹침=고스팅·팔레트 밖 중간색.)
## - 평소: **둥실 흔들(bob)** — 살아있는 느낌.
## - 표정 전환: 짧은 **스쿼시 정착**(바닥에 탁 선 듯) — 컷의 점프를 "반응"으로 가린다.
## - 리워드: **hop(폴짝)** — 별도 그림 없이 `smile`을 재사용해 통 통 튀어오른다.
##
## 노드 원점 = **발밑(하단 중앙)**. 스케일/홉이 바닥에 붙은 듯 보이도록 피벗을 발에 둔다.
## 배치 예) okja.position = Vector2(166, 452)  # LCD(333×480) 바닥 중앙

const EXPRESSIONS := {
  &"idle":  "res://assets/sprites/okja_idle.png",
  &"smile": "res://assets/sprites/okja_smile.png",
  &"shy":   "res://assets/sprites/okja_shy.png",
  &"sad":   "res://assets/sprites/okja_sad.png",
  &"brew":  "res://assets/sprites/okja_brew.png",
  &"talk":  "res://assets/sprites/okja_talk.png",
}
const SPR_SIZE := Vector2(128, 288)

var current: StringName = &"idle"

var _sprite: Sprite2D
var _textures := {}
var _sprite_base := Vector2.ZERO  # 둥실 bob 기준 위치(스프라이트 로컬)
var _react: Tween                 # 정착/홉(일시 트윈) — 새로 시작 전 정리


func _ready() -> void:
  for k in EXPRESSIONS:
    _textures[k] = load(EXPRESSIONS[k])

  _sprite = Sprite2D.new()
  _sprite.centered = false
  _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 도트 또렷
  # 발밑이 노드 원점(0,0)에 오도록 좌상단을 끌어올린다.
  _sprite_base = Vector2(-SPR_SIZE.x / 2.0, -SPR_SIZE.y)
  _sprite.position = _sprite_base
  _sprite.texture = _textures[current]
  add_child(_sprite)

  _start_bob()


## 상시 둥실 흔들 (스프라이트만 위아래 ±2px 무한 루프 — 정착/홉과 채널 분리)
func _start_bob() -> void:
  var t := create_tween().set_loops()
  t.tween_property(_sprite, "position:y", _sprite_base.y - 2.0, 1.4) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.tween_property(_sprite, "position:y", _sprite_base.y + 2.0, 1.4) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 표정 전환: 하드컷 교체 + 짧은 스쿼시 정착. (같은 표정이면 무시)
func set_expression(name: StringName) -> void:
  if not _textures.has(name) or name == current:
    return
  current = name
  _sprite.texture = _textures[name]  # ← 하드컷 (크로스페이드 안 함)
  _settle()


## 스쿼시 정착 — 살짝 납작했다 펴짐(0.14s). 스케일은 발밑 기준이라 바닥에 붙어 보인다.
func _settle() -> void:
  if _react and _react.is_valid():
    _react.kill()
  scale = Vector2(1.08, 0.90)
  _react = create_tween()
  _react.tween_property(self, "scale", Vector2.ONE, 0.14) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 리워드 폴짝 — smile 로 바꾸고 통 통 튀어오른다. (체키 획득/나비 승급 순간)
func hop() -> void:
  set_expression(&"smile")
  if _react and _react.is_valid():
    _react.kill()
  var ground := position.y
  _react = create_tween()
  _react.tween_property(self, "position:y", ground - 18.0, 0.18) \
    .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  _react.tween_property(self, "position:y", ground, 0.24) \
    .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
