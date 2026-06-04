#!/usr/bin/env python3
"""나라카찌 도트화 파이프라인 — AI 생성 이미지를 규격 도트 에셋으로 강제 변환.

Gemini/Midjourney가 만든 '도트풍 큰 그림'을 받아 규격을 코드로 강제한다:
  1) 목표 규격으로 비율 맞춰 축소(fit)
  2) 마스터 32색 팔레트로 인덱싱 → 색 폭발 해결
  3) 알파 이진화(반투명 제거) → 도트 규격
  4) (셸 프리셋) LCD칸을 270×480 비율로 투명 마스킹
  5) 검수 리포트 출력 → 규격 통과 여부 자동 판정
AI 결과 품질과 무관하게 산출물은 항상 규격에 맞는다.

사용 예:
  python tools/dotify.py 원본.png --preset frame --out out.png
  python tools/dotify.py 원본.png --preset okja  --out okja_idle.png
  python tools/dotify.py 원본.png --size 120x180 --transparent --out cheki.png
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALETTE_HEX = os.path.join(ROOT, "assets", "palettes", "narakatchi.hex")

# 프리셋: (폭, 높이, 투명배경?, LCD사각 or None)
#  LCD = (x, y, w, h) — 셸 내부 게임 화면 구멍 (→ ADR 0001: 좌베젤 95·상단 30, 270×480)
PRESETS = {
  "okja":  (128, 288, True,  None),
  "sioni": (48,  48,  True,  None),
  "bg":    (270, 480, False, None),
  "frame": (460, 630, True,  (95, 30, 270, 480)),
  "cheki": (120, 180, True,  None),
}


def load_palette(path=PALETTE_HEX):
  """마스터 팔레트(.hex)를 (N,3) float 배열로 로드."""
  with open(path) as f:
    hexes = [ln.strip().lstrip("#") for ln in f if ln.strip()]
  return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in hexes], dtype=np.float32)


def fit_resize(im, target_w, target_h):
  """비율 유지 축소 후 중앙 배치(남는 곳 투명). 왜곡 없이 규격 캔버스에 안착."""
  src_w, src_h = im.size
  scale = min(target_w / src_w, target_h / src_h)
  new_w, new_h = max(1, round(src_w * scale)), max(1, round(src_h * scale))
  resized = im.resize((new_w, new_h), Image.BOX)
  canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
  canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2))
  return canvas


def index_to_palette(rgb, pal):
  """각 픽셀을 가장 가까운 팔레트색으로 매핑(RGB 유클리드 최근접)."""
  flat = rgb.reshape(-1, 3).astype(np.float32)
  d = ((flat[:, None, :] - pal[None, :, :]) ** 2).sum(2)
  return pal[d.argmin(1)].astype(np.uint8).reshape(rgb.shape)


def dotify(src_path, target_w, target_h, transparent, lcd, alpha_thr=128):
  """핵심 파이프라인: 축소 → 알파 이진화 → 팔레트 인덱싱 → LCD 투명."""
  im = Image.open(src_path).convert("RGBA")
  im = fit_resize(im, target_w, target_h)
  arr = np.array(im)
  rgb, alpha = arr[:, :, :3], arr[:, :, 3]

  mask = alpha > alpha_thr if transparent else np.ones(alpha.shape, bool)
  mapped = index_to_palette(rgb, load_palette())
  out = np.dstack([mapped, np.where(mask, 255, 0).astype(np.uint8)])

  if lcd:
    x, y, w, h = lcd
    out[y:y + h, x:x + w, 3] = 0  # 게임 화면 구멍 = 완전 투명

  return Image.fromarray(out, "RGBA")


def audit(img, target_w, target_h, pal, lcd):
  """규격 검수 리포트. (통과여부, 라인들) 반환."""
  arr = np.array(img)
  w, h = img.size
  alpha = arr[:, :, 3]
  opaque = arr[alpha > 10][:, :3]
  uniq = np.unique(opaque.reshape(-1, 3), axis=0) if len(opaque) else np.empty((0, 3))

  # 팔레트 외 색 검출
  palset = {tuple(c) for c in pal.astype(np.uint8)}
  off = [tuple(c) for c in uniq if tuple(c) not in palset]
  # 반투명(0/255 외) 검출
  semi = int(((alpha > 10) & (alpha < 245)).sum())

  lines, ok = [], True
  def chk(cond, msg):
    nonlocal ok
    ok = ok and cond
    lines.append(("  ✅ " if cond else "  ❌ ") + msg)

  chk((w, h) == (target_w, target_h), f"치수 {w}×{h} (목표 {target_w}×{target_h})")
  chk(len(uniq) <= 32, f"고유 색 {len(uniq)}개 (≤32)")
  chk(len(off) == 0, f"팔레트 외 색 {len(off)}개 (=0)")
  chk(semi == 0, f"반투명 픽셀 {semi}개 (=0, 도트는 0/255만)")
  if lcd:
    x, y, lw, lh = lcd
    hole = arr[y:y + lh, x:x + lw, 3]
    chk(int(hole.max()) == 0, f"LCD칸({lw}×{lh}@{x},{y}) 완전 투명")
  return ok, lines


def main():
  ap = argparse.ArgumentParser(description="나라카찌 도트화 파이프라인")
  ap.add_argument("src", help="원본 이미지(PNG)")
  ap.add_argument("--preset", choices=PRESETS.keys(), help="규격 프리셋")
  ap.add_argument("--size", help="직접 규격 지정 (예: 120x180)")
  ap.add_argument("--transparent", action="store_true", help="--size 사용 시 투명배경 처리")
  ap.add_argument("--out", required=True, help="출력 PNG 경로")
  ap.add_argument("--preview", type=int, default=3, help="×N nearest 확대 미리보기 배율 (0=off)")
  args = ap.parse_args()

  if args.preset:
    tw, th, transparent, lcd = PRESETS[args.preset]
  elif args.size:
    tw, th = (int(v) for v in args.size.lower().split("x"))
    transparent, lcd = args.transparent, None
  else:
    ap.error("--preset 또는 --size 중 하나는 필수")

  img = dotify(args.src, tw, th, transparent, lcd)
  img.save(args.out)

  if args.preview > 0:
    pv = os.path.splitext(args.out)[0] + f"_x{args.preview}.png"
    img.resize((tw * args.preview, th * args.preview), Image.NEAREST).save(pv)

  ok, lines = audit(img, tw, th, load_palette(), lcd)
  print(f"\n=== 도트화: {os.path.basename(args.src)} → {args.out} ===")
  print(f"프리셋: {args.preset or args.size}")
  print("\n[검수 리포트]")
  print("\n".join(lines))
  print(f"\n{'✅ 규격 통과 — 그대로 사용 가능' if ok else '⚠️ 일부 항목 미달 — pixilart 수동 정리 필요'}")
  if args.preview > 0:
    print(f"미리보기: {pv}")
  sys.exit(0 if ok else 1)


if __name__ == "__main__":
  main()
