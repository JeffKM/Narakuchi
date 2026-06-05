class_name Sioni
extends Node2D
## 라이브 시온이 — 흰 얼룩 고양이 펫. 반응 스왑 + bob. (T15, Okja 패턴 축소판 → ADR 0001)
##
## - 라이브는 **기본 흰 고양이 고정**(이벤트 의상은 체키 전용 — 옥자와 동일 원리).
## - idle/간식/놀기/쓰담 4장을 **하드컷**으로 통째 교체(크로스페이드 금지: 자세 달라 고스팅).
## - 평소: **둥실 흔들(bob)**. 반응: 짧은 **스쿼시 정착**. 리워드: **hop(폴짝)**.
##
## 노드 원점 = **발밑(하단 중앙)** — 스케일/홉이 바닥에 붙어 보이게 피벗을 발에 둔다.

const EXPRESSIONS := {
  &"idle":  "res://assets/sprites/sioni_idle.png",
  &"snack": "res://assets/sprites/sioni_snack.png",
  &"play":  "res://assets/sprites/sioni_play.png",
  &"pet":   "res://assets/sprites/sioni_pet.png",
}
const SPR_SIZE := Vector2(96, 96)  # 원본 텍스처 캔버스 크기(sioni_*.png — 제미나이→dotify 96px 도트)

var current: StringName = &"idle"

var _sprite: Sprite2D
var _textures := {}
var _sprite_base := Vector2.ZERO  # 둥실 bob 기준 위치(스프라이트 로컬)
var _react: Tween                 # 정착/홉(일시 트윈) — 새로 시작 전 정리


func _ready() -> void:
  # 96×96 도트를 그대로 표시(scale 1.0 = 옥자처럼 1텍셀=1픽셀 정수 격자). 줌(×2)도 정확한 정수배라 또렷.
  for k in EXPRESSIONS:
    _textures[k] = load(EXPRESSIONS[k])

  _sprite = Sprite2D.new()
  _sprite.centered = false
  _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 도트 또렷
  # 발밑이 노드 원점(0,0)에 오도록 좌상단을 끌어올린다(96×96 캔버스 기준).
  _sprite_base = Vector2(-SPR_SIZE.x / 2.0, -SPR_SIZE.y)
  _sprite.position = _sprite_base
  _sprite.texture = _textures[current]
  add_child(_sprite)

  _start_bob()


## 상시 둥실 흔들 (스프라이트만 위아래 ±1.5px 무한 루프 — 작은 몸이라 폭 줄임)
func _start_bob() -> void:
  var t := create_tween().set_loops()
  t.tween_property(_sprite, "position:y", _sprite_base.y - 1.5, 1.2) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  t.tween_property(_sprite, "position:y", _sprite_base.y + 1.5, 1.2) \
    .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 반응 전환: 하드컷 교체 + 짧은 스쿼시 정착.
## 같은 반응을 다시 눌러도 스쿼시는 한 번 더 줘서 매 탭이 살아있게 한다(텍스처만 같을 때 스킵).
func set_expression(name: StringName) -> void:
  if not _textures.has(name):
    return
  if name != current:
    current = name
    _sprite.texture = _textures[name]  # ← 하드컷
  _settle()


## 스쿼시 정착 — 살짝 납작했다 펴짐(0.14s). 발밑 기준이라 바닥에 붙어 보인다.
func _settle() -> void:
  if _react and _react.is_valid():
    _react.kill()
  scale = Vector2(1.10, 0.88)
  _react = create_tween()
  _react.tween_property(self, "scale", Vector2.ONE, 0.14) \
    .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 리워드 폴짝 — 통 통 튀어오른다(체키 획득 순간). 표정은 현재 유지.
func hop() -> void:
  if _react and _react.is_valid():
    _react.kill()
  var ground := position.y
  _react = create_tween()
  _react.tween_property(self, "position:y", ground - 14.0, 0.16) \
    .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  _react.tween_property(self, "position:y", ground, 0.22) \
    .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
