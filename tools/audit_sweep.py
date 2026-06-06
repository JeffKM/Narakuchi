#!/usr/bin/env python3
"""T20 감사 스윕 — 매니페스트 전 도트 에셋을 한 번에 규격 검수한다.

교체는 끝났다는 전제(ROADMAP T20)에서, 이미 저장된 산출물들이
마스터 팔레트(32색)·치수·알파(0/255)·LCD 규격을 지키는지 일괄 확인한다.
검수 로직은 dotify.audit 단일 출처를 그대로 재사용한다(규격 로직 중복 금지).

사용:
  tools/.venv/bin/python tools/audit_sweep.py            # 리포트만
  tools/.venv/bin/python tools/audit_sweep.py --fix      # 팔레트외/반투명 픽셀 재인덱싱(치수는 손 안 댐)
  tools/.venv/bin/python tools/audit_sweep.py --verbose  # 위반 색 상세(최근접 팔레트색 포함)

종료코드: 치수 위반이 하나라도 있으면 1(재인덱싱으로 못 고침), 아니면 0.
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import dotify  # noqa: E402

MANIFEST = os.path.join(ROOT, "tools", "asset_manifest.json")

# S그룹 등 아직 만들지 않는 게 정상인 미래 에셋 — 누락이어도 실패로 안 본다.
FUTURE_OK = {
  "icon_currency",      # 무과금: 화폐 아이콘 미사용
  "share_watermark",    # 공유는 런타임 합성(T19) — 정적 워터마크 불필요
}

# 도트 파이프라인 산출물이 아니라 채택한 레퍼런스를 가공만 한 "부드러운" 에셋 —
# 32색·0/255 알파 강제 대상이 아니다(→ ADR 0001 §갱신이력: 도트풍 레퍼런스 셸 채택,
# prep_shell.py는 투명화·리샘플만 수행). 치수는 검사하되 팔레트/반투명은 면제.
SOFT_EXEMPT = {
  "shell_frame",        # 다마고치형 달걀 바디 베젤 — 둥근 음영이 매력 포인트
  # PWA 앱 아이콘 = 옥자 얼굴 풀컬러 합성(make_pwa_icons.py) — 인게임 도트가 아닌 앱 아이콘. 치수만 검사.
  "pwa_icon_144", "pwa_icon_180", "pwa_icon_192", "pwa_icon_512",
}


def resolve_spec(item):
  """매니페스트 항목 → (w, h, transparent, lcd)."""
  if item.get("preset"):
    return dotify.PRESETS[item["preset"]]
  w, h = item["size"]
  return w, h, item.get("transparent", True), None


def offending_colors(img, pal):
  """팔레트 밖 색 → [(rgb, 픽셀수, 최근접팔레트색)] 내림차순."""
  arr = np.array(img.convert("RGBA"))
  alpha = arr[:, :, 3]
  rgb = arr[alpha > 10][:, :3]
  if not len(rgb):
    return []
  palset = {tuple(int(v) for v in c) for c in pal.astype(np.uint8)}
  colors, counts = np.unique(rgb.reshape(-1, 3), axis=0, return_counts=True)
  out = []
  for c, n in zip(colors, counts):
    t = tuple(int(v) for v in c)
    if t in palset:
      continue
    d = ((pal - np.array(t, dtype=np.float32)) ** 2).sum(1)
    near = tuple(int(v) for v in pal[d.argmin()].astype(np.uint8))
    out.append((t, int(n), near))
  out.sort(key=lambda x: -x[1])
  return out


def reindex_fix(path, w, h, transparent, lcd, pal):
  """팔레트외/반투명 픽셀만 정리해 같은 경로에 덮어쓴다.

  치수는 건드리지 않는다(원본 비율 깨짐 위험 → 수동 검토 대상).
  알파는 이미 있는 마스크(>128)를 0/255로 이진화, RGB는 최근접 팔레트색으로 인덱싱.
  """
  im = Image.open(path).convert("RGBA")
  arr = np.array(im)
  rgb, alpha = arr[:, :, :3], arr[:, :, 3]
  mask = alpha > 128 if transparent else np.ones(alpha.shape, bool)
  mapped = dotify.index_to_palette(rgb, pal)
  out = np.dstack([mapped, np.where(mask, 255, 0).astype(np.uint8)])
  if lcd:
    x, y, lw, lh = lcd
    out[y:y + lh, x:x + lw, 3] = 0
  Image.fromarray(out, "RGBA").save(path)


def main():
  ap = argparse.ArgumentParser(description="T20 도트 에셋 감사 스윕")
  ap.add_argument("--fix", action="store_true", help="팔레트외/반투명 픽셀 재인덱싱(덮어쓰기)")
  ap.add_argument("--verbose", action="store_true", help="위반 색 상세 출력")
  args = ap.parse_args()

  manifest = json.load(open(MANIFEST))
  pal = dotify.load_palette()

  total = passed = 0
  dim_fails = []      # 치수 위반(재인덱싱 불가 → 수동)
  pal_fails = []      # 팔레트/반투명 위반(재인덱싱 가능)
  missing = []        # 파일 없음
  fixed = []

  for g in manifest["groups"]:
    print(f"\n## {g['title']}")
    for it in g["items"]:
      iid, path = it["id"], it["path"]
      abspath = os.path.join(ROOT, path)
      if not os.path.exists(abspath):
        tag = "  ⏭️  미생산(예정)" if iid in FUTURE_OK else "  ⚠️  파일없음"
        print(f"{tag}  {iid}")
        if iid not in FUTURE_OK:
          missing.append(iid)
        continue

      total += 1
      w, h, transparent, lcd = resolve_spec(it)
      img = Image.open(abspath).convert("RGBA")
      ok, lines = dotify.audit(img, w, h, pal, lcd)

      iw, ih = img.size
      dim_ok = (iw, ih) == (w, h)

      # 부드러운 면제 에셋: 치수만 보고 팔레트/반투명 위반은 무시한다.
      if iid in SOFT_EXEMPT:
        if dim_ok:
          passed += 1
          print(f"  ⏭️  {iid} (소프트 면제 — 치수 OK, 팔레트/알파 비강제)")
        else:
          print(f"  ❌ {iid} (소프트 면제지만 치수 위반)")
          dim_fails.append((iid, f"{iw}×{ih}", f"{w}×{h}"))
        continue

      if ok:
        passed += 1
        print(f"  ✅ {iid}")
        continue

      print(f"  ❌ {iid}")
      for ln in lines:
        if "❌" in ln:
          print(f"    {ln.strip()}")
      if not dim_ok:
        dim_fails.append((iid, f"{iw}×{ih}", f"{w}×{h}"))
      else:
        pal_fails.append((iid, abspath, (w, h, transparent, lcd)))
        if args.verbose:
          for c, n, near in offending_colors(img, pal)[:8]:
            print(f"       · #{('%02x%02x%02x' % c)} ×{n} → 최근접 #{'%02x%02x%02x' % near}")

  # ── 재인덱싱 ─────────────────────────────────────
  if args.fix and pal_fails:
    print("\n=== 재인덱싱 ===")
    for iid, abspath, (w, h, tr, lcd) in pal_fails:
      reindex_fix(abspath, w, h, tr, lcd, pal)
      # 재검수
      ok2, _ = dotify.audit(Image.open(abspath).convert("RGBA"), w, h, pal, lcd)
      print(f"  {'✅' if ok2 else '❌'} {iid} 재인덱싱{'' if ok2 else ' (여전히 위반)'}")
      if ok2:
        fixed.append(iid)

  # ── 요약 ─────────────────────────────────────────
  print("\n" + "=" * 48)
  print(f"검수 {total}개 중 통과 {passed}개")
  if fixed:
    print(f"재인덱싱 수정 {len(fixed)}개: {', '.join(fixed)}")
  if pal_fails and not args.fix:
    print(f"팔레트/반투명 위반 {len(pal_fails)}개(--fix로 수정 가능): "
          + ", ".join(i for i, *_ in pal_fails))
  if dim_fails:
    print(f"❌ 치수 위반 {len(dim_fails)}개(수동 검토):")
    for iid, got, want in dim_fails:
      print(f"   - {iid}: {got} (목표 {want})")
  if missing:
    print(f"⚠️  예기치 못한 누락 {len(missing)}개: {', '.join(missing)}")

  remaining_pal = 0 if args.fix else len(pal_fails)
  if not dim_fails and not missing and remaining_pal == 0:
    print("✅ 전 에셋 규격 통과")
  # 치수/누락은 자동수정 불가 → 실패코드
  sys.exit(1 if (dim_fails or missing) else 0)


if __name__ == "__main__":
  main()
