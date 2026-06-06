class_name DebugTools
extends Node
## 개발/시연 편의 디버그 키 — **디버그 빌드 전용**(Main 이 OS.is_debug_build() 일 때만 붙임).
## release 웹 export(데모 배포)에선 생성되지 않으므로 일반 플레이어에겐 노출 0.
##
##   1 = 완전 초기화(세이브 삭제) → 온보딩부터 (fresh new game)
##   2 = 데모 시드(반말 전환 직전 · 온보딩 스킵) → 바로 교감 화면 (시연용)
##   3 = 현재 씬 리로드(세이브 유지) — 입장 연출/하루치 다시 보기
##   4 = 옥자 "오늘의 체키" 즉시 획득(게이지 풀 → 획득 리빌) — 컬렉션북(T16) 전 카드 확인용
##   5 = 연속출석 마일스톤(3일) 나비 조각 보상 리빌 — T14 확인용(3일 접속 없이 즉시)
##   6 = 시온이 "오늘의 체키" 즉시 획득(게이지 풀 → 획득 리빌) — 시온이 카드 확인용
##
## (숫자열 키 — 노트북 Fn 조합 불필요. F5/Ctrl+R 같은 웹 새로고침과도 충돌 없음.)
## 셸(shell.gd)은 자기 KEYMAP(TAB/방향/스페이스/ESC 등)만 가로채므로 1~6 은 여기로 온다.

const KEYS := {
  KEY_1: "wipe",
  KEY_2: "seed",
  KEY_3: "reload",
  KEY_4: "cheki",
  KEY_5: "milestone",
  KEY_6: "cheki_sion",
}


func _unhandled_input(event: InputEvent) -> void:
  if not (event is InputEventKey and event.pressed and not event.echo):
    return
  match KEYS.get((event as InputEventKey).keycode, ""):
    "wipe":
      SaveManager.wipe()  # 파일 삭제 + 메모리 default → onboarded=false
      _reload()
    "seed":
      SaveManager.reset(true)  # 데모 시드 저장(반말 전환 직전, onboarded=true)
      _reload()
    "reload":
      _reload()
    "cheki":
      _grant_cheki(Events.OKJA)
    "milestone":
      _grant_milestone()
    "cheki_sion":
      _grant_cheki(Events.SION)


## 현재 씬을 다시 로드한다. SaveManager 는 autoload 라 유지되고, Main._ready 가 갱신된 세이브를 다시 읽는다.
func _reload() -> void:
  get_tree().reload_current_scene()


## 교감 화면(Cafe)을 찾아 "오늘의 체키" 획득 리빌을 강제로 띄운다(카드 확인용).
## character: 옥자(키 4) / 시온이(키 6). 카페가 아직 없으면(스플래시/온보딩 중) 무시.
func _grant_cheki(character: String) -> void:
  var cafe := get_tree().get_first_node_in_group(&"cafe")
  if cafe and cafe.has_method("debug_grant_cheki"):
    cafe.debug_grant_cheki(character)


## 교감 화면(Cafe)을 찾아 출석 마일스톤 보상 리빌을 강제로 띄운다(T14 확인용).
func _grant_milestone() -> void:
  var cafe := get_tree().get_first_node_in_group(&"cafe")
  if cafe and cafe.has_method("debug_milestone"):
    cafe.debug_milestone()
