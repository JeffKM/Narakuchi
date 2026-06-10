extends SceneTree
## A4·A5 검수 — ART_READY 이벤트 × 캐릭터별로 ChekiCard 가 실제 로드할 레이어 경로가
## 전부 존재하는지 헤드리스로 확인한다(런타임 "텍스처 없음" 경고 사전 차단).
##   godot --headless -s tools/verify_cheki_art.gd
## 끝나면 OK/누락 요약 후 종료(누락 있으면 exit 1).

func _initialize() -> void:
  var missing: Array = []
  var checked := 0
  for ev in Events.LIST:
    if not Events.cheki_art_ready(ev):
      continue
    for ch in Characters.all_ids():
      if not bool(Events.LIST[ev].get(ch, false)):
        continue
      # ChekiCard.setup 분기 그대로 재현: 베이크 컷 우선, 없으면 배경+의상 3겹.
      var baked := Events.cheki_photo_path(ch, ev)
      var layers: Array = []
      if ResourceLoader.exists(baked):
        layers.append(["photo", baked])
      else:
        layers.append(["bg", Events.cheki_bg_path(ch, ev)])
        layers.append(["costume", Events.cheki_costume_path(ch, ev)])
      # 프레임: 일반(표준) + 나비(테마) 둘 다 확인
      layers.append(["frame_std", Events.cheki_frame_path(ev, false)])
      layers.append(["frame_thm", Events.cheki_frame_path(ev, true)])
      for L in layers:
        checked += 1
        if not ResourceLoader.exists(L[1]):
          missing.append("%s:%s [%s] %s" % [ch, ev, L[0], L[1]])
      print("· %s:%s 검사 (베이크=%s)" % [ch, ev, ResourceLoader.exists(baked)])

  print("\n검사한 레이어: %d개" % checked)
  if missing.is_empty():
    print("✅ 모든 ART_READY 체키 레이어 로드 가능")
    quit(0)
  else:
    print("❌ 누락 %d:" % missing.size())
    for m in missing:
      print("   - %s" % m)
    quit(1)
